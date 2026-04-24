import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          "SWCS LEADERBOARD",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://images.unsplash.com/photo-1554774853-719586f82d77?q=80&w=1000',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.85),
              BlendMode.lighten,
            ),
          ),
        ),
        child: StreamBuilder(
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

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildTopPodium(drivers),
                  const SizedBox(height: 10),
                  AnimationLimiter(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
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
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- TOP 3 PODIUM DESIGN (FIXED OVERFLOW) ---
  Widget _buildTopPodium(List drivers) {
    if (drivers.isEmpty) return const SizedBox.shrink();

    var first = drivers.isNotEmpty ? drivers[0].value : null;
    var second = drivers.length > 1 ? drivers[1].value : null;
    var third = drivers.length > 2 ? drivers[2].value : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(45),
          bottomRight: Radius.circular(45),
        ),
      ),
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
              130,
            ),

          // 1st Place
          if (first != null)
            _podiumItem(
              _getDisplayName(first),
              "1",
              Colors.amberAccent,
              first['points'] ?? 0,
              170,
            ),

          // 3rd Place
          if (third != null)
            _podiumItem(
              _getDisplayName(third),
              "3",
              Colors.orangeAccent.shade100,
              third['points'] ?? 0,
              125, // FIXED: Increased height to prevent 4.0 pixel overflow
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
              SizedBox(
                height: 20,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Text(
                "$pts XP",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
