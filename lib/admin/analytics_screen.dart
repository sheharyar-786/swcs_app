import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Eco-Friendly Green Theme
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color warningRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "📊 System Insights",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP CARTOON SUMMARY SECTION ---
            _buildAnimatedSection(
              title: "Daily Collection Summary",
              child: _buildSummaryRow(),
            ),

            const SizedBox(height: 30),

            // --- SECTION: INDIVIDUAL BIN PERFORMANCE ---
            _buildAnimatedSection(
              title: "Bin #01: Today's Fill Cycles",
              child: _buildChartCard(
                height: 250,
                child: LineChart(_binSpecificLineData()),
              ),
            ),

            const SizedBox(height: 30),

            // --- SECTION: OVERALL WEEKLY EFFICIENCY ---
            _buildAnimatedSection(
              title: "Weekly Collection Rate",
              child: _buildChartCard(
                height: 200,
                child: BarChart(_weeklyBarData()),
              ),
            ),

            const SizedBox(height: 30),

            // --- SECTION: DETAILED LOGS ---
            _buildAnimatedSection(
              title: "Live Bin Records",
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for bouncy entry animations
  Widget _buildAnimatedSection({required String title, required Widget child}) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: childWidget,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: deepForest,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _buildStatBox("Total Bins", "12", "🗑️", leafGreen),
        const SizedBox(width: 15),
        _buildStatBox("Cleansed", "86%", "✨", Colors.blue),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, String emoji, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- INDIVIDUAL BIN CHART (Red/Green logic) ---
  LineChartData _binSpecificLineData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 10), // 8 AM - Empty (Green)
            FlSpot(2, 85), // 10 AM - Near Full (Red)
            FlSpot(4, 20), // 12 PM - Emptied
            FlSpot(6, 95), // 2 PM - Critical
            FlSpot(8, 5), // 4 PM - Emptied
          ],
          isCurved: true,
          color: leafGreen,
          barWidth: 6,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [leafGreen.withOpacity(0.3), warningRed.withOpacity(0.3)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: spot.y > 70 ? warningRed : leafGreen,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  BarChartData _weeklyBarData() {
    return BarChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        _buildBarGroup(0, 5, leafGreen),
        _buildBarGroup(1, 8, leafGreen),
        _buildBarGroup(2, 12, warningRed), // High activity day
        _buildBarGroup(3, 7, leafGreen),
        _buildBarGroup(4, 10, leafGreen),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildChartCard({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(25),
      ),
      child: child,
    );
  }

  Widget _buildHistoryList() {
    final List<Map<String, dynamic>> bins = [
      {"id": "Bin #01", "refills": 4, "status": "Stable", "color": leafGreen},
      {
        "id": "Bin #04",
        "refills": 7,
        "status": "Overflowing",
        "color": warningRed,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bins.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: softMint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            leading: Text(
              bins[index]['color'] == warningRed ? "⚠️" : "✅",
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              bins[index]['id'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: deepForest,
              ),
            ),
            subtitle: Text("Emptied ${bins[index]['refills']} times today"),
            trailing: Text(
              bins[index]['status'],
              style: TextStyle(
                color: bins[index]['color'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
