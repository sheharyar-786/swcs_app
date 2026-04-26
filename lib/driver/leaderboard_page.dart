import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
              _buildSliverAppBar(context, drivers),
              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 20, 15, 80),
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

  Widget _buildSliverAppBar(BuildContext context, List drivers) {
    return SliverAppBar(
      expandedHeight: 180.0,
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
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            _buildTopPodiumOverlay(drivers),
          ],
        ),
      ),
    );
  }

  // --- TOP 3 PODIUM DESIGN ---
  Widget _buildTopPodiumOverlay(List drivers) {
    if (drivers.isEmpty) return const SizedBox.shrink();

    var first = drivers.isNotEmpty ? drivers[0].value : null;
    var second = drivers.length > 1 ? drivers[1].value : null;
    var third = drivers.length > 2 ? drivers[2].value : null;

    return Padding(
      padding: const EdgeInsets.only(top: 80, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _podiumItem(
              _getDisplayName(second),
              "2",
              Colors.grey.shade300,
              second['points'] ?? 0,
              75,
            ),

          // 1st Place
          if (first != null)
            _podiumItem(
              _getDisplayName(first),
              "1",
              Colors.amberAccent,
              first['points'] ?? 0,
              95,
            ),

          // 3rd Place
          if (third != null)
            _podiumItem(
              _getDisplayName(third),
              "3",
              Colors.orangeAccent.shade100,
              third['points'] ?? 0,
              70,
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
          width: 95,
          height: boxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                backgroundColor: color,
                radius: rank == "1" ? 32 : 26,
                child: Text(
                  rank,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // FIX: FittedBox prevents text from pushing borders out
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "$pts pts",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
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
        side: BorderSide(color: Colors.green.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 45,
          alignment: Alignment.center,
          child: Text(
            "#$rank",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          "Vehicle ID: $vehicle",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "$pts XP",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.orange,
              fontSize: 14,
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
