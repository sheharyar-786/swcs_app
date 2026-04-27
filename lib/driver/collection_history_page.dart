import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CollectionHistoryPage extends StatelessWidget {
  const CollectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80.0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "COLLECTION LOGS",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFF0A714E),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0A714E)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (uid != null) SliverToBoxAdapter(child: _buildHeaderStats(uid)),
          SliverFillRemaining(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('lib/assets/bg.jpeg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.9),
                    BlendMode.lighten,
                  ),
                ),
              ),
              child: uid == null
                  ? const Center(child: Text("User not logged in"))
                  : StreamBuilder(
                      stream: FirebaseDatabase.instance
                          .ref('driver_history/$uid')
                          .onValue,
                      builder:
                          (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF00695C),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.snapshot.value == null) {
                              return _buildEmptyState();
                            }

                            Map data = snapshot.data!.snapshot.value as Map;
                            var historyList = data.entries.toList();

                            // Sort: Latest collections on top
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
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: const Color(0xFF0A714E),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A714E).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "TOTAL BINS CLEARED",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$total",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Eco-Mission Success 🏆",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Fixed History Card (Overflow Proof) ---
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            // Icon Section
            Container(
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
            const SizedBox(width: 15),

            // Text Section - WRAPPED IN EXPANDED TO FIX OVERFLOW
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:
                          15, // Slightly smaller to give more breathing room
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis, // Adds "..." if name is too long
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        // Ensures time string doesn't push badge
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Points Badge Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700, width: 1),
              ),
              child: Text(
                "+$points XP",
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
