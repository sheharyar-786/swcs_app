import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AddBinPage extends StatefulWidget {
  const AddBinPage({super.key});

  @override
  State<AddBinPage> createState() => _AddBinPageState();
}

class _AddBinPageState extends State<AddBinPage> {
  // Logic & State
  BluetoothDevice? selectedDevice;
  Position? currentPosition;
  int nextBinId = 0;
  bool isScanning = false;
  bool isFinalizing = false;
  int timerCount = 60;
  Timer? _timer;

  // Controllers
  final ssidController = TextEditingController();
  final passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSetup();
  }

  @override
  void dispose() {
    _timer?.cancel();
    ssidController.dispose();
    passController.dispose();
    super.dispose();
  }

  // 1. Fully Integrated Location & Firebase Setup
  Future<void> _initializeSetup() async {
    try {
      // Permission check and get live location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best), // Best for pinpointing bins
      );

      // Fetching Next ID from Firebase Metadata
      final ref = FirebaseDatabase.instance.ref('system_metadata/total_bins');
      final snapshot = await ref.get();

      if (mounted) {
        setState(() {
          currentPosition = position;
          nextBinId = (snapshot.value as int? ?? 0) + 1;
        });
        _startCountdown();
      }
    } catch (e) {
      _showSnack("Location Error: $e");
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timerCount > 0) {
        if (mounted) setState(() => timerCount--);
      } else {
        _timer?.cancel();
      }
    });
  }

  // 2. Bluetooth Connectivity (SWCS_CONFIG_MODE Filter)
  void _connectToESP32() async {
    setState(() => isScanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // Matching the ID defined in ESP32: "SWCS_CONFIG_MODE"
        if (r.device.platformName.contains("SWCS")) {
          await FlutterBluePlus.stopScan();
          try {
            await r.device.connect();
            setState(() {
              selectedDevice = r.device;
              isScanning = false;
            });
            _showSnack("Connected to Hardware");
          } catch (e) {
            _showSnack("Connection failed: $e");
          }
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    if (selectedDevice == null && mounted) {
      setState(() => isScanning = false);
      _showSnack("No SWCS Hardware found.");
    }
  }

  // 3. Finalize Registration & Provisioning
  void _finalizeProvisioning() async {
    if (selectedDevice == null || currentPosition == null) {
      _showSnack("Hardware connection or GPS missing!");
      return;
    }

    if (ssidController.text.isEmpty || passController.text.isEmpty) {
      _showSnack("Please enter WiFi details");
      return;
    }

    setState(() => isFinalizing = true);

    try {
      // Step A: Send JSON Payload to ESP32 via Bluetooth
      // Format: {"ssid":"name", "pass":"123", "id":"bin_11"}
      String binKey = "bin_${nextBinId.toString().padLeft(2, '0')}";
      Map<String, String> configData = {
        "ssid": ssidController.text,
        "pass": passController.text,
        "id": binKey,
      };

      String jsonPayload = jsonEncode(configData);
      List<BluetoothService> services = await selectedDevice!
          .discoverServices();

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            await char.write(utf8.encode(jsonPayload));
          }
        }
      }

      // Step B: Update Firebase Database
      String path = "bins/$binKey";
      await FirebaseDatabase.instance.ref(path).set({
        "readings": {"fill": 0, "gas": 0},
        "metadata": {
          "bin_id": "BIN-$nextBinId",
          "location": {
            "lat": currentPosition!.latitude,
            "lng": currentPosition!.longitude,
          },
          "status": "Online",
          "alert": "Normal",
          "last_sync": ServerValue.timestamp,
        },
      });

      // Update the Global Bin Counter
      await FirebaseDatabase.instance
          .ref('system_metadata/total_bins')
          .set(nextBinId);

      _showSuccessDialog(binKey);
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      if (mounted) setState(() => isFinalizing = false);
    }
  }

  void _showSuccessDialog(String binKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Registration Success!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text(
              "Hardware $binKey has been successfully deployed and linked to the cloud.",
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Go back to Dashboard
            },
            child: const Text("DONE"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text("Deploy IoT Bin"),
        backgroundColor: const Color(0xFF0A714E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isFinalizing
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A714E)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatusHeader(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStepCard(
                          "1",
                          "Hardware Link",
                          "Pair with the nearby Bin Controller",
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.bluetooth_searching,
                              color: Colors.blue,
                            ),
                            title: Text(
                              selectedDevice?.platformName ??
                                  (isScanning
                                      ? "Scanning..."
                                      : "No Connection"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              selectedDevice?.remoteId.toString() ??
                                  "Connect via Bluetooth",
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isScanning ? Icons.sync : Icons.search,
                                color: const Color(0xFF0A714E),
                              ),
                              onPressed: isScanning ? null : _connectToESP32,
                            ),
                          ),
                        ),
                        _buildStepCard(
                          "2",
                          "Wi-Fi Provisioning",
                          "Share local network with the Bin",
                          child: Column(
                            children: [
                              TextField(
                                controller: ssidController,
                                decoration: const InputDecoration(
                                  hintText: "SSID (WiFi Name)",
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(),
                              TextField(
                                controller: passController,
                                decoration: const InputDecoration(
                                  hintText: "Password",
                                  border: InputBorder.none,
                                ),
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                        _buildStepCard(
                          "3",
                          "GPS Tagging",
                          "Live coordinates for Google Maps",
                          child: Row(
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  currentPosition != null
                                      ? "Lat: ${currentPosition!.latitude}, Lng: ${currentPosition!.longitude}"
                                      : "Fetching High-Accuracy GPS...",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A714E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- UI Styling Components ---
  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: Color(0xFF0A714E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "System Assignment",
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                "BIN-${nextBinId.toString().padLeft(3, '0')}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: timerCount / 60,
                color: Colors.white,
                strokeWidth: 3,
              ),
              Text(
                "${timerCount}s",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    String num,
    String title,
    String sub, {
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0A714E),
                child: Text(
                  num,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A714E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _finalizeProvisioning,
        child: const Text(
          "FINALIZE REGISTRATION",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
