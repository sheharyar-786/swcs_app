import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

class CollectionHistoryPage extends StatelessWidget {
  const CollectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "COLLECTION LOGS",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF00695C), // Premium Teal
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeaderStats(uid!),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref('driver_history/$uid')
                  .onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00695C)),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return _buildEmptyState();
                }

                Map data = snapshot.data!.snapshot.value as Map;
                // Latest collections on top
                var historyList = data.entries.toList();
                historyList.sort((a, b) => b.key.compareTo(a.key));

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      var item = historyList[index].value;
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 600),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildHistoryCard(
                              area: item['area_name'] ?? "Unknown",
                              time: item['time'] ?? "--:--",
                              points: item['points'] ?? 0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Stats (Total Bins Collected) ---
  Widget _buildHeaderStats(String uid) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('driver_history/$uid').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        int total = 0;
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          total = (snapshot.data!.snapshot.value as Map).length;
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFF00695C),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "TOTAL BINS CLEARED",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "$total",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                "Eco-Mission Success",
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Premium History Card ---
  Widget _buildHistoryCard({
    required String area,
    required String time,
    required int points,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.auto_delete_rounded,
            color: Color(0xFF00695C),
          ),
        ),
        title: Text(
          area,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade700, width: 1),
          ),
          child: Text(
            "+$points XP",
            style: TextStyle(
              color: Colors.amber.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          const Text(
            "No collections recorded yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
