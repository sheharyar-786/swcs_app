import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';

class UserDetailsEdit extends StatefulWidget {
  final String uid;
  final Map userData;

  const UserDetailsEdit({super.key, required this.uid, required this.userData});

  @override
  State<UserDetailsEdit> createState() => _UserDetailsEditState();
}

class _UserDetailsEditState extends State<UserDetailsEdit> {
  late TextEditingController _nameController;
  late bool _isSuspended;

  String get _collection =>
      widget.userData['role'] == 'driver' ? 'verified_drivers' : 'users';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _isSuspended = widget.userData['isSuspended'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          "Manage Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            _buildStatementBar(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildEditField(
                    "Full Name",
                    widget.userData['name'] ?? "Unknown",
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildWarningCenter(),
                  const SizedBox(height: 20),
                  _buildStatusToggle(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                FadeInDown(
                  child: Center(
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF0A714E).withValues(alpha: 0.1),
                      child: Text(
                        (widget.userData['name']?.toString().isNotEmpty == true
                                ? widget.userData['name'][0]
                                : "U")
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          color: Color(0xFF0A714E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  (widget.userData['name']?.toString() ?? "User Profile").toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
          border: Border.all(color: const Color(0xFF0A714E).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF0A714E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Role: ${widget.userData['role'].toString().toUpperCase()} | Status: ${_isSuspended ? 'Suspended' : 'Active'}",
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

  Widget _buildEditField(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0A714E), size: 20),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCenter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                "WARNING & ACTION CENTER",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: Colors.orange,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Send an official warning to this manager/driver regarding pending approvals or complaints.",
            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _sendWarning(),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text("SEND OFFICIAL WARNING", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _sendWarning() async {
    final ref = FirebaseDatabase.instance.ref('$_collection/${widget.uid}/warnings');
    await ref.push().set({
      'message': 'Official Warning: Pending approvals/complaints require immediate attention.',
      'timestamp': ServerValue.timestamp,
      'type': 'ADMIN_WARNING',
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Warning sent to staff member!"),
        backgroundColor: Colors.orange,
      ),
    );
  }


  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Account Status",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _isSuspended ? "User is Suspended" : "User is Active",
                style: TextStyle(
                  color: _isSuspended ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch(
            value: _isSuspended,
            activeThumbColor: Colors.red,
            onChanged: (val) {
              setState(() => _isSuspended = val);
              FirebaseDatabase.instance
                  .ref('$_collection/${widget.uid}')
                  .update({'isSuspended': val});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => _confirmDelete(),
          icon: const Icon(Icons.delete_forever, color: Colors.red),
          label: const Text(
            "DELETE ACCOUNT PERMANENTLY",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Staff?"),
        content: const Text(
          "Are you sure you want to remove this user from the system? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              FirebaseDatabase.instance
                  .ref('$_collection/${widget.uid}')
                  .remove();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
