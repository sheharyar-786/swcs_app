import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:confetti/confetti.dart';
import 'package:geolocator/geolocator.dart';

// Your existing imports
import '../auth/login_screen.dart';
import '../manager/live_map_screen.dart';
import 'assign_duties_page.dart';
import 'leaderboard_page.dart';
import 'fuel_analytics_page.dart';
import 'collection_history_page.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

  String driverName = "Commander";
  int driverPoints = 0;
  String attendanceStatus = "Inactive";
  int dutyCount = 0;

  final List<String> _liveMessages = [
    "🚀 Dashboard Active: Waiting for system updates...",
    "🚛 Keep Sadiqabad Clean & Green!",
  ];

  late ConfettiController _confettiController;
  late ScrollController _announcementController;

  // LOGIC FIX: Stream declared here to keep data persistent across page jumps
  late Stream<DatabaseEvent> _globalStream;

  Timer? _marqueeTimer;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _announcementController = ScrollController();

    // INITIALIZE GLOBAL STREAM ONCE
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();

    _initDriverEngine();
    _startAnnouncementAnimation();
    _startBackgroundLocationUpdates();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _announcementController.dispose();
    _marqueeTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  // --- LOGIC: Background GPS Updates (15s Interval) ---
  void _startBackgroundLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) _msg("Please enable GPS/Location services.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await FirebaseDatabase.instance
            .ref('verified_drivers/${user.uid}')
            .update({
              'lat': position.latitude,
              'lng': position.longitude,
              'last_seen': ServerValue.timestamp,
            });
      } catch (e) {
        debugPrint("Location Update Sync Error: $e");
      }
    });
  }

  void _startAnnouncementAnimation() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_announcementController.hasClients) {
        double maxExtent = _announcementController.position.maxScrollExtent;
        double currentOffset = _announcementController.offset;
        if (currentOffset >= maxExtent) {
          _announcementController.jumpTo(0);
        } else {
          _announcementController.animateTo(
            currentOffset + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  void _initDriverEngine() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Real-time listener for Driver Profile
    FirebaseDatabase.instance
        .ref('verified_drivers/${user.uid}')
        .onValue
        .listen((event) {
          if (event.snapshot.exists && mounted) {
            Map data = event.snapshot.value as Map;
            setState(() {
              driverName =
                  data['name'] ??
                  user.email?.split('@')[0].toUpperCase() ??
                  "Driver";
              driverPoints = data['points'] ?? 0;
              attendanceStatus = data['attendance'] ?? "Inactive";
            });
            if (data['last_rating_received'] == 5.0) {
              _confettiController.play();
              FirebaseDatabase.instance
                  .ref('verified_drivers/${user.uid}')
                  .update({'last_rating_received': 0});
            }
          }
        });

    // Real-time task counter sync
    FirebaseDatabase.instance.ref('bins').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        Map bins = event.snapshot.value as Map;
        int activeTasks = bins.entries
            .where(
              (e) =>
                  e.value['assigned_to'] == user.uid &&
                  (e.value['fill_level'] ?? 0) > 0,
            )
            .length;
        setState(() => dutyCount = activeTasks);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: Stack(
        children: [
          StreamBuilder(
            stream:
                _globalStream, // Using initialized stream to prevent vanishing data
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: leafGreen),
                );
              }

              final data = snapshot.data?.snapshot.value as Map? ?? {};
              Map bins = data['bins'] ?? {};
              final user = FirebaseAuth.instance.currentUser;

              // Filter bins specifically for this driver's current mission list
              var myRouteBins = bins.entries
                  .where(
                    (e) =>
                        e.value['assigned_to'] == user?.uid &&
                        (e.value['fill_level'] ?? 0) > 0,
                  )
                  .toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildModernHeader(),
                  SliverToBoxAdapter(child: _buildMarqueeBar()),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatsRow(),
                        const SizedBox(height: 25),
                        _sectionLabel("LIVE BIN PLACEMENTS", "📍"),
                        _buildMap(bins),
                        const SizedBox(height: 25),
                        _sectionLabel("MISSION CONTROL GRID", "🎮"),
                        _buildFeatureGrid(context),
                        const SizedBox(height: 25),
                        _sectionLabel("ON-ROUTE PRIORITY (ACO)", "🚛"),
                        _buildTaskListView(myRouteBins),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
          // Success Feedback Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.yellow, Colors.blue],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildModernHeader() => SliverAppBar(
    expandedHeight: 220,
    pinned: true,
    backgroundColor: leafGreen,
    elevation: 0,
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12, top: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 4,
                backgroundColor: attendanceStatus == "Present"
                    ? Colors.lightGreenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Text(
                attendanceStatus.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        onPressed: _logout,
      ),
    ],
    flexibleSpace: FlexibleSpaceBar(
      titlePadding: const EdgeInsets.only(left: 20, bottom: 25),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello, $driverName",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const Text(
            "Let's the mission begin! 🚛✨",
            style: TextStyle(
              fontSize: 8,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=1000',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  deepForest.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildMarqueeBar() => Container(
    height: 38,
    color: Colors.orange.withValues(alpha: 0.1),
    child: SingleChildScrollView(
      controller: _announcementController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 400),
          Text(
            _liveMessages.reversed.join("    |    "),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 400),
        ],
      ),
    ),
  );

  Widget _buildStatsRow() {
    String rank = "#0${(driverPoints ~/ 500) + 1}";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("Rank", rank, Colors.blue),
        _statItem("My Points", "$driverPoints", Colors.orange),
        _statItem("Tasks Left", "$dutyCount", Colors.purple),
      ],
    );
  }

  Widget _statItem(String l, String v, Color c) => Container(
    width: 105,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: c.withValues(alpha: 0.06),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 18),
        ),
        const SizedBox(height: 5),
        Text(
          l,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );

  Widget _buildMap(Map bins) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(28.3067, 70.1411),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // FIXED: User Agent added to prevent "Access Blocked" policy error
              userAgentPackageName: 'com.shary.swcs.driver_pro_fleet',
            ),
            MarkerLayer(
              markers: bins.entries.map((e) {
                var d = e.value;
                int fill = d['fill_level'] ?? 0;
                int gas = d['gas_level'] ?? 0;
                Color col = gas > 400
                    ? Colors.purple
                    : (fill >= 80
                          ? Colors.red
                          : (fill >= 50 ? Colors.orange : leafGreen));
                return Marker(
                  point: LatLng(
                    double.tryParse(d['lat'].toString()) ?? 28.3067,
                    double.tryParse(d['lng'].toString()) ?? 70.1411,
                  ),
                  width: 50,
                  height: 50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          gas > 400 ? "GAS!" : "$fill%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.location_on, color: col, size: 25),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 15,
    mainAxisSpacing: 15,
    childAspectRatio: 1.4,
    children: [
      _gridTile(
        "Assign Duties",
        Icons.assignment_turned_in_rounded,
        Colors.blue,
        badge: dutyCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AssignDutiesPage()),
        ),
      ),
      _gridTile(
        "Shortest Path",
        Icons.alt_route_rounded,
        Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const LiveMapScreen()),
        ),
      ),
      _gridTile(
        "LEADERBOARD",
        Icons.emoji_events_rounded,
        Colors.amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const LeaderboardPage()),
        ),
      ),
      _gridTile(
        "Fuel Analytics",
        Icons.analytics_rounded,
        Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const FuelAnalyticsPage()),
        ),
      ),
      _gridTile(
        "Attendance",
        Icons.how_to_reg_rounded,
        Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const DriverAttendancePage()),
        ),
      ),
      _gridTile(
        "History Logs",
        Icons.history_edu_rounded,
        Colors.indigo,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const CollectionHistoryPage()),
        ),
      ),
    ],
  );

  Widget _gridTile(
    String t,
    IconData i,
    Color c, {
    int badge = 0,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: c.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(i, color: c, size: 30),
              const SizedBox(height: 8),
              Text(
                t,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: c,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (badge > 0)
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.red,
                child: Text(
                  "$badge",
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildTaskListView(List myBins) {
    if (myBins.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            "No urgent missions. You're efficient! ✨",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myBins.length,
      itemBuilder: (context, index) {
        var bin = myBins[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
            ],
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: softMint,
              child: Icon(Icons.delete_sweep_rounded, color: leafGreen),
            ),
            // FIXED: Added Expanded title and ellipsis to prevent Right Overflow error
            title: Text(
              bin.value['area'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "Level: ${bin.value['fill_level']}% | Gas: ${bin.value['gas_level']}",
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.grey,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AssignDutiesPage()),
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => const AuthPage()),
    );
  }
  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
  );
  Widget _sectionLabel(String t, String e) => Padding(
    padding: const EdgeInsets.only(bottom: 15, top: 10),
    child: Row(
      children: [
        Text(e, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: deepForest,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}

// Attendance Logic Integrated (Saves space in folder structure)
class DriverAttendancePage extends StatefulWidget {
  const DriverAttendancePage({super.key});
  @override
  State<DriverAttendancePage> createState() => _DriverAttendancePageState();
}

class _DriverAttendancePageState extends State<DriverAttendancePage> {
  final TextEditingController _reasonController = TextEditingController();
  Future<void> _updateStatus(String status) async {
    final nav = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseDatabase.instance
          .ref('verified_drivers/${user.uid}')
          .update({
            'attendance': status,
            'leave_reason': status == "On Leave" ? _reasonController.text : "",
            'attendance_time': ServerValue.timestamp,
          });
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Hub"),
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              "Status for Today",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _btn("MARK PRESENT", Colors.green, () => _updateStatus("Present")),
            const SizedBox(height: 35),
            const Divider(),
            const Text(
              "Request Leave",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: "Why do you need leave?",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _btn(
              "SUBMIT LEAVE",
              Colors.orange,
              () => _updateStatus("On Leave"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String t, Color c, VoidCallback tap) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: tap,
      child: Text(
        t,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
