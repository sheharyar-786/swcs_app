import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FillLevelChart extends StatefulWidget {
  const FillLevelChart({super.key});

  @override
  State<FillLevelChart> createState() => _FillLevelChartState();
}

class _FillLevelChartState extends State<FillLevelChart> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color alertRed = Color(0xFFE53935);
  static const Color softMint = Color(0xFFE8F5E9);

  // Map to hold live levels of all 10 bins
  Map<String, double> binLevels = {
    "bin_01": 0,
    "bin_02": 0,
    "bin_03": 0,
    "bin_04": 0,
    "bin_05": 0,
    "bin_06": 0,
    "bin_07": 0,
    "bin_08": 0,
    "bin_09": 0,
    "bin_10": 0,
  };

  @override
  void initState() {
    super.initState();
    _listenToAllBins();
  }

  // --- FIREBASE: Listening to all 10 bins at once ---
  void _listenToAllBins() {
    FirebaseDatabase.instance.ref('bins').onValue.listen((event) {
      if (event.snapshot.exists) {
        Map data = event.snapshot.value as Map;
        setState(() {
          data.forEach((key, value) {
            if (binLevels.containsKey(key)) {
              binLevels[key] = (value['fill_level'] ?? 0).toDouble();
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "REAL-TIME BIN LEVELS (10 UNITS)",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt() + 1;
                          return Text(
                            "B$index",
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 50,
                        getTitlesWidget: (val, meta) => Text(
                          "${val.toInt()}%",
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
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
                  barGroups: _generateBarGroups(),
                ),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups() {
    List<BarChartGroupData> groups = [];
    int i = 0;
    binLevels.forEach((id, level) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: level,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              // Color logic: Red if > 80%
              color: level > 80 ? alertRed : leafGreen,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: softMint.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
      i++;
    });
    return groups;
  }
}
