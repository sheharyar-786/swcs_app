import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Add to pubspec.yaml
import 'package:latlong2/latlong.dart'; // Add to pubspec.yaml
import 'package:firebase_database/firebase_database.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _sadiqabad = LatLng(28.3000, 70.1300);

  // Markers List
  List<Marker> _markers = [];

  // Subscriptions
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
  }

  void _startLiveTracking() {
    // Pure database ko listen karna taake bins aur drivers dono update hon
    _dataSubscription = FirebaseDatabase.instance.ref().onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map allData = event.snapshot.value as Map;
        _processMarkers(allData);
      }
    });
  }

  void _processMarkers(Map data) {
    List<Marker> newMarkers = [];

    // 1. Process Bins with 3-Level Fill & Gas Alert
    if (data['bins'] != null) {
      Map bins = data['bins'];
      bins.forEach((key, val) {
        int fill = val['fill_level'] ?? 0;
        bool gasAlert =
            (val['gas_level'] ?? 0) > 400; // Threshold for Gas Sensor

        newMarkers.add(
          Marker(
            point: LatLng(val['lat'], val['lng']),
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showDetails(key, fill, val['gas_level'] ?? 0),
              child: Column(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    size: 35,
                    // 3 Levels + Gas Special Color
                    color: gasAlert
                        ? Colors
                              .purple // Special Color for Gas/Hazard
                        : (fill >= 90
                              ? Colors.red
                              : (fill >= 50 ? Colors.orange : Colors.green)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      "$fill%",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }

    // 2. Process Drivers
    if (data['driver_locations'] != null) {
      Map drivers = data['driver_locations'];
      drivers.forEach((key, val) {
        newMarkers.add(
          Marker(
            point: LatLng(val['lat'], val['lng']),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.blue,
              size: 35,
            ),
          ),
        );
      });
    }

    if (mounted) setState(() => _markers = newMarkers);
  }

  void _showDetails(String id, int fill, int gas) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Bin $id: Fill $fill% | Gas $gas ppm"),
        backgroundColor: gas > 400 ? Colors.purple : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SWCS Live OSM Tracking"),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(initialCenter: _sadiqabad, initialZoom: 14.0),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.swcs_app',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: () => _mapController.move(_sadiqabad, 14.0),
      ),
    );
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
