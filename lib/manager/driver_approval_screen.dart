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
  static const Color softMint = Color(0xFFF1F8E9);

  final Map<String, String> _selectedDuties = {};
  final Map<String, TextEditingController> _controllers = {};

  // Logic to prevent the "Red Screen" and keep tiles open
  final Map<String, GlobalKey> _tileKeys = {};

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              backgroundColor: Colors.black.withValues(alpha: 0.7),
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
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
      ),
      body: Stack(
        children: [
          // 1. FADED BACKGROUND IMAGE
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.network(
                'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=1000',
                fit: BoxFit.cover,
              ),
            ),
          ),

          StreamBuilder(
            stream: FirebaseDatabase.instance.ref('pending_drivers').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: leafGreen),
                );
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return _buildEmptyState();
              }

              Map<dynamic, dynamic> drivers =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<String> keys = drivers.keys.cast<String>().toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 80),
                physics: const BouncingScrollPhysics(),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  String driverKey = keys[index];
                  var driver = drivers[driverKey];

                  _selectedDuties.putIfAbsent(driverKey, () => 'Collector');
                  _controllers.putIfAbsent(
                    driverKey,
                    () => TextEditingController(),
                  );
                  _tileKeys.putIfAbsent(driverKey, () => GlobalKey());

                  return _buildApprovalCard(driver, driverKey);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(var driver, String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 
          0.92,
        ), // Slight transparency to show background
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: softMint),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: _tileKeys[key], // FIXED: Prevents tile from resetting/closing
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: leafGreen.withValues(alpha: 0.3), width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: softMint,
              child: Icon(Icons.person_outline, color: leafGreen),
            ),
          ),
          title: Text(
            (driver['name'] ?? "New Applicant").toString().toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: deepForest,
              letterSpacing: 0.5,
            ),
          ),
          subtitle: Text(
            driver['email'] ?? "Email not provided",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  const SizedBox(height: 20),
                  _infoBadge(
                    Icons.badge_outlined,
                    "CNIC Number",
                    (driver['cnic_number'] ?? driver['cnic'] ?? "N/A")
                        .toString(),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "DOCUMENT VERIFICATION",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _docBox("CNIC FRONT", driver['cnic_image_base64']),
                      const SizedBox(width: 15),
                      _docBox("LICENSE", driver['license_image_base64']),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "ADMIN ASSIGNMENT",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _inputDeco(
                      "Select Duty Role",
                      Icons.work_outline,
                    ),
                    initialValue: dutyRoles.contains(_selectedDuties[key])
                        ? _selectedDuties[key]
                        : dutyRoles.first,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: deepForest,
                      fontSize: 13,
                    ),
                    items: dutyRoles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDuties[key] = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _controllers[key],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    decoration: _inputDeco(
                      "Assign Vehicle ID",
                      Icons.local_shipping_outlined,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () => _process(
                            key,
                            false,
                            driver['email'],
                            driver['name'] ?? "New Driver",
                          ),
                          child: const Text(
                            "REJECT",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: leafGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () => _process(
                            key,
                            true,
                            driver['email'],
                            driver['name'] ?? "New Driver",
                          ),
                          child: const Text(
                            "APPROVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
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
      ),
    );
  }

  Widget _docBox(String label, String? base64) {
    return Expanded(
      child: GestureDetector(
        onTap: base64 != null ? () => _showImageFull(label, base64) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
              ),
              child: base64 != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        base64Decode(base64),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _process(
    String uid,
    bool approve,
    String email,
    String driverName,
  ) async {
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
          "name": driverName,
          "role": "driver",
          "assignedDuty": _selectedDuties[uid],
          "vehicleId": vId,
          "status": "active",
          "attendance": "Inactive",
          "points": 0,
          "distance_covered": 0.0,
          "approvalTimestamp": ServerValue.timestamp,
        });
        _msg("Driver Approved! 🚛", leafGreen);
      } else {
        _msg("Request Rejected", Colors.redAccent);
      }
      await FirebaseDatabase.instance.ref('pending_drivers/$uid').remove();
      _controllers.remove(uid);
      _selectedDuties.remove(uid);
      _tileKeys.remove(uid);
    } catch (e) {
      _msg("Error: $e", Colors.redAccent);
    }
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
    prefixIcon: Icon(icon, color: leafGreen, size: 20),
    filled: true,
    fillColor: const Color(0xFFF8FBF8),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );

  Widget _infoBadge(IconData icon, String label, String val) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: softMint.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: leafGreen),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                val,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: deepForest,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 15),
        const Text(
          "No pending requests! ✅",
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  void _msg(String m, Color c) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}
