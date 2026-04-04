import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final Color leafGreen = const Color(0xFF4CAF50);
  final Color deepForest = const Color(0xFF1B5E20);

  // --- Sadiqabad Precise Grid (Logic) ---
  final List<Map<String, dynamic>> sadiqabadGrid = [
    {
      "id": "bin_01",
      "area": "Model Town Block A",
      "lat": 28.3067,
      "lng": 70.1411,
    },
    {
      "id": "bin_02",
      "area": "Main Bazar Sadiqabad",
      "lat": 28.3082,
      "lng": 70.1430,
    },
    {"id": "bin_03", "area": "Hospital Road", "lat": 28.3055, "lng": 70.1398},
    {"id": "bin_04", "area": "Railway Road", "lat": 28.3031, "lng": 70.1402},
    {
      "id": "bin_05",
      "area": "Gulshan Iqbal Park",
      "lat": 28.3110,
      "lng": 70.1425,
    },
    {"id": "bin_06", "area": "Siddique Chowk", "lat": 28.3075, "lng": 70.1455},
    {
      "id": "bin_07",
      "area": "Degree College Road",
      "lat": 28.3099,
      "lng": 70.1375,
    },
    {"id": "bin_08", "area": "Fawara Chowk", "lat": 28.3040, "lng": 70.1448},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          "TEST SIMULATOR",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: leafGreen,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('bins').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: leafGreen));
          }

          Map bins = (snapshot.data?.snapshot.value as Map?) ?? {};

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: sadiqabadGrid.length,
              itemBuilder: (context, index) {
                var config = sadiqabadGrid[index];
                var bData =
                    bins[config['id']] ?? {'fill_level': 0, 'gas_level': 0};

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildControlCard(config, bData),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlCard(Map config, Map data) {
    int fill = int.tryParse(data['fill_level'].toString()) ?? 0;
    int gas = int.tryParse(data['gas_level'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("🎮", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config['area'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "ID: ${config['id']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // --- FILL LEVEL SLIDER ---
          _sliderRow(
            label: "Fill Level: $fill%",
            value: fill.toDouble(),
            max: 100,
            activeColor: leafGreen,
            onChanged: (v) => _updateFirebase(config, 'fill_level', v.toInt()),
          ),

          const SizedBox(height: 10),

          // --- GAS LEVEL SLIDER ---
          _sliderRow(
            label: "Gas Level: $gas ppm",
            value: gas.toDouble(),
            max: 1000,
            activeColor: Colors.orange,
            onChanged: (v) => _updateFirebase(config, 'gas_level', v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double max,
    required Color activeColor,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            activeColor: activeColor,
            inactiveColor: activeColor.withOpacity(0.1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // --- Logic: Backend Sync ---
  void _updateFirebase(Map loc, String field, int val) {
    FirebaseDatabase.instance.ref('bins/${loc['id']}').update({
      field: val,
      'lat': loc['lat'],
      'lng': loc['lng'],
      'area': loc['area'],
      'last_update': ServerValue.timestamp,
    });

    // Smart Alert Trigger
    if (field == 'fill_level' && val > 90) {
      FirebaseDatabase.instance
          .ref('latest_activity')
          .set("🚨 SIMULATION: ${loc['area']} is now critical!");
    }
  }
}
