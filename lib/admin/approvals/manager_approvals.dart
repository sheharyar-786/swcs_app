import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';

class ManagerApprovals extends StatelessWidget {
  final Stream<DatabaseEvent> globalStream;

  const ManagerApprovals({super.key, required this.globalStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(
            child: StreamBuilder(
              stream: globalStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  Map allData = snapshot.data!.snapshot.value as Map;

                  // SCREENSHOT FIX: Fetching from 'pending_managers' node
                  Map? pendingManagers = allData['pending_managers'] as Map?;

                  if (pendingManagers == null || pendingManagers.isEmpty) {
                    return _buildEmptyState();
                  }

                  var pendingList = pendingManagers.entries.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: pendingList.length,
                    itemBuilder: (context, index) {
                      var uid = pendingList[index].key;
                      var data = pendingList[index].value as Map;

                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: 100 * index),
                        child: _buildApprovalCard(context, uid, data),
                      );
                    },
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0A714E)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0A714E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manager Approvals",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Verify and authorize staff access",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, String uid, Map data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.person_outline, color: Colors.orange),
            ),
            title: Text(
              data['name'] ?? "New Manager",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(data['email'] ?? "No Email"),
          ),
          const Divider(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectManager(uid),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("REJECT"),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveManager(uid, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A714E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "APPROVE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Logic: Approve/Reject ---

  void _approveManager(String uid, Map data) async {
    final dbRef = FirebaseDatabase.instance.ref();

    // 1. Move to 'users' node with manager role
    await dbRef.child('users').child(uid).set({
      ...data,
      'isApproved': true,
      'role': 'manager',
    });

    // 2. Remove from 'pending_managers'
    await dbRef.child('pending_managers').child(uid).remove();
  }

  void _rejectManager(String uid) async {
    await FirebaseDatabase.instance
        .ref()
        .child('pending_managers')
        .child(uid)
        .remove();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text(
            "No Pending Approvals",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
