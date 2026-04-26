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
  bool showForm = true;
  bool isLoading = false;
  bool obscurePassword = true;

  File? cnicFile;
  File? licenseFile;
  bool cnicUploaded = false;
  bool licenseUploaded = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cnicNumberController = TextEditingController();

  String selectedRegRole = 'Civilian';
  // Updated Roles: Manager added
  final List<String> registrationRoles = ['Civilian', 'Driver', 'Manager'];

  static const Color leafGreen = Color(0xFF0A714E);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

  // --- LOGICS ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingLogin();
    });
  }

  Future<void> _checkExistingLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => isLoading = true);
      await _autoRouteUser(user.uid, user.email ?? '');
      if (mounted) setState(() => isLoading = false);
    }
  }

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

    // 2. Role Check from 'users' (Admin Approved roles: Manager, Driver, Civilian)
    final userSnap = await db.child('users/$uid').get();

    // --- Bootstrap Admin Logic: Auto-create entry if it doesn't exist ---
    if (!userSnap.exists && email.toLowerCase() == "swcsproviders@gmail.com") {
      await db.child('users/$uid').set({
        "uid": uid,
        "email": email,
        "role": "admin",
        "name": "Admin",
        "isSuspended": false,
        "regDate": DateTime.now().toString(),
      });
      _navigate(const AdminMainShell());
      return;
    }

    if (userSnap.exists) {
      String role = userSnap.child('role').value.toString();
      bool isSuspended = userSnap.child('isSuspended').value == true;

      if (isSuspended) {
        await FirebaseAuth.instance.signOut();
        _showErrorDialog(
          "Account Suspended",
          "Your account is suspended. Contact Admin.",
        );
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
        _showErrorDialog(
          "Account Suspended",
          "Your account is suspended. Contact Admin.",
        );
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
      _showErrorDialog("Pending Approval", "Account pending admin approval.");
      return;
    }

    _showErrorDialog("User Not Found", "Record not found. Contact Admin.");
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => screen),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog("Missing Email", "Enter email to receive reset link!");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      _showErrorDialog("Success", "Official Reset Link sent to your Email!");
    } catch (e) {
      _showErrorDialog("Reset Failed", "Error sending link. Verify email.");
    }
  }

  Future<void> _handleSubmit() async {
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog("Incorrect Email", "Please correct your email address.");
      return;
    }

    if (password.isEmpty || password.length < 6) {
      _showErrorDialog(
        "Incorrect Password",
        "Please enter a valid password (min 6 characters).",
      );
      return;
    }

    if (!isLogin && password != _confirmPasswordController.text.trim()) {
      _showErrorDialog(
        "Password Mismatch",
        "Passwords do not match. Please try again.",
      );
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
          _showErrorDialog(
            "Missing Info",
            "Provide Phone, CNIC and License images",
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
            "isApproved": false,
            "isSuspended": false,
            "regDate": DateTime.now().toString(),
            "timestamp": DateTime.now().millisecondsSinceEpoch,
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
            userData["phone"] = _phoneController.text.trim();
            await FirebaseDatabase.instance
                .ref('pending_managers/$uid')
                .set(userData);
          } else {
            userData["role"] = "civilian";
            userData["isApproved"] = true; // Civilian needs no approval
            await FirebaseDatabase.instance.ref('users/$uid').set(userData);
          }

          _showStatusDialog("Signed Up! Wait for Admin Approval.");
        }
      }
    } catch (e) {
      _showErrorDialog("Login/Signup Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [leafGreen, deepForest],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    // Logo
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ClipOval(
                          child: Image.asset(
                            'lib/assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "SWCS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Smart Waste Collection System",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
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
          title: "Sign Up",
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 40), // Spacing to keep title centered
                const Spacer(),
                Text(
                  isLogin ? "Sign In" : "Sign Up",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepForest,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 40), // Balance the other side
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
              if (selectedRegRole == 'Manager') ...[
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _phoneController,
                  label: "Mobile Number",
                  icon: Icons.phone_android,
                ),
              ],
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
            if (!isLogin) ...[
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
            ],

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
                        isLogin ? "SIGN IN" : "SIGN UP",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLogin
                      ? "Don't have an account? "
                      : "Already have an account? ",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLogin = !isLogin;
                    });
                  },
                  child: Text(
                    isLogin ? "Sign Up" : "Sign In",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: leafGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(color: leafGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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
                showForm = true;
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
