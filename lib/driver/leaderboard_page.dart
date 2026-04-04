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
      ),
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
          drivers.sort(
            (a, b) =>
                (b.value['points'] ?? 0).compareTo(a.value['points'] ?? 0),
          );

          if (drivers.isEmpty) return _emptyState();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildTopPodium(drivers), // Top 3 Drivers Stylish Podium
                    // Neeche wali list ko limit karne ke liye aur overflow se bachne ke liye
                    AnimationLimiter(
                      child: ListView.builder(
                        shrinkWrap:
                            true, // Zaroori hai kyunke ye ScrollView ke andar hai
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
          );
        },
      ),
    );
  }

  // --- TOP 3 PODIUM DESIGN ---
  Widget _buildTopPodium(List drivers) {
    if (drivers.isEmpty) return const SizedBox.shrink();

    var first = drivers.length > 0 ? drivers[0].value : null;
    var second = drivers.length > 1 ? drivers[1].value : null;
    var third = drivers.length > 2 ? drivers[2].value : null;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SizedBox(
        height: 200, // Podium ki height fix kar di taake overlap na ho
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (second != null)
              Positioned(
                left: 0,
                bottom: 0,
                child: _podiumItem(
                  _getDisplayName(second),
                  "2",
                  Colors.grey.shade400,
                  second['points'] ?? 0,
                  110,
                ),
              ),
            if (third != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: _podiumItem(
                  _getDisplayName(third),
                  "3",
                  Colors.orangeAccent.shade200,
                  third['points'] ?? 0,
                  100,
                ),
              ),
            if (first != null)
              Positioned(
                bottom: 0,
                child: _podiumItem(
                  _getDisplayName(first),
                  "1",
                  Colors.amberAccent,
                  first['points'] ?? 0,
                  150,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(
    String name,
    String rank,
    Color color,
    int pts,
    double height,
  ) {
    return Container(
      width: 95,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: height > 140 ? 30 : 25,
            child: Text(
              rank,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "${pts} XP",
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRankCard(String name, int rank, int pts, String vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Text(
          "#$rank",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B5E20),
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Vehicle: $vehicle",
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "${pts} XP",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.orange,
              fontSize: 15,
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
      child: Text(
        "No drivers registered in SWCS system.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
