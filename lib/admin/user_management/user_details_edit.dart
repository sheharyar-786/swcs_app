import 'package:flutter/material.dart';
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

  String get _collection => widget.userData['role'] == 'driver' ? 'verified_drivers' : 'users';

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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A714E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildEditField(
                    "Full Name",
                    _nameController,
                    Icons.person_outline,
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0A714E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          FadeInDown(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white24,
              child: Text(
                widget.userData['name'][0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            widget.userData['role'].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.userData['email'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF0A714E)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
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
              FirebaseDatabase.instance.ref('$_collection/${widget.uid}').update({
                'isSuspended': val,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A714E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              FirebaseDatabase.instance.ref('$_collection/${widget.uid}').update({
                'name': _nameController.text,
              });
              Navigator.pop(context);
            },
            child: const Text(
              "UPDATE PROFILE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
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
              FirebaseDatabase.instance.ref('$_collection/${widget.uid}').remove();
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
