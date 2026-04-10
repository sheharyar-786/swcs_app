import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class BinDetailsPage extends StatelessWidget {
  final String binId; // Pass "bin_01", "bin_02", etc.
  const BinDetailsPage({super.key, required this.binId});

  // Theme Colors
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color premiumNavy = Color(0xFF0D47A1);
  static const Color warningOrange = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listening specifically to your 'bins/bin_01' path in Real-time
      stream: FirebaseDatabase.instance.ref('bins/$binId').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: leafGreen)),
          );
        }

        // Mapping your Firebase data
        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        double fillLevel = (data['fill_level'] ?? 0).toDouble();
        int gasLevel = data['gas_level'] ?? 0;
        String status = data['status'] ?? "Unknown";
        String area = data['area'] ?? "Unknown Location";
        int battery = data['battery'] ?? 100;

        // Logic for Driver Message & Alerts
        bool isOnRoute = status == "On Route" || status == "Assigned";
        bool isCritical = fillLevel >= 80;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F4), // Premium Light Background
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title: Column(
              children: [
                Text(
                  binId.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  area,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {}, // Firebase updates automatically
              ),
            ],
          ),
          body: AnimationLimiter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 500),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    // 1. DYNAMIC STATUS BANNER (Alert Logic)
                    _buildStatusBanner(context, isOnRoute, isCritical, data),

                    const SizedBox(height: 20),

                    // 2. PREMIUM FILL CARD (Main Visual) - CONTEXT PASSED HERE
                    _buildFillCard(context, fillLevel),

                    const SizedBox(height: 20),

                    // 3. INFORMATION GRID (4-Box Style)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        _infoBox(
                          "Gas Level",
                          "$gasLevel ppm",
                          Icons.cloud_outlined,
                          gasLevel > 800 ? warningOrange : Colors.teal,
                        ),
                        _infoBox(
                          "Battery",
                          "$battery%",
                          Icons.battery_charging_full,
                          battery < 20 ? alertRed : leafGreen,
                        ),
                        _infoBox(
                          "Last Action",
                          data['last_cleaned_by'] ?? "N/A",
                          Icons.history,
                          premiumNavy,
                        ),
                        _infoBox(
                          "Bin Status",
                          status,
                          Icons.info_outline,
                          isOnRoute ? leafGreen : Colors.blueGrey,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // 4. REAL-TIME TREND CHART (24h Activity)
                    _buildTrendChart(fillLevel >= 80 ? alertRed : leafGreen),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    bool isOnRoute,
    bool isCritical,
    Map data,
  ) {
    String msg = "System Monitoring Active";
    Color color = Colors.blue;
    IconData icon = Icons.verified_user_outlined;

    if (isOnRoute) {
      msg = "COLLECTION IN PROGRESS: Driver is on the way";
      color = leafGreen;
      icon = Icons.local_shipping_rounded;
    } else if (isCritical) {
      msg = "URGENT ACTION REQUIRED: Bin is overflowing";
      color = alertRed;
      icon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isCritical && !isOnRoute)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: InkWell(
                      onTap: () {
                        // This links back to your Admin Dashboard Assignment logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Redirecting to Duty Assignment..."),
                          ),
                        );
                      },
                      child: const Text(
                        "CLICK TO ASSIGN NEAREST DRIVER →",
                        style: TextStyle(
                          color: alertRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FIXED: ADDED BuildContext context to signature ---
  Widget _buildFillCard(BuildContext context, double level) {
    Color color = level >= 80 ? alertRed : leafGreen;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Live Capacity",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.sensors, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${level.toInt()}%",
            style: TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 18,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 18,
                // --- FIXED: context is now recognized here ---
                width: (MediaQuery.of(context).size.width - 90) * (level / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            level >= 80 ? "CRITICAL STATUS" : "STABLE CONDITION",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            val,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF2D3436),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(Color color) {
    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fill Level Trend (24h)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 20),
                      FlSpot(1, 35),
                      FlSpot(2, 55),
                      FlSpot(3, 45),
                      FlSpot(4, 75),
                      FlSpot(5, 85),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
