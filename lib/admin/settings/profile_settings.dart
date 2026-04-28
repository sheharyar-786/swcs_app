import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../widgets/admin_header.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final user = FirebaseAuth.instance.currentUser;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  File? _image;
  String? _base64Image; // Base64 state
  Map? _userData; // Realtime DB user data

  @override
  void initState() {
    super.initState();
    _emailController.text = user?.email ?? "";
    _fetchUserData();
  }

  void _fetchUserData() {
    if (user != null) {
      FirebaseDatabase.instance.ref('users/${user!.uid}').onValue.listen((
        event,
      ) {
        if (mounted && event.snapshot.value != null) {
          setState(() {
            _userData = event.snapshot.value as Map;
            _base64Image = _userData?['profilePic'];
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- FINALIZED: Profile Picture as Base64 in Realtime DB ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    ); // Reduce quality for RTDB

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      try {
        _showSnack("Saving profile picture...", Colors.blue);

        // Save directly to Realtime Database 'users' node
        await FirebaseDatabase.instance.ref('users/${user!.uid}').update({
          'profilePic': base64String,
        });

        if (mounted) {
          setState(() {
            _image = file;
            _base64Image = base64String;
          });
          _showSnack("Profile picture saved to Database!", Colors.green);
        }
      } catch (e) {
        _showSnack("Save failed: $e", Colors.red);
      }
    }
  }

  // --- FINALIZED: Logout & Redirect ---
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Login page par wapis bhejne ke liye
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // --- FINALIZED: App Information ---
  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "About the App",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SWCS MISSION HUB",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A714E),
                fontSize: 18,
              ),
            ),
            SizedBox(height: 10),
            Text("Smart Waste Collection System (IoT Based)"),
            SizedBox(height: 15),
            Divider(),
            SizedBox(height: 15),
            Text(
              "Version: 1.0.5 (Stable)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 5),
            Text(
              "Developed for high-efficiency waste management and live monitoring.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Color(0xFF0A714E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: "Profile Settings",
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfilePicSection(),
                _buildStatementBar(),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Account Security"),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 100),
                        child: _buildSettingTile(
                          "Change Password",
                          Icons.lock_outline,
                          () => _showPasswordChangeDialog(),
                        ),
                      ),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 200),
                        child: _buildSettingTile(
                          "Update Email",
                          Icons.alternate_email_rounded,
                          () => _showEmailChangeDialog(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSectionTitle("System Configuration"),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 300),
                        child: _buildSettingTile(
                          "Alert Thresholds",
                          Icons.notifications_active_outlined,
                          _showThresholdDialog,
                        ),
                      ),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 400),
                        delay: const Duration(milliseconds: 400),
                        child: _buildSettingTile(
                          "About the App",
                          Icons.info_outline_rounded,
                          _showAboutApp,
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildProfilePicSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          FadeInDown(
            child: Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A714E).withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFF0A714E).withValues(alpha: 0.05),
                        backgroundImage: _base64Image != null
                            ? MemoryImage(base64Decode(_base64Image!))
                            : null,
                        child: _base64Image == null
                            ? const Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: Color(0xFF0A714E),
                              )
                            : null,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF0A714E),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            (_userData?['name'] ?? "Admin Account").toString().toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementBar() {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A714E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF0A714E).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.security_outlined,
              size: 18,
              color: Color(0xFF0A714E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Logged in as: ${user?.email ?? 'System Administrator'}",
                style: const TextStyle(
                  color: Color(0xFF0A714E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A714E).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        hoverColor: const Color(0xFF0A714E).withValues(alpha: 0.05),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A714E).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0A714E), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeInUp(
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            elevation: 0,
            side: BorderSide(color: Colors.red[100]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: _handleLogout, // Finalized Logout
          child: const Text(
            "LOGOUT SESSION",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // --- SECURE: Email Change Logic ---
  void _showEmailChangeDialog() {
    final currentPassController = TextEditingController();
    final newEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Update Email",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                prefixIcon: Icon(Icons.lock_open, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newEmailController,
              decoration: const InputDecoration(
                labelText: "New Email Address",
                prefixIcon: Icon(Icons.email_outlined, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A714E),
            ),
            onPressed: () async {
              if (currentPassController.text.isEmpty ||
                  newEmailController.text.isEmpty) {
                _showSnack("Please fill all fields", Colors.orange);
                return;
              }

              try {
                // 1. Re-authenticate
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPassController.text,
                );
                await user!.reauthenticateWithCredential(credential);

                // 2. Update Firebase Auth
                await user!.verifyBeforeUpdateEmail(newEmailController.text);

                // 3. Update Realtime DB
                await FirebaseDatabase.instance
                    .ref('users/${user!.uid}')
                    .update({'email': newEmailController.text});

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack(
                  "Verification email sent to new address!",
                  Colors.green,
                );
              } catch (e) {
                _showSnack("Error: $e", Colors.red);
              }
            },
            child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- SECURE: Password Change Logic with Database Sync ---
  void _showPasswordChangeDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Email Account:",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user?.email ?? "",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0A714E),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 25),
              TextField(
                controller: currentPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                  prefixIcon: Icon(Icons.lock_open, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: user!.email!,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showSnack(
                        "Reset link sent to ${user!.email}!",
                        Colors.green,
                      );
                    } catch (e) {
                      _showSnack("Error: $e", Colors.red);
                    }
                  },
                  child: const Text(
                    "Forgot Current Password?",
                    style: TextStyle(
                      color: Color(0xFF0A714E),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A714E),
            ),
            onPressed: () async {
              if (currentPassController.text.isEmpty ||
                  newPassController.text.isEmpty) {
                _showSnack("Please fill all fields", Colors.orange);
                return;
              }

              if (newPassController.text.length < 6) {
                _showSnack(
                  "Password must be at least 6 characters",
                  Colors.orange,
                );
                return;
              }

              try {
                // 1. Re-authenticate
                AuthCredential credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPassController.text,
                );
                await user!.reauthenticateWithCredential(credential);

                // 2. Update Firebase Auth
                await user!.updatePassword(newPassController.text);

                // 3. Sync with Realtime Database (as requested)
                await FirebaseDatabase.instance
                    .ref('users/${user!.uid}')
                    .update({'password': newPassController.text});

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack(
                  "Password updated in Auth & Database!",
                  Colors.green,
                );
              } catch (e) {
                _showSnack("Error: Check current password", Colors.red);
              }
            },
            child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(String title, String hint, bool isPassword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: isPassword ? _passController : _emailController,
          obscureText: isPassword,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isPassword) {
                  await user?.updatePassword(_passController.text);
                } else {
                  await user?.verifyBeforeUpdateEmail(_emailController.text);
                }
                if (!context.mounted) return;
                Navigator.pop(context);
                _showSnack("$title Success!", Colors.green);
              } catch (e) {
                if (!context.mounted) return;
                _showSnack("Error: Re-login required", Colors.red);
              }
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  // --- NEW: System Thresholds Logic (Admin Governance) ---
  void _showThresholdDialog() {
    // Default values if not found in DB
    double approvalHours = 24;
    double escalationHours = 48;
    double minRating = 3.5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: const Text(
              "System Thresholds",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Manage governance triggers and staff alerts.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 30),

                  _buildThresholdSlider(
                    "Approval Timeout",
                    "Notify if staff pending for > ${approvalHours.toInt()}h",
                    approvalHours,
                    1,
                    72,
                    (val) => setDialogState(() => approvalHours = val),
                  ),

                  const SizedBox(height: 20),
                  _buildThresholdSlider(
                    "Complaint Escalation",
                    "Escalate to Admin after ${escalationHours.toInt()}h",
                    escalationHours,
                    1,
                    168,
                    (val) => setDialogState(() => escalationHours = val),
                  ),

                  const SizedBox(height: 20),
                  _buildThresholdSlider(
                    "Staff Performance Flag",
                    "Flag staff if rating drops below ${minRating.toStringAsFixed(1)}",
                    minRating,
                    1.0,
                    5.0,
                    (val) => setDialogState(() => minRating = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A714E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    await FirebaseDatabase.instance
                        .ref('system_settings/thresholds')
                        .update({
                          'approval_timeout_hours': approvalHours.toInt(),
                          'complaint_escalation_hours': escalationHours.toInt(),
                          'min_staff_rating': minRating,
                          'last_updated': DateTime.now().toString(),
                        });
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showSnack(
                      "Thresholds updated successfully!",
                      Colors.green,
                    );
                  } catch (e) {
                    _showSnack("Update failed: $e", Colors.red);
                  }
                },
                child: const Text(
                  "SAVE SETTINGS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThresholdSlider(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF0A714E),
          inactiveColor: const Color(0xFF0A714E).withValues(alpha: 0.1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
