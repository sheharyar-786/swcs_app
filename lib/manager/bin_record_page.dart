import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'bin_utils.dart';

class BinRecordPage extends StatefulWidget {
  final String binId;
  final String area;
  const BinRecordPage({super.key, required this.binId, required this.area});

  @override
  State<BinRecordPage> createState() => _BinRecordPageState();
}

class _BinRecordPageState extends State<BinRecordPage>
    with SingleTickerProviderStateMixin {
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color alertRed = Color(0xFFD32F2F);
  static const Color premiumNavy = Color(0xFF0D47A1);
  static const Color deepForest = Color(0xFF1B5E20);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: StreamBuilder(
        // Read global history node (existing Firebase structure)
        stream: FirebaseDatabase.instance.ref('history').onValue,
        builder: (context, historySnap) {
          return StreamBuilder(
            stream: FirebaseDatabase.instance
                .ref('bins/${widget.binId}')
                .onValue,
            builder: (context, binSnap) {
              Map<String, dynamic> binData = {};
              if (binSnap.hasData && binSnap.data!.snapshot.value != null) {
                binData = Map<String, dynamic>.from(
                    binSnap.data!.snapshot.value as Map);
              }

              // Filter history records for THIS bin only
              List<Map<String, dynamic>> records = [];
              if (historySnap.hasData &&
                  historySnap.data!.snapshot.value != null) {
                Map<String, dynamic> allHistory = Map<String, dynamic>.from(
                    historySnap.data!.snapshot.value as Map);

                allHistory.forEach((key, value) {
                  final entry = Map<String, dynamic>.from(value as Map);
                  // Match bin_id to current bin (normalize to lowercase)
                  if (entry['bin_id']?.toString().toLowerCase() ==
                      widget.binId.toLowerCase()) {
                    records.add(entry..['_key'] = key);
                  }
                });

                // Sort newest first using 'cleaned_at' timestamp
                records.sort((a, b) =>
                    (b['cleaned_at'] ?? 0).compareTo(a['cleaned_at'] ?? 0));
              }

              // Computed stats
              int totalCleanings = records.length;
              int todayCleanings = binData['fill_count_today'] ?? 0;
              String lastCleanedBy = records.isNotEmpty
                  ? (records.first['collected_by'] ?? 'N/A')
                  : (binData['last_cleaned_by'] ?? 'N/A');
              double currentFill = BinData.fillLevel(binData);

              // Avg fill level at time of collection (using 'fill_before')
              double avgFillAtCollection = 0;
              if (records.isNotEmpty) {
                double sum = records.fold(
                    0.0,
                    (prev, r) =>
                        prev + (r['fill_before'] ?? 0).toDouble());
                avgFillAtCollection = sum / records.length;
              }

              return Column(
                children: [
                  _buildHeader(context),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(
                          totalCleanings: totalCleanings,
                          todayCleanings: todayCleanings,
                          lastCleanedBy: lastCleanedBy,
                          currentFill: currentFill,
                          avgFillAtCollection: avgFillAtCollection,
                          monthlyStats: _computeMonthlyStats(records),
                          binData: binData,
                        ),
                        _buildHistoryTab(records),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Compute monthly stats from existing records
  Map<String, dynamic> _computeMonthlyStats(
      List<Map<String, dynamic>> records) {
    Map<String, List<double>> monthFills = {};

    for (var r in records) {
      final ts = r['cleaned_at'];
      if (ts == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(ts as int);
      final key = "${dt.year}-${dt.month.toString().padLeft(2, '0')}";
      monthFills.putIfAbsent(key, () => []);
      monthFills[key]!.add((r['fill_before'] ?? 0).toDouble());
    }

    Map<String, dynamic> result = {};
    monthFills.forEach((month, fills) {
      double avg = fills.reduce((a, b) => a + b) / fills.length;
      result[month] = {
        'avg_fill_level': avg,
        'total_cleanings': fills.length,
        'avg_daily_cleanings': fills.length / 30.0,
      };
    });
    return result;
  }


  // ─── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(35)),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child:
                  Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(35)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            top: 45,
            left: 15,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text(
                "BIN PERFORMANCE RECORD",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.binId.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                widget.area,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TAB BAR ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: leafGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "History"),
        ],
      ),
    );
  }

  // ─── TAB 1: OVERVIEW ─────────────────────────────────────────────────────
  Widget _buildOverviewTab({
    required int totalCleanings,
    required int todayCleanings,
    required String lastCleanedBy,
    required double currentFill,
    required double avgFillAtCollection,
    required Map<String, dynamic> monthlyStats,
    required Map<String, dynamic> binData,
  }) {
    final battery = BinData.battery(binData);
    final gasLevel = BinData.gasLevel(binData);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary Cards Row ──
          Row(
            children: [
              _statMini(
                "Today's Cleans",
                "$todayCleanings",
                Icons.today_rounded,
                premiumNavy,
              ),
              const SizedBox(width: 12),
              _statMini(
                "Total Cleanings",
                "$totalCleanings",
                Icons.cleaning_services_rounded,
                leafGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statMini(
                "Avg Fill at Collection",
                avgFillAtCollection > 0
                    ? "${avgFillAtCollection.toStringAsFixed(1)}%"
                    : "N/A",
                Icons.bar_chart_rounded,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _statMini(
                "Current Fill",
                "${currentFill.toInt()}%",
                Icons.sensors,
                currentFill >= 80 ? alertRed : leafGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Last Cleaned By Card ──
          _infoCard(
            icon: Icons.person_pin_rounded,
            color: Colors.teal,
            title: "Last Cleaned By",
            value: lastCleanedBy,
            subtitle:
                "Last full recorded: ${binData['last_full_time'] ?? 'No data'}",
          ),

          const SizedBox(height: 12),

          _infoCard(
            icon: BinData.isOnline(binData)
                ? Icons.sensors
                : Icons.sensors_off_rounded,
            color: BinData.isOnline(binData) ? Colors.green : Colors.grey,
            title: "Hardware Status",
            value: "Battery: ${battery != null ? '$battery%' : 'N/A'}",
            subtitle:
                "Gas: $gasLevel ppm • ${BinData.connectionStatus(binData)}",
          ),

          const SizedBox(height: 20),

          // ── Monthly Stats ──
          if (monthlyStats.isNotEmpty) ...[
            const _SectionLabel("Monthly Breakdown"),
            const SizedBox(height: 10),
            ...monthlyStats.entries.map((e) {
              String month = e.key;
              Map data = Map.from(e.value as Map);
              return _monthCard(
                month: month,
                avgFill: (data['avg_fill_level'] ?? 0).toDouble(),
                totalCleans: data['total_cleanings'] ?? 0,
                avgDaily: (data['avg_daily_cleanings'] ?? 0).toDouble(),
              );
            }),
          ] else
            _emptyMonthly(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── TAB 2: HISTORY ──────────────────────────────────────────────────────
  Widget _buildHistoryTab(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "No cleaning history yet.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              "Records appear after each collection.",
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        // Use 'cleaned_at' (existing Firebase field)
        final ts = r['cleaned_at'];
        String formattedDate = "Unknown date";
        if (ts != null) {
          try {
            formattedDate = DateFormat('dd MMM yyyy • hh:mm a')
                .format(DateTime.fromMillisecondsSinceEpoch(ts as int));
          } catch (_) {}
        }
        // Use 'fill_before' (existing Firebase field)
        double fillAtCollection =
            (r['fill_before'] ?? 0).toDouble();
        bool wasCritical = fillAtCollection >= 80;
        // Use 'collected_by' (existing Firebase field)
        String cleanedBy = r['collected_by'] ?? "Unknown";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Index badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: wasCritical
                      ? alertRed.withValues(alpha: 0.1)
                      : leafGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${records.length - index}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: wasCritical ? alertRed : leafGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          cleanedBy,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Fill level chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: wasCritical
                      ? alertRed.withValues(alpha: 0.1)
                      : leafGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${fillAtCollection.toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: wasCritical ? alertRed : leafGreen,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Widget _statMini(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
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
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF1B2D1B))),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthCard({
    required String month,
    required double avgFill,
    required int totalCleans,
    required double avgDaily,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatMonthKey(month),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _monthStat("Avg Fill", "${avgFill.toStringAsFixed(1)}%"),
              _monthStat("Total Cleanings", "$totalCleans"),
              _monthStat(
                  "Avg/Day", avgDaily.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthStat(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 9)),
      ],
    );
  }

  Widget _emptyMonthly() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.insert_chart_outlined_rounded,
              color: Colors.grey, size: 28),
          SizedBox(width: 12),
          Text(
            "Monthly stats will appear\nas data accumulates.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatMonthKey(String key) {
    // key format: "2026-04"
    try {
      final dt = DateFormat('yyyy-MM').parse(key);
      return DateFormat('MMMM yyyy').format(dt).toUpperCase();
    } catch (_) {
      return key;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B5E20),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
