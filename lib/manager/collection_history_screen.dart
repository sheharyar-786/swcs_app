import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class CollectionHistoryPage extends StatelessWidget {
  final Map bins;
  const CollectionHistoryPage({super.key, required this.bins});

  // Theme Constants
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);
  static const Color premiumNavy = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    // LOGIC: Filter for bins that have a "last_cleaned_by" entry
    var historyList = bins.entries
        .where(
          (e) =>
              e.value['last_cleaned_by'] != null || e.value['fill_level'] == 0,
        )
        .toList();

    // Sort by most recent
    historyList = historyList.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            sliver: historyList.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      var data = historyList[index].value;
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildTimelineCard(context, data),
                          ),
                        ),
                      );
                    }, childCount: historyList.length),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 150.0,
      pinned: true,
      backgroundColor: leafGreen,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "COLLECTION LOGS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deepForest, leafGreen],
            ),
          ),
          child: const Opacity(
            opacity: 0.2,
            child: Icon(
              Icons.history_edu_rounded,
              size: 150,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context, dynamic data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIMELINE DECORATION
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: leafGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: leafGreen, width: 2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: leafGreen,
                  size: 16,
                ),
              ),
              Container(
                width: 2,
                height: 100,
                color: leafGreen.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(width: 15),

          // 2. DATA CARD
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: softMint),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // Added Expanded to prevent Overflow
                        child: Text(
                          (data['area'] ?? "Unknown Sector").toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _statusBadge("VERIFIED"),
                    ],
                  ),
                  const Divider(height: 25),
                  _logRow(
                    Icons.person_outline,
                    "Driver",
                    (data['last_cleaned_by'] ?? "System Auto").toString(),
                  ),
                  _logRow(
                    Icons.access_time_rounded,
                    "Time",
                    (data['last_cleaned_time'] ?? "Recently").toString(),
                  ),
                  _logRow(
                    Icons.analytics_outlined,
                    "Sensor Confirmation",
                    "Fill Level: ${data['fill_level']?.toString() ?? '0'}%", // Fixed type mismatch
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "IoT data suggests successful disposal at the designated facility.",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
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

  Widget _logRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Better for multi-line values
        children: [
          Icon(icon, size: 14, color: leafGreen),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: premiumNavy,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: leafGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: leafGreen,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildEmptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 100),
        Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
        SizedBox(height: 15),
        Text(
          "No collection logs found for today.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );
}
