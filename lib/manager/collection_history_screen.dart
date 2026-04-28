import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'bin_utils.dart';
import '../widgets/universal_header.dart';

class CollectionHistoryPage extends StatelessWidget {
  const CollectionHistoryPage({super.key});

  // Theme Constants
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);
  static const Color premiumNavy = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('history').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: leafGreen));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return CustomScrollView(
              slivers: [
                UniversalHeader(
                  title: "Collection Logs",
                  showBackButton: true,
                ),
                SliverToBoxAdapter(child: _buildEmptyState()),
              ],
            );
          }

          Map data = snapshot.data!.snapshot.value as Map;
          List<MapEntry> historyList = data.entries.toList();

          // Sort by timestamp (cleaned_at) descending
          historyList.sort((a, b) {
            var timeA = (a.value as Map)['cleaned_at'] ?? 0;
            var timeB = (b.value as Map)['cleaned_at'] ?? 0;
            return timeB.compareTo(timeA);
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              UniversalHeader(
                title: "Collection Logs",
                showBackButton: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var logData = historyList[index].value;
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildTimelineCard(context, logData),
                        ),
                      ),
                    );
                  }, childCount: historyList.length),
                ),
              ),
            ],
          );
        },
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
                          BinData.area(data),
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
                    (data['collected_by'] ?? "System Auto").toString(),
                  ),
                   _logRow(
                    Icons.access_time_rounded,
                    "Time",
                    (data['time'] ?? "Recently").toString(),
                  ),
                   _logRow(
                    Icons.location_on_outlined,
                    "Area",
                    BinData.area(data),
                  ),
                  _logRow(
                    Icons.analytics_outlined,
                    "Sensor Confirmation",
                    "Cleaned at ${data['fill_before'] ?? 0}% Fill",
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
