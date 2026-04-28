import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'bin_details.dart';
import 'bin_utils.dart';

import '../widgets/seven_day_trend_chart.dart';

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
        .where((b) => BinData.fillLevel(b) >= 80)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Stack(
        children: [
          // --- PROFESSIONAL ANALYTICS BACKGROUND IMAGE ---
          Positioned.fill(
            child: Opacity(
              opacity: 0.05, // Very subtle so it doesn't distract
              child: Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
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
                          // 2. PREMIUM 7-DAY TREND CHARTS (Like the reference image)
                          _sectionLabel("Performance Analytics"),
                          SizedBox(
                            height: 320,
                            child: PageView(
                              children: const [
                                SevenDayTrendChart(
                                  data: [42, 58, 35, 78, 52, 65, 48],
                                  title: "Waste Generation Trend",
                                ),
                                SevenDayTrendChart(
                                  data: [80, 65, 90, 70, 85, 95, 88],
                                  title: "Collection Efficiency",
                                ),
                              ],
                            ),
                          ),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Swipe left to see more charts",
                                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),


                          // 3. SUMMARY CARDS
                          _sectionLabel("Quick Metrics"),
                          _buildQuickMetrics(totalBins, criticalBins),

                          const SizedBox(height: 25),

                          // 4. HORIZONTAL GAUGE LIST (CLICKABLE)
                          _sectionLabelWithSubtitle("Live Bin Gauges", "Status based on 15-second activity window"),
                          _buildCircularSection(),



                          const SizedBox(height: 25),

                          // 5. VIEW BIN DETAILS — merged with fleet status
                          _sectionLabel("Bin Fleet Overview"),
                          _buildViewBinDetailsSection(),

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
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "SYSTEM ANALYTICS",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
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
          color: Colors.white.withValues(
            alpha: 0.9,
          ), // Slight transparency for background blend
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
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
          double level = BinData.fillLevel(sortedBins[index].value);
          Color color = level >= 80 ? alertRed : leafGreen;

          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 15, bottom: 5),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
                        backgroundColor: color.withValues(alpha: 0.1),
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
          );
        },
      ),
    );
  }

  // --- NEW: DEDICATED "VIEW BIN DETAILS" SECTION ---
  Widget _buildViewBinDetailsSection() {
    var bins = binData.entries.toList();

    if (bins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            "No bins registered yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: leafGreen.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  "${bins.length} Bins Registered",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Text(
                  "TAP TO INSPECT",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Bin list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bins.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              String binId = bins[index].key;
              var data = bins[index].value;
              String area = BinData.area(data);
              double level = BinData.fillLevel(data);
              bool isCritical = level >= 80;
              Color statusColor = isCritical ? alertRed : leafGreen;

              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => BinDetailsPage(binId: binId),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Fill level badge
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "${level.toInt()}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Area name, Bin ID & Gas level
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF1B2D1B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${binId.toUpperCase()} • Gas: ${BinData.gasLevel(data)} ppm",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status chips + arrow
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Online/Offline status
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BinData.isOnline(data)
                                  ? leafGreen.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: BinData.isOnline(data)
                                        ? leafGreen
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${BinData.connectionStatus(data).toUpperCase()} (${BinData.lastSeenAgo(data)})",
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: BinData.isOnline(data)
                                        ? leafGreen
                                        : Colors.grey,
                                  ),
                                ),

                              ],
                            ),
                          ),
                          // Critical/Stable status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isCritical ? "CRITICAL" : "STABLE",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

  Widget _sectionLabelWithSubtitle(String t, String s) => Padding(
    padding: const EdgeInsets.only(bottom: 15, top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            s,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

