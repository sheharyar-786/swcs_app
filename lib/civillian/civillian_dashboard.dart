import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // User name ke liye
import '../auth/login_screen.dart';

class CivillianPage extends StatefulWidget {
  const CivillianPage({super.key});

  @override
  State<CivillianPage> createState() => _CivillianPageState();
}

class _CivillianPageState extends State<CivillianPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);

  String userName = "Citizen"; // Default name

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- Logic: Fetch Logged-in User Name ---
  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}/name');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() => userName = snapshot.value.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🌿 Citizen Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          Map data = snapshot.data!.snapshot.value as Map;
          Map schedules = data['schedules'] ?? {};
          Map bins = data['bins'] ?? {};

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(userName),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _sectionHeader(
                        "Quick Report",
                        Icons.report_problem_outlined,
                      ),
                      _buildReportGrid(),
                      const SizedBox(height: 25),

                      _sectionHeader("Nearby Smart Bins", Icons.sensors),
                      _buildBinScroll(bins),
                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader(
                            "Area Schedules",
                            Icons.calendar_today,
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ScheduleExplorer(allData: data),
                              ),
                            ),
                            child: const Text(
                              "See More",
                              style: TextStyle(
                                color: leafGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildScheduleMiniGrid(schedules),
                      const SizedBox(height: 30),
                      _buildEmergencyCard(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // UI Widgets (Header, Report Grid, etc. as per previous design)
  Widget _buildHeader(String name) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    color: leafGreen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, $name!",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          "Ready to make Sadiqabad cleaner?",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String t, IconData i) => Row(
    children: [
      Icon(i, color: deepForest),
      const SizedBox(width: 10),
      Text(
        t,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: deepForest,
        ),
      ),
    ],
  );

  Widget _buildBinScroll(Map bins) => SizedBox(
    height: 150,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: bins.entries
          .map(
            (e) => Container(
              width: 200,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: softMint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    e.value['area'] ?? "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    "${e.value['fill_level']}% Full",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: leafGreen,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _buildScheduleMiniGrid(Map schedules) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
    ),
    itemCount: schedules.length > 4 ? 4 : schedules.length,
    itemBuilder: (context, index) {
      var s = schedules.values.toList()[index];
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: softMint),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              s['area'],
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              s['time'],
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildReportGrid() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 3,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.9,
    children: [
      _reportBtn("Overflow", Icons.delete_outline, Colors.orange),
      _reportBtn("Missed", Icons.moped, Colors.blue),
      _reportBtn("Damage", Icons.handyman, Colors.red),
    ],
  );

  Widget _reportBtn(String t, IconData i, Color c) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: c.withOpacity(0.2)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(i, color: c),
        Text(t, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );

  Widget _buildEmergencyCard() => Container(
    padding: const EdgeInsets.all(20),
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [deepForest, leafGreen]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Emergency Pickup",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text("Call: 1122", style: TextStyle(color: Colors.white70)),
      ],
    ),
  );

  void _logout(context) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (c) => const AuthPage()),
  );
}

// --- NEW PAGE: SCHEDULE EXPLORER WITH SEARCH & RATING ---
class ScheduleExplorer extends StatefulWidget {
  final Map allData;
  const ScheduleExplorer({super.key, required this.allData});

  @override
  State<ScheduleExplorer> createState() => _ScheduleExplorerState();
}

class _ScheduleExplorerState extends State<ScheduleExplorer> {
  String query = "";
  double rating = 0;

  @override
  Widget build(BuildContext context) {
    Map schedules = widget.allData['schedules'] ?? {};
    Map drivers = widget.allData['verified_drivers'] ?? {};
    var list = schedules.values
        .where(
          (s) =>
              s['area'].toString().toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Area Schedules"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search your area...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                var s = list[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFF4CAF50),
                    ),
                    title: Text(
                      s['area'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${s['day']} at ${s['time']}"),
                    children: [_buildDetails(s, drivers)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Map s, Map drivers) {
    String collector = s['collector'] ?? "Not Assigned";
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _detailRow(Icons.person, "Collector: $collector"),
          _detailRow(Icons.info_outline, "Status: Daily Pickup Active"),
          const SizedBox(height: 15),
          const Text(
            "Rate Collector Service:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.orange,
                ),
                onPressed: () => setState(() => rating = i + 1.0),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Rating Submitted!"))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              "Submit Feedback",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(i, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(t),
      ],
    ),
  );
}
