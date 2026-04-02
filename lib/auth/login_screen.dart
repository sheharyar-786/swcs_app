import 'dart:io';
import 'dart:convert';
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
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  File? cnicFile;
  File? licenseFile;
  bool cnicUploaded = false;
  bool licenseUploaded = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _cnicController = TextEditingController();

  String selectedRole = 'Civilian';
  final List<String> registrationRoles = ['Civilian', 'Driver'];
  final List<String> loginRoles = ['Civilian', 'Driver', 'Admin'];

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

  String imageToBase64(File file) {
    List<int> imageBytes = file.readAsBytesSync();
    return base64Encode(imageBytes);
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

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
      _showSnackBar("$type document attached successfully! ✅", deepForest);
    }
  }

  Future<void> _handleSubmit() async {
    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter both email and password", Colors.redAccent);
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // --- LOGIN PROCESS ---
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (userCredential.user != null) {
          String uid = userCredential.user!.uid;

          // --- NEW: DRIVER VERIFICATION CHECK (Issue Fix) ---
          if (selectedRole == 'Driver') {
            final snapshot = await FirebaseDatabase.instance
                .ref('verified_drivers/$uid')
                .get();

            if (!snapshot.exists) {
              // Account exists in Auth, but not approved in Database
              await FirebaseAuth.instance.signOut();
              _showSnackBar(
                "Access Denied: Profile not approved by Admin yet.",
                Colors.orange,
              );
              return;
            }
          }

          // ADMIN SECURITY
          if (selectedRole == 'Admin') {
            if (email.contains("admin")) {
              _navigateBasedOnRole('admin');
            } else {
              await FirebaseAuth.instance.signOut();
              _showSnackBar("Access Denied: Use Admin email", Colors.redAccent);
            }
          } else {
            // Check to prevent admin email from entering other portals
            if (email.contains("admin")) {
              await FirebaseAuth.instance.signOut();
              _showSnackBar("Admin must select Admin role", Colors.redAccent);
            } else {
              _navigateBasedOnRole(selectedRole.toLowerCase());
            }
          }
        }
      } else {
        // --- REGISTRATION PROCESS ---
        if (email.contains("admin")) {
          _showSnackBar("Cannot register with 'admin' email", Colors.redAccent);
          return;
        }
        if (password != _confirmPasswordController.text.trim()) {
          _showSnackBar("Passwords mismatch", Colors.redAccent);
          return;
        }
        if (selectedRole == 'Driver' &&
            (cnicFile == null || licenseFile == null)) {
          _showSnackBar("Actual documents required!", Colors.redAccent);
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        if (userCredential.user != null) {
          String uid = userCredential.user!.uid;

          if (selectedRole == 'Driver') {
            String cnicData = imageToBase64(cnicFile!);
            String licenseData = imageToBase64(licenseFile!);

            await FirebaseDatabase.instance.ref('pending_drivers/$uid').set({
              "uid": uid,
              "email": email,
              "cnic": _cnicController.text,
              "cnic_image_base64": cnicData,
              "license_image_base64": licenseData,
              "status": "pending",
              "role": "driver",
              "regDate": DateTime.now().toString(),
            });

            _showApprovalPendingDialog();
          } else {
            _navigateBasedOnRole('civilian');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Auth Error", Colors.redAccent);
    } catch (e) {
      _showSnackBar("An unexpected error occurred", Colors.redAccent);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // UI Helper functions remain the same as your design
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateBasedOnRole(String role) {
    Widget destination;
    switch (role) {
      case 'admin':
        destination = const AdminPage();
        break;
      case 'driver':
        destination = const DriverDashboard();
        break;
      default:
        destination = const CivillianPage();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "Success",
          style: TextStyle(color: deepForest, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Profile submitted! Admin will verify your documents shortly.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isLogin = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: leafGreen),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: leafGreen,
              image: DecorationImage(
                image: AssetImage('assets/background.jpeg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        size: 60,
                        color: leafGreen,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "SWCS PORTAL",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isLogin ? "Sign In" : "Register",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: deepForest,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isObscured: obscurePassword,
                            toggleVisibility: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 15),
                            _buildTextField(
                              controller: _confirmPasswordController,
                              label: "Confirm Password",
                              icon: Icons.lock_reset,
                              isPassword: true,
                              isObscured: obscureConfirmPassword,
                              toggleVisibility: () => setState(
                                () => obscureConfirmPassword =
                                    !obscureConfirmPassword,
                              ),
                            ),
                          ],
                          const SizedBox(height: 15),
                          _buildRoleDropdown(),
                          const SizedBox(height: 15),

                          if (!isLogin && selectedRole == 'Driver') ...[
                            _buildTextField(
                              controller: _cnicController,
                              label: "CNIC Number",
                              icon: Icons.badge,
                            ),
                            const SizedBox(height: 15),
                            _buildUploadButton(
                              "CNIC Photo",
                              Icons.camera,
                              () => _pickImage("CNIC"),
                              cnicUploaded,
                            ),
                            const SizedBox(height: 10),
                            _buildUploadButton(
                              "License Photo",
                              Icons.drive_eta,
                              () => _pickImage("License"),
                              licenseUploaded,
                            ),
                            const SizedBox(height: 20),
                          ],

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
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      isLogin ? "LOGIN" : "REGISTER",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          TextButton(
                            onPressed: () => setState(() {
                              isLogin = !isLogin;
                            }),
                            child: Text(
                              isLogin ? "New? Create Account" : "Back to Login",
                              style: const TextStyle(color: leafGreen),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? isObscured : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: leafGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: softMint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final displayRoles = isLogin ? loginRoles : registrationRoles;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayRoles.contains(selectedRole)
              ? selectedRole
              : displayRoles[0],
          isExpanded: true,
          items: displayRoles
              .map((r) => DropdownMenuItem(value: r, child: Text("Role: $r")))
              .toList(),
          onChanged: (value) => setState(() => selectedRole = value!),
        ),
      ),
    );
  }

  Widget _buildUploadButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDone,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: isDone ? leafGreen : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(15),
          color: softMint,
        ),
        child: Row(
          children: [
            Icon(icon, color: isDone ? leafGreen : Colors.grey),
            const SizedBox(width: 15),
            Text(isDone ? "Attached" : label),
            const Spacer(),
            Icon(isDone ? Icons.check_circle : Icons.cloud_upload),
          ],
        ),
      ),
    );
  }
}
