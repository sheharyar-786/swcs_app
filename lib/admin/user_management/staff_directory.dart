import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'user_details_edit.dart';

class StaffDirectory extends StatefulWidget {
  const StaffDirectory({super.key, this.globalStream});
  final Stream<DatabaseEvent>? globalStream;

  @override
  State<StaffDirectory> createState() => _StaffDirectoryState();
}

class _StaffDirectoryState extends State<StaffDirectory> {
  String _statusFilter = 'All'; // 'All', 'Active', 'Pending'

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        body: Column(
          children: [
            /// Premium Header (Safe Design - Square)
            Container(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'lib/assets/bg.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0A714E)),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            const Color(0xFF0A714E).withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            "STAFF DETAILS",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Info Bar (Statement Bar)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A714E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.people_outline, color: Color(0xFF0A714E), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Manage and view details of managers and field staff.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A714E)),
                    ),
                  ),
                ],
              ),
            ),

            /// Status Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: Row(
                children: [
                  _filterChip("All"),
                  const SizedBox(width: 10),
                  _filterChip("Active"),
                  const SizedBox(width: 10),
                  _filterChip("Pending"),
                ],
              ),
            ),

            /// Tabs
            Container(
              margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const TabBar(
                labelColor: Color(0xFF0A714E),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF0A714E),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: "MANAGERS"),
                  Tab(text: "DRIVERS"),
                ],
              ),
            ),

            /// Data Content
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref().onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0A714E)));
                  }
                  
                  final data = Map<String, dynamic>.from(snapshot.data?.snapshot.value as Map? ?? {});
                  final users = Map<String, dynamic>.from(data['users'] as Map? ?? {});
                  final verified = Map<String, dynamic>.from(data['verified_drivers'] as Map? ?? {});
                  final pending = Map<String, dynamic>.from(data['pending_drivers'] as Map? ?? {});

                  return TabBarView(
                    children: [
                      _buildStaffList('manager', users, {}, {}),
                      _buildStaffList('driver', users, verified, pending),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A714E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0A714E) : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0A714E).withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList(String role, Map<String, dynamic> users, Map<String, dynamic> verified, Map<String, dynamic> pending) {
    List<Map<String, dynamic>> list = [];

    users.forEach((key, value) {
      final user = Map<String, dynamic>.from(value as Map);
      if (user['role'] == role) {
        list.add(user..['uid'] = key);
      }
    });

    if (role == 'driver') {
      verified.forEach((key, value) {
        if (!list.any((e) => e['uid'] == key)) {
          list.add(Map<String, dynamic>.from(value as Map)..['uid'] = key);
        }
      });
      pending.forEach((key, value) {
        if (!list.any((e) => e['uid'] == key)) {
          list.add(Map<String, dynamic>.from(value as Map)..['uid'] = key);
        }
      });
    }

    // Apply Status Filter
    if (_statusFilter != 'All') {
      list = list.where((staff) {
        final status = (staff['status'] ?? (staff['isApproved'] == true ? "Active" : "Pending")).toString().toLowerCase();
        return status == _statusFilter.toLowerCase();
      }).toList();
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          "No $_statusFilter staff found in this category.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final staff = list[index];
        final status = staff['status'] ?? (staff['isApproved'] == true ? "Active" : "Pending");

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsEdit(
                uid: staff['uid'],
                userData: staff,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF0A714E).withOpacity(0.1),
                  child: Icon(role == 'manager' ? Icons.support_agent : Icons.local_shipping, color: const Color(0xFF0A714E)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(staff['email'] ?? "No Email", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    bool isActive = status.toLowerCase() == 'active' || status.toLowerCase() == 'true' || status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.orange),
      ),
    );
  }
}
