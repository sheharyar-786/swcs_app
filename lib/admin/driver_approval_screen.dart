import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DriverApprovalScreen extends StatefulWidget {
  const DriverApprovalScreen({super.key});

  @override
  State<DriverApprovalScreen> createState() => _DriverApprovalScreenState();
}

class _DriverApprovalScreenState extends State<DriverApprovalScreen> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);

  final Map<String, String> _selectedDuties = {};
  final Map<String, TextEditingController> _controllers = {};

  final List<String> dutyRoles = [
    'Collector',
    'HeavyloadLifter',
    'Helper',
    'Supervisor',
    'Emergency Squad',
  ];

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget decodeBase64Image(String base64String) {
    try {
      Uint8List bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
    }
  }

  void _showImageFull(String title, String base64) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              width: double.infinity,
              color: Colors.black,
              child: decodeBase64Image(base64),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🛡️ Verification Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('pending_drivers').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text(
                "No pending requests! ✅",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          Map<dynamic, dynamic> drivers =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<String> keys = drivers.keys.cast<String>().toList();

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              String driverKey = keys[index];
              var driver = drivers[driverKey];

              _selectedDuties.putIfAbsent(driverKey, () => 'Collector');
              _controllers.putIfAbsent(
                driverKey,
                () => TextEditingController(),
              );

              return _buildApprovalCard(driver, driverKey);
            },
          );
        },
      ),
    );
  }

  Widget _buildApprovalCard(var driver, String key) {
    return Container(
      key: ValueKey(key),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(25),
      ),
      child: ExpansionTile(
        maintainState: true,
        leading: const CircleAvatar(
          backgroundColor: leafGreen,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          driver['name'] ?? driver['email'] ?? "New Applicant",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoBadge(
                  Icons.email_outlined,
                  "Email",
                  driver['email'] ?? "N/A",
                ),
                const SizedBox(height: 8),
                _infoBadge(
                  Icons.badge_outlined,
                  "CNIC",
                  driver['cnic'] ?? "N/A",
                ),
                const SizedBox(height: 20),
                const Text(
                  "Documents Review (Tap to zoom):",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _docBox("CNIC Front", driver['cnic_image_base64']),
                    const SizedBox(width: 10),
                    _docBox("License", driver['license_image_base64']),
                  ],
                ),
                const Divider(height: 40),
                const Text(
                  "Assignment Details:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: deepForest,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: _inputDeco("Select Duty Role"),
                  value: _selectedDuties[key],
                  items: dutyRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDuties[key] = val!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controllers[key],
                  decoration: _inputDeco("Assign Vehicle ID (e.g. TRUCK-01)"),
                ),
                const SizedBox(height: 25),
                // --- FIXED EQUAL BUTTONS ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _process(key, false, driver['email']),
                        child: const Text(
                          "REJECT",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: leafGreen,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => _process(key, true, driver['email']),
                        child: const Text(
                          "APPROVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _docBox(String label, String? base64) {
    return Expanded(
      child: GestureDetector(
        onTap: base64 != null ? () => _showImageFull(label, base64) : null,
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: base64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        base64Decode(base64),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _process(String uid, bool approve, String email) async {
    try {
      if (approve) {
        String vId = _controllers[uid]!.text.trim();
        if (vId.isEmpty) {
          _msg("Please assign a Vehicle ID first!", Colors.redAccent);
          return;
        }
        await FirebaseDatabase.instance.ref('verified_drivers/$uid').set({
          "uid": uid,
          "email": email,
          "role": "driver",
          "assignedDuty": _selectedDuties[uid],
          "vehicleId": vId,
          "status": "active",
          "points": 0,
          "approvalTimestamp": ServerValue.timestamp,
        });
        _msg("Driver $email Approved!", leafGreen);
      } else {
        _msg("Request Rejected", Colors.redAccent);
      }
      // Removing from pending will automatically trigger StreamBuilder to refresh UI safely
      await FirebaseDatabase.instance.ref('pending_drivers/$uid').remove();

      _controllers.remove(uid);
      _selectedDuties.remove(uid);
    } catch (e) {
      _msg("Error: $e", Colors.redAccent);
    }
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _infoBadge(IconData icon, String label, String val) => Row(
    children: [
      Icon(icon, size: 18, color: leafGreen),
      const SizedBox(width: 10),
      Text(
        "$label: ",
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      Expanded(
        child: Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  void _msg(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
