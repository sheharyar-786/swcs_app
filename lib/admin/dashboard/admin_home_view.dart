import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'widgets/stats_card.dart';
import 'support_inbox_view.dart';
import '../../widgets/admin_header.dart';

import '../user_management/staff_directory.dart'; // Import navigation target

class AdminHomeView extends StatelessWidget {
  // Receive the broadcast stream from AdminMainShell
  final Stream<DatabaseEvent> globalStream;

  const AdminHomeView({super.key, required this.globalStream});

  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color deepForest = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          AdminHeader(
            title: "Management Hub",
            showBackButton: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const SupportInboxView(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeInLeft(
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
          ),
          StreamBuilder(
            stream: globalStream,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                Map data = snapshot.data!.snapshot.value as Map;
                int totalBins = (data['bins'] as Map?)?.length ?? 0;
                Map users = data['users'] ?? {};
                Map verifiedDrivers = data['verified_drivers'] ?? {};

                int managers = users.values
                    .where((u) => u['role'] == 'manager')
                    .length;
                int drivers = users.values
                        .where((u) => u['role'] == 'driver')
                        .length +
                    verifiedDrivers.length;
                int citizens = users.values
                    .where((u) => u['role'] == 'civilian')
                    .length;

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  sliver: SliverGrid.count(
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
                          leafGreen,
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildFixedStatsCard(
                          "MANAGERS",
                          "$managers",
                          Icons.support_agent,
                          const Color(0xFF0288D1),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => StaffDirectory(globalStream: globalStream))),
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: _buildFixedStatsCard(
                          "DRIVERS",
                          "$drivers",
                          Icons.local_shipping,
                          const Color(0xFFF57C00),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => StaffDirectory(globalStream: globalStream))),
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildFixedStatsCard(
                          "CIVILIANS",
                          "$citizens",
                          Icons.location_city,
                          const Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text("Error: ${snapshot.error}")),
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

  // Helper function to ensure StatsCard doesn't overflow
  Widget _buildFixedStatsCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return SizedBox(
      // Constraining height to prevent overflow
      height: 120,
      child: StatsCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }
}

