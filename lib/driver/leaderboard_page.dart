import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

const Color leafGreen = Color(0xFF0A714E);

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          Map data = snapshot.data!.snapshot.value as Map;
          List<MapEntry> drivers = data.entries.toList();

          // Sorting drivers by points (descending)
          drivers.sort(
            (a, b) =>
                (b.value['points'] ?? 0).compareTo(a.value['points'] ?? 0),
          );

          if (drivers.isEmpty) return _emptyState();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),
              
              // 2. PREMIUM PODIUM SECTION (Now below header)
              SliverToBoxAdapter(
                child: _buildTopPodiumSection(drivers),
              ),

              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 80),
                    itemCount: drivers.length > 3 ? drivers.length - 3 : 0,
                    itemBuilder: (context, index) {
                      int actualIndex = index + 3;
                      var driver = drivers[actualIndex].value;
                      int rank = actualIndex + 1;
                      String displayName = _getDisplayName(driver);

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildRankCard(
                              displayName,
                              rank,
                              driver['points'] ?? 0,
                              driver['vehicleId'] ?? "N/A",
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "SWCS LEADERBOARD",
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
              child: Image.asset(
                'lib/assets/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOP 3 PODIUM DESIGN ---
  Widget _buildTopPodiumSection(List drivers) {
    if (drivers.isEmpty) return const SizedBox.shrink();

    var first = drivers.isNotEmpty ? drivers[0].value : null;
    var second = drivers.length > 1 ? drivers[1].value : null;
    var third = drivers.length > 2 ? drivers[2].value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _podiumItem(
              _getDisplayName(second),
              "2",
              const Color(0xFFC0C0C0), // Silver
              second['points'] ?? 0,
              120,
            ),

          // 1st Place
          if (first != null)
            _podiumItem(
              _getDisplayName(first),
              "1",
              const Color(0xFFFFD700), // Gold
              first['points'] ?? 0,
              150,
            ),

          // 3rd Place
          if (third != null)
            _podiumItem(
              _getDisplayName(third),
              "3",
              const Color(0xFFCD7F32), // Bronze
              third['points'] ?? 0,
              110,
            ),
        ],
      ),
    );
  }

  Widget _podiumItem(
    String name,
    String rank,
    Color color,
    int pts,
    double boxHeight,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: boxHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: leafGreen.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                radius: rank == "1" ? 30 : 22,
                child: Text(
                  rank == "1" ? "👑" : rank,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: rank == "1" ? 24 : 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$pts XP",
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard(String name, int rank, int pts, String vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: leafGreen.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 45,
          alignment: Alignment.center,
          child: Text(
            "#$rank",
            style: const TextStyle(
              color: leafGreen,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Text(
          "Vehicle ID: $vehicle",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: leafGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$pts XP",
            style: const TextStyle(
              color: leafGreen,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayName(dynamic driver) {
    String name = driver['name'] ?? "";
    if (name.isEmpty) {
      String email = driver['email'] ?? "Driver";
      return email.split('@')[0].toUpperCase();
    }
    return name;
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 15),
          Text(
            "No rankings available yet.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
