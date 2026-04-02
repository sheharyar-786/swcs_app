import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();

  // Rahim Yar Khan/Sadiqabad default, but updates instantly with GPS
  LatLng _myLiveLocation = const LatLng(28.4212, 70.2989);

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  StreamSubscription? _dbSubscription;
  StreamSubscription? _gpsSubscription;

  @override
  void initState() {
    super.initState();
    _enableLiveTracking();
  }

  void _enableLiveTracking() async {
    // 1. Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 2. Continuous GPS Stream
    _gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2, // 2 meters movement par update
          ),
        ).listen((Position pos) {
          if (mounted) {
            setState(() {
              _myLiveLocation = LatLng(pos.latitude, pos.longitude);
            });
            // Real-time camera follow
            _mapController.move(_myLiveLocation, _mapController.camera.zoom);
            _refreshMapData();
          }
        });

    // 3. Firebase Listener
    _dbSubscription = FirebaseDatabase.instance.ref().onValue.listen((event) {
      _refreshMapData();
    });
  }

  Future<void> _refreshMapData() async {
    final snapshot = await FirebaseDatabase.instance.ref().get();
    if (snapshot.value == null) return;

    Map data = snapshot.value as Map;
    List<Marker> newMarkers = [];
    LatLng? targetBin;
    double highestFill = -1;

    // Aapki Apni Location Marker
    newMarkers.add(
      Marker(
        point: _myLiveLocation,
        width: 50,
        height: 50,
        child: const Icon(Icons.navigation, color: Colors.blue, size: 40),
      ),
    );

    // Bins Processing
    if (data['bins'] != null) {
      Map bins = data['bins'];
      bins.forEach((id, val) {
        // Data safety check
        if (val['lat'] != null && val['lng'] != null) {
          LatLng binPos = LatLng(
            double.parse(val['lat'].toString()),
            double.parse(val['lng'].toString()),
          );
          int fill = val['fill_level'] ?? 0;
          int gas = val['gas_level'] ?? 0;

          if (fill > highestFill && fill >= 50) {
            highestFill = fill.toDouble();
            targetBin = binPos;
          }

          newMarkers.add(
            Marker(
              point: binPos,
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    color: gas > 400
                        ? Colors.purple
                        : (fill >= 80
                              ? Colors.red
                              : (fill >= 50 ? Colors.orange : Colors.green)),
                    size: 35,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    color: Colors.white.withOpacity(0.7),
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
          );
        }
      });
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = targetBin != null
            ? [
                Polyline(
                  points: [_myLiveLocation, targetBin!],
                  strokeWidth: 5,
                  color: Colors.blueAccent.withOpacity(0.6),
                ),
              ]
            : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SWCS Live Tracking"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
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
                // Updated User Agent to avoid 403 error
                userAgentPackageName: 'com.shary.swcs_iot.v1',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),
          // --- Floating Location Button ---
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF4CAF50),
              onPressed: () {
                _mapController.move(_myLiveLocation, 17.0);
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }
}
