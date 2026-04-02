import 'package:flutter/material.dart';
import '../widgets/bin_card.dart';
import '../auth/login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  // --- Unified Eco-Friendly Theme ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color warningYellow = Color(0xFFFFD54F);
  static const Color dangerRed = Color(0xFFE53935);

  final double averageRating = 4.8;
  final int rankingPoints = 1250;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () => _showNewDutyAlert());
  }

  void _showNewDutyAlert() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Duty",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 25),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🚛 New Duty Assigned!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: leafGreen,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Admin Faizan has assigned a new optimized route for Sadiqabad.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: leafGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Start Route",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) =>
          ScaleTransition(scale: anim1, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🚛 Driver Mission Control",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAnimatedHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: softMint,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildRouteOptimizationBar(),
                    const SizedBox(height: 20),
                    _buildMapPreviewCard(), // Updated with Shortest Path Visuals
                    const SizedBox(height: 20),
                    _sectionTitle("Your Active Bin Route"),
                    const SizedBox(height: 10),
                    _buildBinList(), // Updated with "Collected" action
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: leafGreen,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Text("🚛", style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 10),
          const Text(
            " Jawad",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _headerStat("Rating", "$averageRating ⭐"),
              _headerStat("Points", "$rankingPoints 🏆"),
              _headerStat("Rank", "#04 🎖️"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRouteOptimizationBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: leafGreen.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_run, color: leafGreen),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Shortest Path Active",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: deepForest,
                  ),
                ),
                Text(
                  "Algorithm: ACO (Ant Colony Optimization)",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: softMint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "4.2 km",
              style: TextStyle(
                color: deepForest,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.map_rounded, color: leafGreen),
              SizedBox(width: 10),
              Text(
                "Route: Navigate to BIN-X01",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: deepForest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: AssetImage('assets/background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Visualizing the path
                Center(
                  child: Icon(
                    Icons.gesture,
                    color: leafGreen.withOpacity(0.5),
                    size: 100,
                  ),
                ),
                _mapPulse(
                  top: 20,
                  left: 40,
                  color: dangerRed,
                  label: "X01 (Full)",
                ),
                _mapPulse(top: 100, left: 180, color: leafGreen, label: "You"),
                // Navigation Arrow
                const Positioned(
                  bottom: 20,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: leafGreen,
                    child: Icon(Icons.navigation, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "ACO has prioritized BIN-X01 due to 95% fill level.",
            style: TextStyle(
              fontSize: 10,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPulse({
    required double top,
    required double left,
    required Color color,
    required String label,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: Column(
        children: [
          Icon(Icons.location_on, color: color, size: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinList() {
    return Column(
      children: [
        BinInfoCard(
          binId: "BIN-X01",
          fillLevel: 0.95,
          status: "CRITICAL",
          area: "Model Town - Block A",
          actionLabel: "Mark as Collected", // FEATURE: Action Button
          onActionPressed: () => _handleCollection("BIN-X01"),
        ),
        const SizedBox(height: 10),
        BinInfoCard(
          binId: "BIN-Y04",
          fillLevel: 0.65,
          status: "RISING",
          area: "Sadiqabad - Ghausia Chowk",
          actionLabel: "Mark as Collected",
          onActionPressed: () => _handleCollection("BIN-Y04"),
        ),
      ],
    );
  }

  void _handleCollection(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Confirm Collection? 🗑️"),
        content: Text(
          "Marking $id as clean will update Admin Faizan and notify Sheharyar.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: leafGreen),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "$id Status: CLEANED ✅. Syncing with Admin Hub...",
                  ),
                ),
              );
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        const Icon(Icons.route, color: deepForest),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: deepForest,
          ),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }
}
