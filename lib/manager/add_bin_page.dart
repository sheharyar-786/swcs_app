import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../widgets/universal_header.dart';

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
  final areaController = TextEditingController(); // Nayi Field Area ke liye

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
    areaController.dispose();
    super.dispose();
  }

  // 1. Fully Integrated Location & Firebase Setup
  Future<void> _initializeSetup() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

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

  // 2. Bluetooth Connectivity (Filtered for SWCS)
  void _connectToESP32() async {
    setState(() {
      isScanning = true;
      selectedDevice = null; // Purani selection clear karein
    });

    // Scan shuru karein
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Scan results ko listen karein
    var subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // Latest version mein ye zayada stable hai
        String dName = r.advertisementData.localName.isNotEmpty
            ? r.advertisementData.localName
            : (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : "Unknown Device");

        if (dName.toUpperCase().contains("SWCS")) {
          print("SWCS Device Found: $dName");
          await FlutterBluePlus.stopScan();

          try {
            await r.device.connect();

            // Request higher MTU for sending long JSON payloads (up to 512 bytes)
            await r.device.requestMtu(512);

            if (mounted) {
              setState(() {
                selectedDevice = r.device;
                isScanning = false;
              });
            }
            _showSnack("Connected & MTU Updated");
          } catch (e) {
            _showSnack("Connection failed: $e");
            if (mounted) setState(() => isScanning = false);
          }
          break;
        }
      }
    });

    // Timeout ke baad agar kuch na mile
    await Future.delayed(const Duration(seconds: 10));
    subscription.cancel();
    if (selectedDevice == null && mounted) {
      setState(() => isScanning = false);
      _showSnack("No SWCS Hardware found nearby.");
    }
  }

  // 3. Finalize Registration & Provisioning
  void _finalizeProvisioning() async {
    if (selectedDevice == null || currentPosition == null) {
      _showSnack("Hardware connection or GPS missing!");
      return;
    }

    if (ssidController.text.isEmpty ||
        passController.text.isEmpty ||
        areaController.text.isEmpty) {
      _showSnack("Please fill WiFi and Area details");
      return;
    }

    setState(() => isFinalizing = true);

    try {
      String binKey = "bin_${nextBinId.toString().padLeft(2, '0')}";

      // Step A: Send JSON to ESP32
      Map<String, String> configData = {
        "ssid": ssidController.text.trim(),
        "pass": passController.text.trim(),
        "id": binKey,
      };

      String jsonPayload = jsonEncode(configData);
      List<BluetoothService> services = await selectedDevice!
          .discoverServices();

      bool dataSent = false;
      for (var service in services) {
        for (var char in service.characteristics) {
          // Humari Characteristic UUID jo ESP32 mein hai
          if (char.uuid.toString() == "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
            await char.write(utf8.encode(jsonPayload));
            dataSent = true;
            break;
          }
        }
      }

      if (!dataSent) throw Exception("Configuration characteristic not found");

      // Step B: Update Firebase Database
      String path = "bins/$binKey";
      await FirebaseDatabase.instance.ref(path).set({
        // --- TOP-LEVEL FIELDS (read by all dashboard/analytics screens) ---
        "area": areaController.text.trim(),
        "fill_level": 0,
        "gas_level": 0,
        "battery": 100,
        "status": "Online",
        "lat": currentPosition!.latitude,
        "lng": currentPosition!.longitude,

        // --- NESTED METADATA (organized storage) ---
        "readings": {"fill_level": 0, "gas_level": 0, "battery_level": 100},
        "metadata": {
          "bin_id": "BIN-${nextBinId.toString().padLeft(3, '0')}",
          "area": areaController.text.trim(),
          "location": {
            "lat": currentPosition!.latitude,
            "lng": currentPosition!.longitude,
          },
          "status": "Online",
          "last_sync": ServerValue.timestamp,
        },
      });

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

  // --- UI Components ---
  // (Success Dialog, Snackbars, and Styling)

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
              "Hardware $binKey has been successfully deployed at ${areaController.text}.",
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
      body: isFinalizing
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A714E)),
            )
          : CustomScrollView(
              slivers: [
                UniversalHeader(
                  title: "BIN-${nextBinId.toString().padLeft(3, '0')}",
                  showBackButton: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStepCard(
                          "1",
                          "Hardware Link",
                          "Pair with SWCS Bin Controller",
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.bluetooth,
                              color: selectedDevice != null
                                  ? Colors.green
                                  : Colors.blue,
                            ),
                            title: Text(
                              selectedDevice != null
                                  ? "Connected: ${selectedDevice!.platformName}"
                                  : (isScanning
                                        ? "Scanning for SWCS..."
                                        : "Disconnected"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                          "Bin Details",
                          "Enter Area and Network Info",
                          child: Column(
                            children: [
                              TextField(
                                controller: areaController,
                                decoration: const InputDecoration(
                                  hintText: "Area Name (e.g. Model Town)",
                                  border: InputBorder.none,
                                  icon: Icon(Icons.map, size: 20),
                                ),
                              ),
                              const Divider(),
                              TextField(
                                controller: ssidController,
                                decoration: const InputDecoration(
                                  hintText: "WiFi SSID",
                                  border: InputBorder.none,
                                  icon: Icon(Icons.wifi, size: 20),
                                ),
                              ),
                              const Divider(),
                              TextField(
                                controller: passController,
                                decoration: const InputDecoration(
                                  hintText: "WiFi Password",
                                  border: InputBorder.none,
                                  icon: Icon(Icons.lock_outline, size: 20),
                                ),
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                        _buildStepCard(
                          "3",
                          "GPS Tagging",
                          "Location for Google Maps",
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
                                      ? "Lat: ${currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${currentPosition!.longitude.toStringAsFixed(4)}"
                                      : "Fetching GPS...",
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
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
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
            color: Colors.black12,
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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
