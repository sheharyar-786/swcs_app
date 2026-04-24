import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart'; // flutter pub add image_picker

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final user = FirebaseAuth.instance.currentUser;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  File? _image; // Profile Picture state

  @override
  void initState() {
    super.initState();
    _emailController.text = user?.email ?? "";
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- NEW: Profile Picture Picker ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _showSnack("Profile picture updated locally!", Colors.green);
      // Note: Yahan aap Firebase Storage logic add kar saktay hain image upload ke liye.
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

  // --- FINALIZED: Alert Thresholds ---
  void _showThresholdDialog() {
    double currentThreshold = 80;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Alert Threshold (%)"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Current: ${currentThreshold.toInt()}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A714E),
                ),
              ),
              Slider(
                value: currentThreshold,
                min: 50,
                max: 100,
                divisions: 10,
                activeColor: const Color(0xFF0A714E),
                onChanged: (val) =>
                    setDialogState(() => currentThreshold = val),
              ),
              const Text(
                "Notification will trigger when bins exceed this level.",
                style: TextStyle(fontSize: 10, color: Colors.grey),
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
              onPressed: () {
                FirebaseDatabase.instance
                    .ref('system_metadata/threshold')
                    .set(currentThreshold.toInt());
                Navigator.pop(context);
                _showSnack(
                  "Threshold updated to ${currentThreshold.toInt()}%",
                  Colors.green,
                );
              },
              child: const Text("SAVE", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- FINALIZED: App Information ---
  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: "SWCS Admin Suite",
      applicationVersion: "1.0.5 (Stable)",
      applicationIcon: const Icon(
        Icons.recycling_rounded,
        color: Color(0xFF0A714E),
        size: 40,
      ),
      children: [
        const Text("Smart Waste Collection System (IoT Based)"),
        const SizedBox(height: 10),
        const Text("Lead Developer: Shary"),
        const Text("Support: support@swcs-iot.com"),
        const Text("Backend: Firebase Realtime DB"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=1000',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.85),
              BlendMode.lighten,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildPremiumHeader(),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Account Security"),
                    _buildSettingTile(
                      "Change Password",
                      Icons.lock_outline,
                      () => _showUpdateDialog(
                        "Update Password",
                        "New Password",
                        true,
                      ),
                    ),
                    _buildSettingTile(
                      "Update Email",
                      Icons.alternate_email_rounded,
                      () => _showUpdateDialog(
                        "Update Email",
                        "New Email Address",
                        false,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle("System Configuration"),
                    _buildSettingTile(
                      "Alert Thresholds",
                      Icons.notifications_active_outlined,
                      _showThresholdDialog, // Finalized
                    ),
                    _buildSettingTile(
                      "App Information",
                      Icons.info_outline_rounded,
                      _showAboutApp, // Finalized
                    ),
                    const SizedBox(height: 50),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 80, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0A714E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          FadeInDown(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickImage, // Editable profile picture
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white24,
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: _pickImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Color(0xFF0A714E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "SUPER ADMIN",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.email ?? "admin@swcs.com",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF0A714E)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
