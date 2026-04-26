import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'widgets/stats_card.dart';
import 'support_inbox_view.dart';

class AdminHomeView extends StatelessWidget {
  // Receive the broadcast stream from AdminMainShell
  final Stream<DatabaseEvent> globalStream;

  const AdminHomeView({super.key, required this.globalStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        color: const Color(0xFFF8FAF9), // Clean light background
        child: Column(
          children: [
            // --- Premium Unified Header ---
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(35),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(35),
                    ),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: 0.0,
                        sigmaY: 0.0,
                      ),
                      child: Image.asset(
                        'lib/assets/bg.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(35),
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
                  const Padding(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Panel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --- SUPPORT INBOX ACCESS ---
                  Positioned(
                    top: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const SupportInboxView(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Color(0xFF0A714E),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Styled Statement Bar ---
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A714E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF0A714E).withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF0A714E),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Real-time system overview and live statistical tracking.",
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
            ),

            Expanded(
              child: StreamBuilder(
                // Using the broadcast stream to avoid "Bad State" error
                stream: globalStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    Map data = snapshot.data!.snapshot.value as Map;

                    // --- Logic: Safe Data Fetching ---
                    Map users = data['users'] ?? {};
                    Map verifiedDrivers = data['verified_drivers'] ?? {};

                    // Counting based on roles
                    int managers = users.values
                        .where((u) => u['role'] == 'manager')
                        .length;
                    int drivers =
                        users.values
                            .where((u) => u['role'] == 'driver')
                            .length +
                        verifiedDrivers.length;
                    int citizens = users.values
                        .where((u) => u['role'] == 'civilian')
                        .length;

                    // Safe fetching of metadata
                    int totalBins = 0;
                    if (data['system_metadata'] != null) {
                      totalBins = data['system_metadata']['total_bins'] ?? 0;
                    }

                    return GridView.count(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.95,
                      children: [
                        FadeInUp(
                          delay: const Duration(milliseconds: 100),
                          child: _buildFixedStatsCard(
                            "TOTAL BINS",
                            "$totalBins",
                            Icons.delete_sweep,
                            Colors.green,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: _buildFixedStatsCard(
                            "MANAGERS",
                            "$managers",
                            Icons.support_agent,
                            Colors.blue,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 300),
                          child: _buildFixedStatsCard(
                            "DRIVERS",
                            "$drivers",
                            Icons.local_shipping,
                            Colors.orange,
                          ),
                        ),
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          child: _buildFixedStatsCard(
                            "CIVILIANS",
                            "$citizens",
                            Icons.location_city,
                            Colors.purple,
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
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

  // Helper function to ensure StatsCard doesn't overflow
  Widget _buildFixedStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      // Constraining height to prevent overflow
      height: 120,
      child: StatsCard(title: title, value: value, icon: icon, color: color),
    );
  }
}
