import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FillLevelChart extends StatelessWidget {
  const FillLevelChart({super.key});

  // --- Eco-Friendly Green Theme ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color warningYellow = Color(0xFFFFD54F);
  static const Color dangerRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // Cartoon-style rounding
          boxShadow: [
            BoxShadow(
              color: leafGreen.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              show: true,
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
                  interval: 1,
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  getTitlesWidget: leftTitleWidgets,
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 7,
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 10),
                  FlSpot(1, 25),
                  FlSpot(2, 65), // Warning level
                  FlSpot(3, 40),
                  FlSpot(4, 85), // Critical level
                  FlSpot(5, 95),
                  FlSpot(6, 15), // Reset after collection
                  FlSpot(7, 35),
                ],
                isCurved: true,
                curveSmoothness: 0.35,
                color: leafGreen,
                barWidth: 5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    // Logic to change dot color based on level
                    Color dotColor = leafGreen;
                    if (spot.y >= 80) {
                      dotColor = dangerRed;
                    } else if (spot.y >= 60)
                      dotColor = warningYellow;

                    return FlDotCirclePainter(
                      radius: 5,
                      color: dotColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      leafGreen.withOpacity(0.2),
                      leafGreen.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1000), // Bouncy animation
          curve: Curves.easeInOutBack,
        ),
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'MON';
        break;
      case 2:
        text = 'WED';
        break;
      case 4:
        text = 'FRI';
        break;
      case 6:
        text = 'SUN';
        break;
      default:
        return const SizedBox();
    }
    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 10,
      child: Text(
        '${value.toInt()}%',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
