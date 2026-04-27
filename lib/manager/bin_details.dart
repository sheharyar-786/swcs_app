import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'manager_dashboard.dart';
import 'bin_record_page.dart';
import 'bin_utils.dart';

class BinDetailsPage extends StatefulWidget {
  final String binId;
  const BinDetailsPage({super.key, required this.binId});

  @override
  State<BinDetailsPage> createState() => _BinDetailsPageState();
}

class _BinDetailsPageState extends State<BinDetailsPage>
    with TickerProviderStateMixin {
  // Theme Colors
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color premiumNavy = Color(0xFF0D47A1);
  static const Color warningOrange = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('bins/${widget.binId}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: leafGreen)),
          );
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );

        // --- REAL-TIME DATA MAPPING via BinData utility ---
        double fillLevel  = BinData.fillLevel(data);
        int    gasLevel   = BinData.gasLevel(data);
        String status     = BinData.status(data);
        String area       = BinData.area(data);
        String connStatus = BinData.connectionStatus(data);
        bool isOnline     = BinData.isOnline(data);

        // Battery
        var batteryRaw     = BinData.battery(data);
        String batteryDisplay = BinData.batteryDisplay(data);
        int batteryVal = batteryRaw == null
            ? 0
            : (int.tryParse(batteryRaw.toString()) ?? 0);

        // Analytics Data
        int fillCountToday = data['fill_count_today'] ?? 0;
        String lastFillTime = data['last_full_time'] ?? "No data";

        bool isOnRoute = status == "On Route" || status == "Assigned";
        bool isCritical = fillLevel >= 80;

        // --- HARDWARE SYNC LOGIC ---
        // If the bin is offline, we should not show old/stale data values
        String displayFill = isOnline ? "${fillLevel.toInt()}%" : "--";
        String displayGas = isOnline ? "$gasLevel ppm" : "--";
        String displayBattery = isOnline ? batteryDisplay : "--";
        String displayLastAction = data['last_cleaned_by'] ?? "No History";

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F4),
          body: Column(
            children: [
              _buildPremiumHeader(context, area),
              Expanded(
                child: AnimationLimiter(
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
                          // 1. Alert Banner
                          _buildStatusBanner(
                            context,
                            isOnRoute,
                            isCritical,
                            area,
                          ),
                          const SizedBox(height: 20),

                          // 2. Main Capacity Card
                          _buildFillCard(context, isOnline ? fillLevel : 0.0),
                          const SizedBox(height: 20),

                          // 3. Info Grid (Live Battery, Gas, etc)
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
                                displayGas,
                                Icons.cloud_outlined,
                                (isOnline && gasLevel > 800) ? warningOrange : Colors.teal,
                              ),
                              _infoBox(
                                "Battery",
                                displayBattery,
                                Icons.battery_charging_full,
                                (isOnline && batteryVal < 20) ? alertRed : leafGreen,
                              ),
                              _infoBox(
                                "Last Action",
                                displayLastAction,
                                Icons.history,
                                premiumNavy,
                              ),
                              _infoBox(
                                "Bin Status",
                                isOnline ? "Online" : "Offline",
                                isOnline ? Icons.sensors : Icons.sensors_off,
                                isOnline ? leafGreen : Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // 5. Weekly Trend Chart
                          _buildTimeTrendChart(
                            fillLevel >= 80 ? alertRed : leafGreen,
                            fillLevel,
                          ),
                          const SizedBox(height: 20),

                          // 6. View Full Record Button
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => BinRecordPage(
                                  binId: widget.binId,
                                  area: area,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF0D47A1).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_edu_rounded,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    "VIEW FULL RECORD",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.chevron_right_rounded,
                                      color: Colors.white70, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleManualRedirect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Loading Duty Assignments..."),
        backgroundColor: premiumNavy,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPage(scrollToUrgent: true),
      ),
    );
  }

  // --- 1. AREA UPDATE LOGIC (FIXED) ---
  Future<void> updateBinArea(String binId, String currentArea) async {
    TextEditingController areaEditController = TextEditingController(
      text: currentArea,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Bin Location"),
        content: TextField(
          controller: areaEditController,
          decoration: const InputDecoration(
            labelText: "Area Name",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: leafGreen),
            onPressed: () async {
              // Path 1: metadata folder
              await FirebaseDatabase.instance
                  .ref('bins/$binId/metadata/area')
                  .set(areaEditController.text.trim());
              // Path 2: root area (for lists)
              await FirebaseDatabase.instance
                  .ref('bins/$binId/area')
                  .set(areaEditController.text.trim());

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Area Updated Successfully!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. BIN DELETE LOGIC ---
  Future<void> deleteBin(String binId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete"),
        content: const Text(
          "Dhyan dein! Is se Firebase se bin ka data mukammal khatam ho jayega. Kya aap waqai delete karna chahte hain?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: alertRed),
            onPressed: () async {
              await FirebaseDatabase.instance.ref('bins/$binId').remove();
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bin Deleted from System"),
                  backgroundColor: alertRed,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatsCard(int count, String time) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [premiumNavy, Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: premiumNavy.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Operational Frequency",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                count == 0 ? "No collections yet" : "Filled $count Times Today",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white54,
                size: 20,
              ),
              Text(
                "Last Full: $time",
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    bool isOnRoute,
    bool isCritical,
    String area,
  ) {
    String msg = "System Monitoring Active";
    Color color = Colors.blue;
    IconData icon = Icons.verified_user_outlined;

    if (isOnRoute) {
      msg = "COLLECTION IN PROGRESS";
      color = leafGreen;
      icon = Icons.local_shipping_rounded;
    } else if (isCritical) {
      msg = "CRITICAL: Bin is Overflowing";
      color = alertRed;
      icon = Icons.warning_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
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
                  InkWell(
                    onTap: () => _handleManualRedirect(),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        "ASSIGN NEAREST DRIVER NOW →",
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
            color: color.withValues(alpha: 0.05),
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
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.sensors,
                color: color.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
          Text(
            "${level.toInt()}%",
            style: TextStyle(
              fontSize: 65,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 14,
                width: (MediaQuery.of(context).size.width - 90) * (level / 100),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            level >= 80 ? "IMMEDIATE ATTENTION REQUIRED" : "STABLE",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
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

  Widget _buildTimeTrendChart(Color color, double currentFill) {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Fill Analytics",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          child: Text(
                            days[value.toInt() % 7],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 45),
                      const FlSpot(1, 30),
                      const FlSpot(2, 85),
                      const FlSpot(3, 20),
                      const FlSpot(4, 55),
                      const FlSpot(5, 40),
                      FlSpot(6, currentFill),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Center(
            child: Text(
              "Data updated every 5 seconds",
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context, String area) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
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
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_location_alt, color: leafGreen),
                  onPressed: () => updateBinArea(widget.binId, area),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: alertRed),
                  onPressed: () => deleteBin(widget.binId),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                widget.binId.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                area,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
