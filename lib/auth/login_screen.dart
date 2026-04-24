import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../manager/manager_dashboard.dart';
import '../driver/driver_dashboard.dart';
import '../civillian/civillian_dashboard.dart';
import '../admin/dashboard/admin_main_shell.dart'; // Admin Dashboard Import

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
  final TextEditingController _phoneController =
      TextEditingController(); // New: Phone Field
  final TextEditingController _cnicNumberController = TextEditingController();

  String selectedRegRole = 'Civilian';
  // Updated Roles: Manager added
  final List<String> registrationRoles = ['Civilian', 'Driver', 'Manager'];

  static const Color leafGreen = Color(0xFF0A714E);
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

  Future<void> _autoRouteUser(String uid, String email) async {
    final db = FirebaseDatabase.instance.ref();

    // 1. Admin Bypass
    if (email.toLowerCase() == "admin@gmail.com") {
      _navigate(const AdminMainShell());
      return;
    }

    // 2. Role Check from 'users' (Admin Approved roles: Manager, Driver, Civilian)
    final userSnap = await db.child('users/$uid').get();
    if (userSnap.exists) {
      String role = userSnap.child('role').value.toString();
      bool isSuspended = userSnap.child('isSuspended').value == true;

      if (isSuspended) {
        await FirebaseAuth.instance.signOut();
        _showSnackBar("Your account is suspended. Contact Admin.", Colors.red);
        return;
      }

      if (role == 'admin') {
        _navigate(const AdminMainShell());
      } else if (role == 'manager') {
        _navigate(const AdminPage());
      } else if (role == 'driver') {
        _navigate(const DriverDashboard());
      } else {
        _navigate(const CivillianPage());
      }
      return;
    }

    // 2.5 Role Check from 'verified_drivers' (Drivers)
    final driverSnap = await db.child('verified_drivers/$uid').get();
    if (driverSnap.exists) {
      bool isSuspended = driverSnap.child('isSuspended').value == true;
      if (isSuspended) {
        await FirebaseAuth.instance.signOut();
        _showSnackBar("Your account is suspended. Contact Admin.", Colors.red);
        return;
      }
      _navigate(const DriverDashboard());
      return;
    }

    // 3. Pending Check (For Manager & Driver)
    // Still check users if not approved
    // Standard practice: if they exist in a "pending" node
    final isPendingManager =
        (await db.child('pending_managers/$uid').get()).exists;
    final isPendingDriver =
        (await db.child('pending_drivers/$uid').get()).exists;

    if (isPendingManager || isPendingDriver) {
      await FirebaseAuth.instance.signOut();
      _showSnackBar("Account pending admin approval.", Colors.orange);
      return;
    }

    _showSnackBar("Record not found. Contact Admin.", Colors.redAccent);
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => screen),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar("Enter email to receive reset link!", Colors.orange);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showSnackBar("Official Reset Link sent to your Email!", leafGreen);
    } catch (e) {
      _showSnackBar("Error sending link. Verify email.", Colors.redAccent);
    }
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
        if (cred.user != null) await _autoRouteUser(cred.user!.uid, email);
      } else {
        // Sign-up Specific Validation
        if (selectedRegRole == 'Driver' &&
            (!cnicUploaded ||
                !licenseUploaded ||
                _phoneController.text.isEmpty)) {
          _showSnackBar(
            "Provide Phone, CNIC and License images",
            Colors.redAccent,
          );
          setState(() => isLoading = false);
          return;
        }

        UserCredential cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (cred.user != null) {
          String uid = cred.user!.uid;
          Map<String, dynamic> userData = {
            "uid": uid,
            "name": _nameController.text.trim(),
            "email": email,
            "phone": _phoneController.text.trim(),
            "isApproved": false,
            "isSuspended": false,
            "regDate": DateTime.now().toString(),
          };

          if (selectedRegRole == 'Driver') {
            userData["role"] = "driver";
            userData["cnic_number"] = _cnicNumberController.text.trim();
            userData["cnic_image"] = imageToBase64(cnicFile!);
            userData["license_image"] = imageToBase64(licenseFile!);
            await FirebaseDatabase.instance
                .ref('pending_drivers/$uid')
                .set(userData);
          } else if (selectedRegRole == 'Manager') {
            userData["role"] = "manager";
            await FirebaseDatabase.instance
                .ref('pending_managers/$uid')
                .set(userData);
          } else {
            userData["role"] = "civilian";
            userData["isApproved"] = true; // Civilian needs no approval
            await FirebaseDatabase.instance.ref('users/$uid').set(userData);
          }

          _showStatusDialog("Registered! Wait for Admin Approval.");
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
          // Background
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  leafGreen.withValues(alpha: 0.7),
                  deepForest.withValues(alpha: 0.9),
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
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
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
          subtitle: "Register as Staff or Civilian",
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
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
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
            const SizedBox(height: 15),
            _buildTextField(
              controller: _phoneController,
              label: "Mobile Number",
              icon: Icons.phone_android,
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

          if (isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: leafGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          if (!isLogin && selectedRegRole == 'Driver') ...[
            const SizedBox(height: 15),
            _buildTextField(
              controller: _cnicNumberController,
              label: "CNIC (31303-xxxxxxx-x)",
              icon: Icons.numbers,
            ),
            const SizedBox(height: 15),
            _buildDocButton(
              "CNIC Front Image",
              Icons.badge_outlined,
              "CNIC",
              cnicUploaded,
            ),
            const SizedBox(height: 10),
            _buildDocButton(
              "License Front Image",
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
                      fontSize: 11,
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
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: leafGreen.withValues(alpha: 0.1),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: leafGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
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
          color: softMint.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDone ? leafGreen : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: leafGreen, size: 20),
            const SizedBox(width: 10),
            Text(
              isDone ? "$type Added ✅" : label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.upload, color: leafGreen, size: 18),
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
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
