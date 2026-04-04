import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _myLiveLocation = const LatLng(28.3067, 70.1411);

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  StreamSubscription? _dbSubscription;
  StreamSubscription? _gpsSubscription;

  int _criticalCount = 0;
  bool _isEmergencyActive = false;
  LatLng? _emergencyTargetLocation;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _enableLiveTracking();
  }

  void _enableLiveTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 1. Live GPS Stream & Firebase Update
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((Position pos) {
          if (mounted) {
            LatLng currentPos = LatLng(pos.latitude, pos.longitude);
            setState(() => _myLiveLocation = currentPos);

            // Admin ko apni location bhejein
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              FirebaseDatabase.instance
                  .ref('verified_drivers/${user.uid}')
                  .update({
                    'lat': pos.latitude,
                    'lng': pos.longitude,
                    'last_seen': ServerValue.timestamp,
                  });
            }
            _refreshMapData();
          }
        });

    // 2. Real-time Database Listener
    _dbSubscription = FirebaseDatabase.instance.ref().onValue.listen((event) {
      _refreshMapData();
    });
  }

  Future<void> _refreshMapData() async {
    final snapshot = await FirebaseDatabase.instance.ref().get();
    if (snapshot.value == null) return;

    Map data = snapshot.value as Map;
    Map bins = data['bins'] ?? {};
    final user = FirebaseAuth.instance.currentUser;

    // Check if any emergency is assigned to THIS driver
    String? assignedEmergencyBinId;
    bins.forEach((id, val) {
      if (val['assigned_to'] == user?.uid &&
          ((val['fill_level'] ?? 0) >= 90 || (val['gas_level'] ?? 0) > 450)) {
        assignedEmergencyBinId = id;
      }
    });

    List<Marker> newMarkers = [];
    List<Map<String, dynamic>> highPriorityBins = [];
    int critCount = 0;

    // Driver Marker
    newMarkers.add(
      Marker(
        point: _myLiveLocation,
        width: 60,
        height: 60,
        child: _buildLiveUserMarker(),
      ),
    );

    bins.forEach((id, val) {
      if (val['lat'] != null && val['lng'] != null) {
        LatLng binPos = LatLng(
          double.parse(val['lat'].toString()),
          double.parse(val['lng'].toString()),
        );
        int fill = val['fill_level'] ?? 0;
        int gas = val['gas_level'] ?? 0;

        bool isThisEmergency = (id == assignedEmergencyBinId);
        if (gas > 400 || fill >= 80) critCount++;

        if (fill > 0) {
          // Only show non-empty bins for routing
          highPriorityBins.add({
            'pos': binPos,
            'priority': (gas > 400) ? 1000 + gas : fill,
            'isEmergency': isThisEmergency,
          });
        }

        newMarkers.add(
          Marker(
            point: binPos,
            width: 80,
            height: 80,
            child: isThisEmergency
                ? _buildEmergencyMarker(fill, gas)
                : _buildSmartBinMarker(fill, gas, val['area'] ?? "Sector"),
          ),
        );
      }
    });

    // --- ACO & EMERGENCY ROUTING LOGIC ---
    highPriorityBins.sort((a, b) => b['priority'].compareTo(a['priority']));

    List<Polyline> newPolylines = [];
    List<LatLng> routinePoints = [_myLiveLocation];
    List<LatLng> emergencyPoints = [_myLiveLocation];

    if (assignedEmergencyBinId != null) {
      _isEmergencyActive = true;
      var eBin = highPriorityBins.firstWhere(
        (element) => element['isEmergency'] == true,
      );
      emergencyPoints.add(eBin['pos']);
      _emergencyTargetLocation = eBin['pos'];

      // Dull Routine Path
      for (var bin in highPriorityBins) {
        if (!bin['isEmergency']) routinePoints.add(bin['pos']);
      }

      newPolylines.add(
        Polyline(
          points: routinePoints,
          strokeWidth: 3.0,
          color: Colors.grey.withOpacity(0.3),
        ),
      );
      newPolylines.add(
        Polyline(points: emergencyPoints, strokeWidth: 7.0, color: Colors.red),
      );
    } else {
      _isEmergencyActive = false;
      _emergencyTargetLocation = null;
      for (var bin in highPriorityBins) {
        routinePoints.add(bin['pos']);
      }
      newPolylines.add(
        Polyline(
          points: routinePoints,
          strokeWidth: 5.0,
          color: Colors.blueAccent,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _criticalCount = critCount;
        _polylines = newPolylines;
      });
    }
  }

  Widget _buildEmergencyMarker(int fill, int gas) {
    return FadeTransition(
      opacity: _pulseController,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "EMERGENCY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 45),
        ],
      ),
    );
  }

  Widget _buildSmartBinMarker(int fill, int gas, String area) {
    Color col = (gas > 400)
        ? Colors.purple
        : (fill >= 80
              ? Colors.red
              : (fill >= 50 ? Colors.orange : Colors.green));
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            gas > 400 ? "GAS!" : "$fill%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(Icons.location_on, color: col, size: 35),
      ],
    );
  }

  Widget _buildLiveUserMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _pulseController,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Icon(Icons.navigation_rounded, color: Colors.blue, size: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLiveLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.shary.swcs',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),
          _buildEmergencyOverlay(),
          _buildMapControls(),
        ],
      ),
    );
  }

  Widget _buildEmergencyOverlay() {
    if (!_isEmergencyActive) return _buildNormalOverlay();
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.yellowAccent, size: 30),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EMERGENCY ASSIGNED",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    "Route optimized for critical pickup.",
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  _mapController.move(_emergencyTargetLocation!, 17),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                "VIEW",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              "CRITICAL BINS: $_criticalCount",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            const Text(
              "ACO ACTIVE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: Column(
        children: [
          FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () => _mapController.move(_myLiveLocation, 17),
            child: const Icon(Icons.my_location, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gpsSubscription?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}
