import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/stats_card.dart';

class AdminHomeView extends StatelessWidget {
  // Receive the broadcast stream from AdminMainShell
  final Stream<DatabaseEvent> globalStream;

  const AdminHomeView({super.key, required this.globalStream});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?q=80&w=1000',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.85),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Column(
          children: [
            // --- Premium Header ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                left: 25,
                right: 25,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0A714E),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(35),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello Admin 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "System Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Real-time monitoring of all entities",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
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
                      padding: const EdgeInsets.all(25),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      // --- FIX: Ratio set to avoid Overflow ---
                      childAspectRatio: 0.95,
                      children: [
                        _buildFixedStatsCard(
                          "TOTAL BINS",
                          "$totalBins",
                          Icons.delete_sweep,
                          Colors.green,
                        ),
                        _buildFixedStatsCard(
                          "MANAGERS",
                          "$managers",
                          Icons.support_agent,
                          Colors.blue,
                        ),
                        _buildFixedStatsCard(
                          "DRIVERS",
                          "$drivers",
                          Icons.local_shipping,
                          Colors.orange,
                        ),
                        _buildFixedStatsCard(
                          "CIVILIANS",
                          "$citizens",
                          Icons.location_city,
                          Colors.purple,
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
