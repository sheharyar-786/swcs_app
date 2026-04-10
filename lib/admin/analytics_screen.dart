import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'bin_details.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color softMint = Color(0xFFE8F5E9);

  Map<String, dynamic> binData = {};
  late StreamSubscription _binsSubscription;

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Stack(
        children: [
          // --- PROFESSIONAL ANALYTICS BACKGROUND IMAGE ---
          Positioned.fill(
            child: Opacity(
              opacity: 0.05, // Very subtle so it doesn't distract
              child: Image.network(
                'https://img.freepik.com/free-vector/abstract-technology-particle-background_52683-25766.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. BEAUTIFUL PROFESSIONAL HEADER
              _buildSliverAppBar(totalBins, criticalBins),

              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          // 2. SUMMARY CARDS
                          _sectionLabel("Quick Metrics"),
                          _buildQuickMetrics(totalBins, criticalBins),

                          const SizedBox(height: 25),

                          // 3. HORIZONTAL GAUGE LIST (CLICKABLE)
                          _sectionLabel("Live Bin Gauges"),
                          _buildCircularSection(),

                          const SizedBox(height: 25),

                          // 4. BAR CHART COMPARISON
                          _sectionLabel("Fleet Fill Comparison (%)"),
                          _buildBarChartCard(),

                          const SizedBox(height: 25),

                          // 5. DETAILED LIST (CLICKABLE)
                          _sectionLabel("Detailed Fleet Status"),
                          _buildLiveStatusList(),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(int total, int critical) {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: leafGreen,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "SYSTEM ANALYTICS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [deepForest, leafGreen],
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: 40,
              child: Icon(
                Icons.analytics_outlined,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetrics(int total, int critical) {
    return Row(
      children: [
        _buildStatCard(
          "Total Units",
          total.toString(),
          Icons.sensors,
          Colors.blue,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          "Action Required",
          critical.toString(),
          Icons.warning_rounded,
          alertRed,
        ),
      ],
    );
  }

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
          color: Colors.white.withOpacity(
            0.9,
          ), // Slight transparency for background blend
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
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
    if (sortedBins.isEmpty) return const Center(child: Text("Syncing..."));

    return SizedBox(
      height: 145,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sortedBins.length,
        itemBuilder: (context, index) {
          String id = sortedBins[index].key;
          double level = (sortedBins[index].value['fill_level'] ?? 0)
              .toDouble();
          Color color = level >= 80 ? alertRed : leafGreen;

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => BinDetailsPage(binId: id)),
            ),
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 15, bottom: 5),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: level / 100,
                          strokeWidth: 8,
                          backgroundColor: color.withOpacity(0.1),
                          color: color,
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          "${level.toInt()}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    id.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "B${v.toInt() + 1}",
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (v, m) => Text(
                  "${v.toInt()}%",
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
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
          borderData: FlBorderData(show: false),
          barGroups: binData.entries.map((e) {
            int index = binData.keys.toList().indexOf(e.key);
            double level = (e.value['fill_level'] ?? 0).toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: level,
                  color: level >= 80 ? alertRed : leafGreen,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: softMint,
                  ),
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
        String id = list[index].key;
        bool isFull = (data['fill_level'] ?? 0) >= 80;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => BinDetailsPage(binId: id)),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isFull
                          ? alertRed.withOpacity(0.1)
                          : leafGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFull
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: isFull ? alertRed : leafGreen,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    data['area'] ?? "Unknown Area",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "ID: ${id.toUpperCase()} • Gas: ${data['gas_level'] ?? 0}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${data['fill_level']}%",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isFull ? alertRed : deepForest,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "LEVEL",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 15, top: 10),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: leafGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: deepForest,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}
