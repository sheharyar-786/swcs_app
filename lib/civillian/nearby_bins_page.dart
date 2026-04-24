import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class NearbyBinsPage extends StatefulWidget {
  const NearbyBinsPage({super.key});

  @override
  State<NearbyBinsPage> createState() => _NearbyBinsPageState();
}

class _NearbyBinsPageState extends State<NearbyBinsPage> {
  String binSearchQuery = "";
  final Color leafGreen = const Color(0xFF4CAF50);
  final Color deepForest = const Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          "AREA BIN EXPLORER",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: leafGreen,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- PREMIUM SEARCH BAR ---
          _buildSearchHeader(),

          Expanded(
            child: StreamBuilder(
              // Direct Firebase Stream taake Sensors ka data Live nazar aaye
              stream: FirebaseDatabase.instance.ref('bins').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: leafGreen),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return _buildNoDataState("No bins connected to the system.");
                }

                Map bins = snapshot.data!.snapshot.value as Map;

                // Filtering Logic based on Area Name
                var filteredList = bins.entries.where((e) {
                  String area = (e.value['area'] ?? "")
                      .toString()
                      .toLowerCase();
                  return area.contains(binSearchQuery.toLowerCase());
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildNoDataState(
                    "No bins found in '$binSearchQuery'",
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      var bin = filteredList[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSensorCard(
                              binId: bin.key,
                              area: bin.value['area'] ?? "Unknown",
                              fill:
                                  int.tryParse(
                                    bin.value['fill_level'].toString(),
                                  ) ??
                                  0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: BoxDecoration(
        color: leafGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: TextField(
        onChanged: (v) => setState(() => binSearchQuery = v),
        decoration: InputDecoration(
          hintText: "Enter your area name...",
          prefixIcon: Icon(Icons.location_on_rounded, color: leafGreen),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String binId,
    required String area,
    required int fill,
  }) {
    Color statusColor = fill > 80
        ? Colors.red
        : (fill > 50 ? Colors.orange : leafGreen);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: deepForest,
                    ),
                  ),
                  Text(
                    "Sensor ID: $binId",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  fill >= 100 ? "FULL" : "$fill%",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          // --- LIVE SENSOR PROGRESS BAR ---
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 12,
                width:
                    (MediaQuery.of(context).size.width - 80) *
                    (fill / 100).clamp(0, 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withValues(alpha: 0.6), statusColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Current Waste Level",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (fill > 80)
                const Text(
                  "⚠ Critical: Request Pickup",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors_off_rounded,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
