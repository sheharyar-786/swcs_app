import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CollectionRateChart extends StatelessWidget {
  const CollectionRateChart({super.key});

  // --- Eco-Friendly Green Theme ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color warningYellow = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25), // Matches Admin Card style
          boxShadow: [
            BoxShadow(
              color: leafGreen.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 20,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (BarChartGroupData group) => deepForest,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} Bins Cleaned',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const titles = [
                      'Area A',
                      'Area B',
                      'Area C',
                      'Area D',
                      'Area E',
                    ];
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        titles[value.toInt()],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              _makeGroupData(0, 12, leafGreen),
              _makeGroupData(1, 18, deepForest),
              _makeGroupData(2, 8, warningYellow), // Low collection warning
              _makeGroupData(3, 15, leafGreen),
              _makeGroupData(4, 10, leafGreen),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          // This represents the "Total Bin Capacity" per area
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: softMint,
          ),
        ),
      ],
    );
  }
}
