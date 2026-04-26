import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';

class ManagerApprovals extends StatelessWidget {
  final Stream<DatabaseEvent> globalStream;

  const ManagerApprovals({super.key, required this.globalStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        color: const Color(0xFFF8FAF9),
        child: Column(
          children: [
            _buildPremiumHeader(),
            _buildStatementBar(),
            Expanded(
              child: StreamBuilder(
                stream: globalStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
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
      ),
    );
  }

  // --- UI Components ---

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Image.asset(
                'lib/assets/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(35)),
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
          const Padding(
            padding: EdgeInsets.only(left: 25, right: 25, bottom: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Approvals",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
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
        child: const Row(
          children: [
            Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF0A714E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Review and authorize new staff registration requests.",
                style: TextStyle(
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

  Widget _buildApprovalCard(BuildContext context, String uid, Map data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
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
