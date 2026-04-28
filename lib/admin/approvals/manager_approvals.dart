import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/admin_header.dart';

class ManagerApprovals extends StatelessWidget {
  final Stream<DatabaseEvent> globalStream;
  final DatabaseEvent? initialData;

  const ManagerApprovals({
    super.key,
    required this.globalStream,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: "Approvals",
            showBackButton: true,
          ),
          SliverToBoxAdapter(child: _buildStatementBar()),
          StreamBuilder(
            stream: globalStream,
            initialData: initialData,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map allData = snapshot.data!.snapshot.value as Map;
                Map? pendingManagers = allData['pending_managers'] as Map?;

                if (pendingManagers == null || pendingManagers.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState());
                }

                var pendingList = pendingManagers.entries.toList();

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var uid = pendingList[index].key;
                        var data = pendingList[index].value as Map;

                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: 100 * index),
                          child: _buildApprovalCard(context, uid, data),
                        );
                      },
                      childCount: pendingList.length,
                    ),
                  ),
                );
              }

              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0A714E)),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- UI Components ---

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
