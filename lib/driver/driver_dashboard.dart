import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:confetti/confetti.dart';
import 'package:geolocator/geolocator.dart';
import '../manager/bin_utils.dart';
import '../widgets/universal_header.dart';

// Your existing imports
import '../auth/login_screen.dart';
import '../manager/live_map_screen.dart';
import 'assign_duties_page.dart';
import 'leaderboard_page.dart';
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
  String? profilePic;
  String attendanceStatus = "Inactive";
  int dutyCount = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _liveMessages = [
    "Dashboard Active: Waiting for system updates...",
    "Keep Sadiqabad Clean & Green!",
  ];

  late ConfettiController _confettiController;
  late ScrollController _announcementController;

  // LOGIC FIX: Stream declared here to keep data persistent across page jumps
  late Stream<DatabaseEvent> _globalStream;

  Timer? _marqueeTimer;
  Timer? _locationTimer;
  StreamSubscription? _warningSubscription;
  List<Map> _warningHistory = [];

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
    _listenForWarnings();
  }

  void _listenForWarnings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _warningSubscription = FirebaseDatabase.instance
        .ref('verified_drivers/${user.uid}/warnings')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final Map data = event.snapshot.value as Map;
        List<Map> tempHistory = [];
        data.forEach((key, value) {
          tempHistory.add(Map.from(value));
        });
        
        // Sort by timestamp
        tempHistory.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

        // Detect if a NEW warning was added (if length increased)
        if (tempHistory.length > _warningHistory.length && _warningHistory.isNotEmpty) {
          _showWarningAlert(tempHistory.first['message'] ?? "New Warning Received!");
        }

        setState(() => _warningHistory = tempHistory);
      }
    });
  }

  void _showWarningAlert(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "VIEW",
          textColor: Colors.white,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _announcementController.dispose();
    _marqueeTimer?.cancel();
    _locationTimer?.cancel();
    _warningSubscription?.cancel();
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
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
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
              profilePic = data['profile_pic'];
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

    final db = FirebaseDatabase.instance.ref();
    // --- NEW: Leave Approval & General Notification Listener ---
    db.child('driver_notifications/${user.uid}').onChildAdded.listen((event) {
      if (event.snapshot.exists && mounted) {
        var data = event.snapshot.value as Map;
        // Only notify for fresh notifications (status: Unread)
        if (data['status'] == 'Unread') {
          NotificationService.showNotification(
            data['title'] ?? "New Update",
            data['message'] ?? "You have a new message from management."
          );
          // Mark as Read so we don't notify again on app restart
          db.child('driver_notifications/${user.uid}/${event.snapshot.key}').update({
            'status': 'Read'
          });
        }
      }
    });

    // Real-time task counter sync & Emergency Alert Logic
    FirebaseDatabase.instance.ref('bins').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        Map bins = event.snapshot.value as Map;
        int activeTasks = 0;
        bool hasNewEmergency = false;
        String emergencyArea = "";

        bins.forEach((id, val) {
          if (val['assigned_to'] == user.uid) {
            double fill = BinData.fillLevel(val);
            int gas = BinData.gasLevel(val);
            
            if (fill > 0) activeTasks++;

            // CHECK FOR EMERGENCY (90% fill or 450+ gas)
            if (fill >= 90 || gas >= 450) {
              hasNewEmergency = true;
              emergencyArea = BinData.area(val);
            }
          }
        });

        setState(() => dutyCount = activeTasks);

        // TRIGGER LOUD ALERT IF EMERGENCY DETECTED
        if (hasNewEmergency) {
          NotificationService.showNotification(
            "🚨 EMERGENCY ASSIGNMENT",
            "Urgent pickup required at $emergencyArea! Check your mission list immediately."
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDriverDrawer(),
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
              Map driversMap = data['verified_drivers'] ?? {};
              final user = FirebaseAuth.instance.currentUser;

              // --- REAL-TIME RANK CALCULATION ---
              int realRank = 0;
              if (user != null && driversMap.isNotEmpty) {
                List<MapEntry> sorted = driversMap.entries.toList();
                sorted.sort((a, b) => (b.value['points'] ?? 0).compareTo(a.value['points'] ?? 0));
                int index = sorted.indexWhere((e) => e.key == user.uid);
                realRank = index != -1 ? index + 1 : 0;
              }

              // Filter bins specifically for this driver's current mission list
              var myRouteBins = bins.entries
                  .where(
                    (e) =>
                        e.value['assigned_to'] == user?.uid &&
                        BinData.fillLevel(e.value) > 0,
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
                        _buildStatsRow(realRank),
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

  Widget _buildModernHeader() => UniversalHeader(
    title: "DRIVER DASHBOARD",
    showMenuButton: true,
    onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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

  Widget _buildStatsRow(int rankValue) {
    String rankStr = rankValue > 0 ? "#$rankValue" : "--";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem("Rank", rankStr, Colors.blue),
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
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
                int fill = BinData.fillLevel(d).toInt();
                int gas = BinData.gasLevel(d);
                Color col = gas > 400
                    ? Colors.purple
                    : (fill >= 80
                          ? Colors.red
                          : (fill >= 50 ? Colors.orange : leafGreen));
                return Marker(
                  point: LatLng(BinData.lat(d), BinData.lng(d)),
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

  Widget _buildFeatureGrid(BuildContext context) => Column(
    children: [
      _gridTile(
        "Assign Duties",
        Icons.assignment_turned_in_rounded,
        Colors.blue,
        isFullWidth: true,
        badge: dutyCount,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AssignDutiesPage()),
        ),
      ),
      const SizedBox(height: 15),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.4,
        children: [
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
      ),
    ],
  );

  Widget _gridTile(
    String t,
    IconData i,
    Color c, {
    int badge = 0,
    bool isFullWidth = false,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      width: isFullWidth ? double.infinity : null,
      height: isFullWidth ? 100 : null,
      padding: isFullWidth ? const EdgeInsets.symmetric(horizontal: 25) : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: c.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isFullWidth)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(i, color: c, size: 35),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: c,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Check your active missions",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: c.withValues(alpha: 0.3),
                  size: 18,
                ),
              ],
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(i, color: c, size: 28),
                ),
                const SizedBox(height: 10),
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
              top: isFullWidth ? 20 : 12,
              right: isFullWidth ? 0 : 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$badge",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: softMint,
              child: Icon(Icons.delete_sweep_rounded, color: leafGreen),
            ),
            // FIXED: Added Expanded title and ellipsis to prevent Right Overflow error
            title: Text(
              BinData.area(bin.value),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: BinData.isOnline(bin.value)
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  BinData.isOnline(bin.value) ? "Online" : "Offline",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: BinData.isOnline(bin.value)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Level: ${BinData.fillLevel(bin.value).toInt()}% | Gas: ${BinData.gasLevel(bin.value)}",
                  style: const TextStyle(fontSize: 10),
                ),
              ],
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
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => const AuthPage()),
    );
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), behavior: SnackBarBehavior.floating),
  );
  // --- NEW: PREMIUM DRIVER DRAWER ---
  Widget _buildDriverDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. Header with Profile & Points
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [leafGreen, deepForest],
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: softMint,
                        backgroundImage: profilePic != null
                            ? (profilePic!.startsWith('data:image')
                                ? MemoryImage(base64Decode(profilePic!.split(',').last)) as ImageProvider
                                : NetworkImage(profilePic!))
                            : null,
                        child: profilePic == null
                            ? Text(driverName.substring(0, 1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: leafGreen))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.email ?? "driver@swcs.com",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "$driverPoints COLLECTOR POINTS",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: [
                _drawerItem(
                  icon: Icons.warning_amber_rounded,
                  title: "Warning Logs",
                  color: Colors.red,
                  badge: _warningHistory.length > 0 ? _warningHistory.length.toString() : null,
                  onTap: () => _showWarningLogs(),
                ),
                _drawerItem(
                  icon: Icons.alternate_email_rounded,
                  title: "Change Email",
                  color: Colors.blue,
                  onTap: () => _showChangeEmailDialog(),
                ),
                _drawerItem(
                  icon: Icons.security_rounded,
                  title: "Privacy & Security",
                  color: Colors.purple,
                  onTap: () => _msg("Security settings coming soon!"),
                ),
                _drawerItem(
                  icon: Icons.help_outline_rounded,
                  title: "Help & Support",
                  color: Colors.orange,
                  onTap: () => _msg("Support ticket system active."),
                ),
                const Divider(height: 40, indent: 20, endIndent: 20),
                _drawerItem(
                  icon: Icons.logout_rounded,
                  title: "Log Out",
                  color: Colors.red,
                  onTap: () => _showLogoutConfirm(),
                ),
              ],
            ),
          ),
          
          // 3. Footer
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "SWCS DRIVER PRO v2.4.0",
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required Color color, required VoidCallback onTap, String? badge}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  void _showWarningLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Official Warnings", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: _warningHistory.isEmpty
            ? const Text("No warnings received yet. Keep up the good work!", style: TextStyle(fontSize: 12, color: Colors.grey))
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _warningHistory.length,
                  itemBuilder: (context, index) {
                    final w = _warningHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w['message'] ?? "",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Type: ${w['type'] ?? 'GENERAL'}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final TextEditingController emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Change Email", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your new official email address below.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "New Email",
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: leafGreen, shape: const StadiumBorder()),
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(emailController.text);
                  Navigator.pop(context);
                  _msg("Verification email sent to ${emailController.text}!");
                } catch (e) {
                  _msg("Error: ${e.toString()}");
                }
              }
            },
            child: const Text("UPDATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to exit the driver dashboard?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("STAY", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: const StadiumBorder()),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
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
      backgroundColor: const Color(0xFFF4F7F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          UniversalHeader(
            title: "Attendance Hub",
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const Text(
                    "Status for Today",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _btn(
                    "MARK PRESENT",
                    Colors.green,
                    () => _updateStatus("Present"),
                  ),
                  const SizedBox(height: 35),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    "Request Leave",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: "Why do you need leave?",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.green,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
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
          ),
        ],
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
