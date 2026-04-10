import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../civillian/civillian_dashboard.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool showForm = false;
  bool isLoading = false;
  bool obscurePassword = true;

  File? cnicFile;
  File? licenseFile;
  bool cnicUploaded = false;
  bool licenseUploaded = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String selectedRegRole = 'Civilian';
  final List<String> registrationRoles = ['Civilian', 'Driver'];

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

  // --- LOGICS ---
  String imageToBase64(File file) {
    List<int> imageBytes = file.readAsBytesSync();
    return base64Encode(imageBytes);
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        if (type == "CNIC") {
          cnicFile = File(image.path);
          cnicUploaded = true;
        } else {
          licenseFile = File(image.path);
          licenseUploaded = true;
        }
      });
    }
  }

  Future<void> _autoRouteUser(String uid) async {
    final db = FirebaseDatabase.instance.ref();
    final adminSnap = await db.child('admins/$uid').get();
    if (adminSnap.exists) {
      _navigate(const AdminPage());
      return;
    }
    final driverSnap = await db.child('verified_drivers/$uid').get();
    if (driverSnap.exists) {
      _navigate(const DriverDashboard());
      return;
    }
    final civilianSnap = await db.child('users/$uid').get();
    if (civilianSnap.exists) {
      _navigate(const CivillianPage());
      return;
    }
    final pendingSnap = await db.child('pending_drivers/$uid').get();
    if (pendingSnap.exists) {
      await FirebaseAuth.instance.signOut();
      _showSnackBar(
        "Your account is still pending admin approval.",
        Colors.orange,
      );
      return;
    }
    _showSnackBar("Account not found in system.", Colors.redAccent);
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => screen),
    );
  }

  Future<void> _handleSubmit() async {
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.redAccent);
      return;
    }
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        UserCredential cred = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) await _autoRouteUser(cred.user!.uid);
      } else {
        if (selectedRegRole == 'Driver' &&
            (!cnicUploaded || !licenseUploaded)) {
          _showSnackBar("Please upload both documents", Colors.redAccent);
          return;
        }
        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (cred.user != null) {
          String uid = cred.user!.uid;
          if (selectedRegRole == 'Driver') {
            await FirebaseDatabase.instance.ref('pending_drivers/$uid').set({
              "uid": uid,
              "name": _nameController.text.trim(),
              "email": email,
              "cnic_image_base64": imageToBase64(cnicFile!),
              "license_image_base64": imageToBase64(licenseFile!),
              "status": "pending",
              "regDate": DateTime.now().toString(),
              "role": "driver",
            });
          } else {
            await FirebaseDatabase.instance.ref('users/$uid').set({
              "uid": uid,
              "name": _nameController.text.trim(),
              "email": email,
              "role": "civilian",
            });
          }
          _showStatusDialog(
            "Submission Successful! Awaiting Admin Verification.",
          );
        }
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.redAccent);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FADED GREEN NATURE BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. LOW OPACITY GREEN OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.4),
                  leafGreen.withOpacity(0.7),
                  deepForest.withOpacity(0.9),
                ],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // 3. WASTE COLLECTION SIGN LOGO
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded, // Waste/Recycle Sign
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "SWCS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const Text(
                      "SMART WASTE COLLECTION",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: !showForm ? _buildChoiceBoxes() : _buildAuthForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceBoxes() {
    return Column(
      children: [
        _selectionCard(
          title: "Sign In",
          subtitle: "Access system automatically",
          icon: Icons.login_rounded,
          onTap: () => setState(() {
            isLogin = true;
            showForm = true;
          }),
        ),
        const SizedBox(height: 20),
        _selectionCard(
          title: "Join Us",
          subtitle: "Register as Driver or Civilian",
          icon: Icons.person_add_rounded,
          onTap: () => setState(() {
            isLogin = false;
            showForm = true;
          }),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => showForm = false),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: leafGreen,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                isLogin ? "Welcome Back" : "Create Account",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: deepForest,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
          const SizedBox(height: 20),
          if (!isLogin) _buildSignupRoleSelector(),
          if (!isLogin) ...[
            const SizedBox(height: 15),
            _buildTextField(
              controller: _nameController,
              label: "Full Name",
              icon: Icons.person_outline,
            ),
          ],
          const SizedBox(height: 15),
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          if (!isLogin && selectedRegRole == 'Driver') ...[
            const SizedBox(height: 15),
            _buildDocButton(
              "Attach CNIC Front",
              Icons.badge_outlined,
              "CNIC",
              cnicUploaded,
            ),
            const SizedBox(height: 10),
            _buildDocButton(
              "Attach License Front",
              Icons.drive_eta_outlined,
              "License",
              licenseUploaded,
            ),
          ],
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: leafGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : _handleSubmit,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isLogin ? "LOG IN" : "CONTINUE",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: registrationRoles.map((role) {
          bool isSelected = selectedRegRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedRegRole = role),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? leafGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    role,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _selectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white54),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: leafGreen.withOpacity(0.1),
              child: Icon(icon, color: leafGreen),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: deepForest,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: leafGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && obscurePassword,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: leafGreen, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDocButton(
    String label,
    IconData icon,
    String type,
    bool isDone,
  ) {
    return InkWell(
      onTap: () => _pickImage(type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: softMint.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDone ? leafGreen : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: leafGreen, size: 20),
            const SizedBox(width: 10),
            Text(
              isDone ? "$type Attached ✅" : label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: deepForest,
              ),
            ),
            const Spacer(),
            const Icon(Icons.cloud_upload_outlined, color: leafGreen, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String m, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating,
        ),
      );

  void _showStatusDialog(String m) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(m),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                showForm = false;
                isLogin = true;
              });
            },
            child: const Text(
              "OK",
              style: TextStyle(color: leafGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
