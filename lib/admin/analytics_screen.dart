import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color alertRed = Color(0xFFE53935);
  static const Color softMint = Color(0xFFE8F5E9);

  Map<String, dynamic> binData = {};
  late StreamSubscription _binsSubscription;

  @override
  void initState() {
    super.initState();
    // Listening to all bins real-time
    _binsSubscription = FirebaseDatabase.instance.ref('bins').onValue.listen((
      event,
    ) {
      if (event.snapshot.exists) {
        setState(() {
          binData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  void dispose() {
    _binsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalBins = binData.length;
    int criticalBins = binData.values
        .where((b) => (b['fill_level'] ?? 0) >= 80)
        .length;
    double avgFill = totalBins == 0
        ? 0
        : binData.values
                  .map((b) => b['fill_level'] ?? 0)
                  .reduce((a, b) => a + b) /
              totalBins;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          "📊 System Analytics",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PREMIUM SUMMARY CARDS ---
            _sectionLabel("Overview Statistics"),
            Row(
              children: [
                _buildStatCard(
                  "Active Units",
                  totalBins.toString(),
                  Icons.sensors,
                  Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Critical",
                  criticalBins.toString(),
                  Icons.warning_amber_rounded,
                  alertRed,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 2. CIRCULAR MONITORING (TOP 3 BINS) ---
            _sectionLabel("Live Bin Monitoring (Gauges)"),
            _buildCircularSection(),

            const SizedBox(height: 30),

            // --- 3. BAR CHART: ALL BINS COMPARISON ---
            _sectionLabel("Real-time Fill Comparison"),
            _buildBarChartCard(),

            const SizedBox(height: 30),

            // --- 4. LIVE LOGS SECTION ---
            _sectionLabel("Latest Activity Records"),
            _buildLiveStatusList(),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 15),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularSection() {
    var sortedBins = binData.entries.toList();
    if (sortedBins.isEmpty)
      return const Center(child: Text("Waiting for data..."));

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sortedBins.length,
        itemBuilder: (context, index) {
          double level = (sortedBins[index].value['fill_level'] ?? 0)
              .toDouble();
          Color color = level > 80 ? alertRed : leafGreen;
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: level / 100,
                        strokeWidth: 6,
                        backgroundColor: color.withOpacity(0.1),
                        color: color,
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        "${level.toInt()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sortedBins[index].key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: true),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Text(
                  "B${v.toInt() + 1}",
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, m) =>
                    Text("${v.toInt()}%", style: const TextStyle(fontSize: 8)),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: binData.entries.map((e) {
            int index = binData.keys.toList().indexOf(e.key);
            double level = (e.value['fill_level'] ?? 0).toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: level,
                  color: level > 80 ? alertRed : leafGreen,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLiveStatusList() {
    var list = binData.entries.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        var data = list[index].value;
        bool isFull = (data['fill_level'] ?? 0) >= 80;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isFull
                  ? alertRed.withOpacity(0.1)
                  : leafGreen.withOpacity(0.1),
              child: Icon(
                isFull ? Icons.priority_high : Icons.check,
                color: isFull ? alertRed : leafGreen,
                size: 18,
              ),
            ),
            title: Text(
              data['area'] ?? "Unknown Area",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text("Gas Level: ${data['gas_level'] ?? 0}"),
            trailing: Text(
              "${data['fill_level']}%",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isFull ? alertRed : deepForest,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 15, top: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: deepForest,
        letterSpacing: 0.5,
      ),
    ),
  );
}
