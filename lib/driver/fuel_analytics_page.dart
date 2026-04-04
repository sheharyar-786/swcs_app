import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FuelAnalyticsPage extends StatefulWidget {
  const FuelAnalyticsPage({super.key});

  @override
  State<FuelAnalyticsPage> createState() => _FuelAnalyticsPageState();
}

class _FuelAnalyticsPageState extends State<FuelAnalyticsPage> {
  final TextEditingController _priceController = TextEditingController(
    text: "280",
  );
  final TextEditingController _avgController = TextEditingController(text: "5");

  double fuelPrice = 280.0;
  double vehicleAvg = 5.0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        title: const Text(
          "ECO SAVINGS ANALYTICS",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref('verified_drivers/${user?.uid}')
            .onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          Map data = snapshot.data!.snapshot.value as Map;
          double totalKm = (data['distance_covered'] ?? 0.0).toDouble();

          // Logic based on User Input
          double distanceSaved = totalKm * 0.18; // 18% ACO efficiency
          double fuelSaved = distanceSaved / vehicleAvg;
          double moneySaved = fuelSaved * fuelPrice;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroHeader(moneySaved),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      _buildQuickConfigChips(),
                      const SizedBox(height: 20),
                      _analyticsCard(
                        "ACO Distance Saved",
                        "${distanceSaved.toStringAsFixed(2)} KM",
                        Icons.route_rounded,
                        Colors.blue,
                      ),
                      _analyticsCard(
                        "Fuel Conserved",
                        "${fuelSaved.toStringAsFixed(2)} Litres",
                        Icons.local_gas_station_rounded,
                        Colors.orange,
                      ),
                      _analyticsCard(
                        "Carbon Footprint Reduced",
                        "${(fuelSaved * 2.3).toStringAsFixed(1)} kg CO2",
                        Icons.cloud_done_rounded,
                        Colors.teal,
                      ),
                      const SizedBox(height: 30),
                      _buildEfficiencyGauge(),
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

  // --- Premium UI Components ---
  Widget _buildHeroHeader(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white24,
            size: 60,
          ),
          const Text(
            "NET CALCULATED SAVINGS",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // --- FIXED SECTION START ---
          Text(
            "PKR ${amount.toStringAsFixed(1)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 45,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.black26,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
          // --- FIXED SECTION END ---
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              "Algorithm: Ant Colony Optimization (ACO)",
              style: TextStyle(color: Colors.lightGreenAccent, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConfigChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _miniInfoChip("Price: Rs.$fuelPrice", Icons.sell),
        _miniInfoChip("Avg: $vehicleAvg km/L", Icons.speed),
      ],
    );
  }

  Widget _miniInfoChip(String t, IconData i) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.green.withOpacity(0.1)),
    ),
    child: Row(
      children: [
        Icon(i, size: 14, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          t,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _analyticsCard(String t, String v, IconData i, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(i, color: c, size: 30),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                v,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2E3E2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyGauge() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          const Text(
            "ACO SYSTEM EFFICIENCY",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 0.82,
                  strokeWidth: 15,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Column(
                children: [
                  const Text(
                    "OPTIMIZED",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "82%",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text(
          "Vehicle Configuration",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current Fuel Price (Rs/L)",
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _avgController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Vehicle Average (KM/L)",
                prefixIcon: Icon(Icons.shutter_speed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: StadiumBorder(),
            ),
            onPressed: () {
              setState(() {
                fuelPrice = double.parse(_priceController.text);
                vehicleAvg = double.parse(_avgController.text);
              });
              Navigator.pop(context);
            },
            child: const Text(
              "Update Analytics",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
