import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

// Your existing imports
import 'analytics_screen.dart';
import 'schedule_list_screen.dart';
import 'driver_approval_screen.dart';
import 'live_map_screen.dart';
import 'simulation_screen.dart';
import 'bin_details.dart';
import 'drivers_status_screen.dart';
import 'collection_history_screen.dart';
import 'add_bin_page.dart';
import 'bin_utils.dart';
import '../auth/login_screen.dart';
import '../widgets/summary_card.dart';

// GLOBAL CONSTANTS FOR COLOR UNIFORMITY
const Color leafGreen = Color(0xFF0A714E); // Updated to your premium green
const Color deepForest = Color(0xFF1B5E20);
const Color softMint = Color(0xFFF1F8E9);
const Color alertRed = Color(0xFFE53935);

class AdminPage extends StatefulWidget {
  final bool scrollToUrgent;
  const AdminPage({super.key, this.scrollToUrgent = false});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late Stream<DatabaseEvent> _globalStream;
  static DatabaseEvent? _cachedEvent;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
    _globalStream.listen((event) {
      if (mounted) {
        setState(() {
          _cachedEvent = event;
        });
      } else {
        _cachedEvent = event;
      }
    });

    if (widget.scrollToUrgent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }

    _startBackgroundAlerts();
  }

  void _startBackgroundAlerts() {
    final db = FirebaseDatabase.instance.ref();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Monitor Pending Drivers for Approval
    db.child('pending_drivers').onChildAdded.listen((event) {
      if (event.snapshot.exists && mounted) {
        String name = (event.snapshot.value as Map)['name'] ?? "New Driver";
        NotificationService.showNotification(
          "New Driver Registration 👤",
          "$name is waiting for your approval."
        );
      }
    });

    // 2. Monitor Critical Bins (90%+ Fill or 450+ Gas)
    db.child('bins').onValue.listen((event) {
      if (event.snapshot.exists && mounted) {
        Map bins = (event.snapshot.value as Map?) ?? {};
        bins.forEach((id, val) {
          double fill = BinData.fillLevel(val);
          int gas = BinData.gasLevel(val);
          if (fill >= 90 || gas >= 450) {
            NotificationService.showNotification(
              "⚠️ Critical Bin Alert: $id",
              "Bin at ${BinData.area(val)} requires immediate attention ($fill% Fill)."
            );
          }
        });
      }
    });

    // 3. Monitor Admin Warnings
    db.child('users/${user.uid}/warnings').onChildAdded.listen((event) {
      if (event.snapshot.exists && mounted) {
        String msg = (event.snapshot.value as Map)['message'] ?? "You have a new message from Admin.";
        NotificationService.showNotification(
          "Admin Warning ❗",
          msg
        );
      }
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _openAssignmentSheet(
    String binId,
    String area,
    double binLat,
    double binLng,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) => StreamBuilder(
        stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );
          }
          Map driversData = snapshot.data!.snapshot.value as Map? ?? {};
          var activeDrivers = driversData.entries
              .map((d) {
                var val = d.value;
                double dLat = double.tryParse(val['lat']?.toString() ?? "0.0") ?? 0.0;
                double dLng = double.tryParse(val['lng']?.toString() ?? "0.0") ?? 0.0;
                double dist = _calculateDistance(binLat, binLng, dLat, dLng);
                
                return {
                  'uid': d.key,
                  'name': val['name'] ?? "Driver",
                  'distance': dist,
                  'hasLocation': dLat != 0.0 && dLng != 0.0,
                  'isPresent': val['attendance'] == 'Present',
                };
              })
              .toList();

          // Sorting by distance - Closest on TOP
          activeDrivers.sort((a, b) {
            // Drivers without location go to bottom
            if (!(a['hasLocation'] as bool) && (b['hasLocation'] as bool)) return 1;
            if ((a['hasLocation'] as bool) && !(b['hasLocation'] as bool)) return -1;
            return (a['distance'] as double).compareTo(b['distance'] as double);
          });

          return Container(
            padding: const EdgeInsets.all(25),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                _sectionTitle("Assign Nearest Driver", Icons.gps_fixed_rounded),
                const Divider(),
                Expanded(
                  child: activeDrivers.isEmpty
                      ? const Center(
                          child: Text(
                            "No active drivers on duty.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: activeDrivers.length,
                          itemBuilder: (context, index) {
                            var driver = activeDrivers[index];
                            bool isNearest = index == 0;
                            return Card(
                              elevation: 0,
                              color: isNearest
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : softMint.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isNearest
                                          ? Colors.blue
                                          : leafGreen,
                                      child: const Icon(
                                        Icons.local_shipping_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (driver['isPresent'] == true)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        driver['name'].toString(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isNearest && (driver['hasLocation'] as bool))
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          "NEAREST",
                                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),

                                subtitle: Text(
                                  driver['hasLocation'] == true
                                      ? "${(driver['distance'] as double).toStringAsFixed(2)} km away"
                                      : "Location unavailable",
                                ),
                                trailing: Icon(
                                  Icons.send_rounded,
                                  color: isNearest ? Colors.blue : leafGreen,
                                ),
                                onTap: () => _finalizeDuty(
                                  binId,
                                  driver['uid'].toString(),
                                  driver['name'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _finalizeDuty(String bId, String dUid, String name) async {
    await FirebaseDatabase.instance.ref('bins/$bId').update({
      'assigned_to': dUid,
      'status': 'Assigned',
    });
    await FirebaseDatabase.instance
        .ref('latest_activity')
        .set("Mission: $name assigned to Emergency Duty! 🚨");
    if (!mounted) return;
    Navigator.pop(context);
    _msg("Duty Assigned to $name Successfully!", leafGreen);
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    File file = File(image.path);
    String base64Image = base64Encode(file.readAsBytesSync());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseDatabase.instance.ref('users/${user.uid}').update({
        'profile_pic': "data:image/jpeg;base64,$base64Image",
      });
      _msg("Profile Picture Updated!", leafGreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _globalStream,
      initialData: _cachedEvent,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: leafGreen)),
          );
        }

        final snapshotValue = snapshot.data?.snapshot.value as Map? ?? {};
        Map bins = snapshotValue['bins'] as Map? ?? {};
        Map reports = snapshotValue['citizen_reports'] as Map? ?? {};
        Map pending = snapshotValue['pending_drivers'] as Map? ?? {};
        Map verifiedDrivers = snapshotValue['verified_drivers'] as Map? ?? {};

        String activityMsg =
            snapshotValue['latest_activity']?.toString() ??
            "System Monitoring Active";

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          // --- FIXED & ADDED: FLOATING ACTION BUTTONS ---
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: "addBinBtn",
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const AddBinPage()),
                ),
                backgroundColor: leafGreen,
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  "ADD BIN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(activityMsg, bins, verifiedDrivers, snapshotValue['users'] as Map? ?? {}),
          body: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildCompactHeader(activityMsg),
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.15,
                        child: Image.asset(
                          'lib/assets/bg.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder: (widget) => FadeInAnimation(
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: widget,
                            ),
                          ),
                          children: [
                            // --- FIXED: SUMMARY SECTION ---
                            _buildSummarySection(bins, reports),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: softMint.withValues(alpha: 0.92),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(40),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 25),
                                  _build6GridMenu(
                                    pending.length,
                                    verifiedDrivers,
                                    bins,
                                  ),
                                  _sectionTitle(
                                    "Urgent Duty Assignments",
                                    Icons.priority_high_rounded,
                                  ),
                                  _buildSmartCriticalList(bins),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(String msg, Map bins, Map drivers, Map users) {
    final user = FirebaseAuth.instance.currentUser;
    final userData = users[user?.uid] as Map? ?? {};
    final userName = userData['name']?.toString() ?? "System Manager";
    final profilePic = userData['profile_pic']?.toString();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. PREMIUM USER PROFILE HEADER
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [leafGreen, deepForest],
              ),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(50)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: softMint,
                      backgroundImage: profilePic != null
                          ? (profilePic.startsWith('data:image')
                              ? MemoryImage(base64Decode(profilePic.split(',').last)) as ImageProvider
                              : NetworkImage(profilePic))
                          : null,
                      child: profilePic == null
                          ? Text(
                              userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: leafGreen),
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: leafGreen, shape: BoxShape.circle),
                                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        user?.email ?? "manager@swcs.com",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "VERIFIED MANAGER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                // 2. SYSTEM INTELLIGENCE (THRESHOLDS)
                _drawerSectionLabel("SYSTEM THRESHOLDS"),
                _thresholdCard(
                  "Critical Capacity",
                  "80%",
                  Icons.speed_rounded,
                  alertRed,
                ),
                _thresholdCard(
                  "Gas Warning",
                  "400 ppm",
                  Icons.waves_rounded,
                  Colors.purple,
                ),
                _thresholdCard(
                  "Battery Alert",
                  "20%",
                  Icons.battery_alert_rounded,
                  Colors.orange,
                ),

                const SizedBox(height: 25),

                // 3. REAL-TIME ACTIVITY FEED
                _drawerSectionLabel("LIVE MISSION FEED"),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: softMint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: leafGreen.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 16,
                            color: leafGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _activityItem(
                        "New Report",
                        "Citizen reported overflow in Sector 4",
                        Colors.orange,
                      ),
                      _activityItem(
                        "Driver Online",
                        "Driver Shary is now on mission",
                        leafGreen,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                // --- NEW: ADMIN WARNINGS SECTION ---
                if (userData['warnings'] != null) ...[
                  _drawerSectionLabel("ADMIN WARNINGS"),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: (userData['warnings'] as Map).values.map((w) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  w['message'] ?? "Requirement not fulfilled",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // 4. CORE CONTROLS
                _drawerSectionLabel("SYSTEM TOOLS"),
                _drawerItem(
                  "IoT Simulation",
                  Icons.settings_remote_rounded,
                  leafGreen,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const SimulationScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),
                _drawerItem(
                  "Support & Help",
                  Icons.support_agent_rounded,
                  Colors.purple,
                  () {
                    Navigator.pop(context);
                    _showSupportDialog();
                  },
                ),
              ],
            ),
          ),

          // 5. FOOTER & LOGOUT
          const Divider(),
          ListTile(
            onTap: _handleLogout,
            leading: const Icon(
              Icons.logout_rounded,
              color: alertRed,
            ),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: alertRed,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- SUPPORT & HELP DIALOG ---
  void _showSupportDialog() {
    final TextEditingController _supportMsg = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.mark_as_unread_rounded, color: leafGreen),
            SizedBox(width: 10),
            Text(
              "Support Inbox",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Need technical assistance or want to report a system bug? Send a message to the High Command.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _supportMsg,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Describe your issue...",
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: leafGreen,
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              if (_supportMsg.text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;

              // 1. Save to Firebase (Real-time)
              await FirebaseDatabase.instance
                  .ref('support_messages')
                  .push()
                  .set({
                    'sender': user?.email ?? "Unknown Manager",
                    'message': _supportMsg.text,
                    'timestamp': ServerValue.timestamp,
                    'status': 'Pending',
                  });

              // 2. Prepare Email Link
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'swcsproviders@gmail.com',
                query:
                    'subject=SUPPORT REQUEST: ${user?.email}&body=${_supportMsg.text}',
              );

              if (await canLaunchUrl(emailLaunchUri)) {
                await launchUrl(emailLaunchUri);
              }

              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Support Request Dispatched!"),
                  backgroundColor: leafGreen,
                ),
              );
            },
            child: const Text(
              "SEND TO ADMIN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.grey.shade400,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _thresholdCard(String title, String val, IconData icon, Color col) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: col),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                val,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: col,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _activityItem(String title, String sub, Color col) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 25,
          decoration: BoxDecoration(
            color: col,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _drawerItem(
    String title,
    IconData icon,
    Color col,
    VoidCallback onTap,
  ) => ListTile(
    onTap: onTap,
    dense: true,
    leading: Icon(icon, color: col, size: 22),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios_rounded,
      size: 12,
      color: Colors.grey,
    ),
  );

  Widget _buildCompactHeader(String msg) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "Welcome back, Manager!",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.menu_open_rounded,
          color: Colors.black87,
          size: 28,
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Image.asset('lib/assets/bg.jpeg', fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map bins, Map reports) {
    int critical = bins.values
        .where((b) => b != null && BinData.fillLevel(b) >= 80)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      height: 160, // FIXED: Increased height to prevent 10px overflow
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              index: 0,
              title: "Bins",
              value: bins.length.toString(),
              icon: Icons.delete_outline,
              iconColor: leafGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SummaryCard(
              index: 1,
              title: "Critical",
              value: critical.toString(),
              icon: Icons.error_outline,
              iconColor: alertRed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => CitizenReportsPage(reports: reports),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  SummaryCard(
                    index: 2,
                    title: "Reports",
                    value: reports.length.toString(),
                    icon: Icons.chat_bubble_outline,
                    iconColor: Colors.orange,
                  ),
                  if (reports.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _badge(reports.length.toString()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build6GridMenu(int pCount, Map drivers, Map bins) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: 1.3,
    children: [
      _gridItem("City Map", "📍", Colors.blue, const LiveMapScreen(isReadOnly: true)),
      _gridItem("Analytics", "📊", Colors.purple, const AnalyticsPage()),
      _gridItem(
        "Schedule",
        "📅",
        Colors.orange,
        const ScheduleManagementPage(),
      ),
      _gridItem(
        "Approvals",
        "✅",
        leafGreen,
        const DriverApprovalScreen(),
        badge: pCount,
      ),
      _gridItem(
        "History",
        "📂",
        Colors.indigo,
        const CollectionHistoryPage(),
      ),
      _gridItem(
        "Drivers",
        "👤",
        Colors.brown,
        DriversStatusPage(drivers: drivers),
      ),
    ],
  );

  Widget _gridItem(String t, String e, Color c, Widget? p, {int badge = 0}) =>
      InkWell(
        onTap: p == null
            ? null
            : () =>
                  Navigator.push(context, MaterialPageRoute(builder: (c) => p)),
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: c.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(right: 15, top: 15, child: _badge(badge.toString())),
          ],
        ),
      );

  Widget _buildSmartCriticalList(Map bins) {
    var list = bins.entries.where((e) {
      if (e.value == null) return false;
      double level = BinData.fillLevel(e.value);
      String status = BinData.status(e.value);
      // Show bins above 75% or those that are Assigned/On Route but still critical
      return level >= 75;
    }).toList();
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            "All bins are under control. ✨",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: list.map((e) {
        double bLat = BinData.lat(e.value);
        double bLng = BinData.lng(e.value);
        String status = BinData.status(e.value);
        return AnimationConfiguration.staggeredList(
          position: list.indexOf(e),
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            horizontalOffset: 50,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => BinDetailsPage(
                      binId: e.key,
                      initialData: e.value as Map?,
                    ),
                  ),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: alertRed,
                    size: 20,
                  ),
                ),
                title: Text(
                  BinData.area(e.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: BinData.isOnline(e.value)
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      BinData.isOnline(e.value) ? "ONLINE" : "OFFLINE",
                      style: TextStyle(
                        fontSize: 9,
                        color: BinData.isOnline(e.value)
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Level: ${BinData.fillLevel(e.value).toInt()}%",
                      style: const TextStyle(
                        fontSize: 10,
                        color: alertRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: status == "Assigned" || status == "On Route"
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Tracking",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepForest,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _openAssignmentSheet(
                          e.key,
                          e.value['area'].toString(),
                          bLat,
                          bLng,
                        ),
                        child: const Text(
                          "Assign",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(String count) => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: alertRed,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(
      count,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (c) => const AuthPage()),
      (r) => false,
    );
  }

  void _msg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
  );

  Widget _sectionTitle(String t, IconData i) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
    child: Row(
      children: [
        Icon(i, color: leafGreen, size: 22),
        const SizedBox(width: 10),
        Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: deepForest,
          ),
        ),
      ],
    ),
  );
}

class CitizenReportsPage extends StatelessWidget {
  final Map reports;
  const CitizenReportsPage({super.key, required this.reports});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          "Citizen Inbox",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: reports.isEmpty
          ? const Center(child: Text("No Pending Complaints. ✨"))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                var r = reports.values.toList()[index];
                var key = reports.keys.toList()[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              r['type']?.toString().toUpperCase() ?? "ISSUE",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.mark_as_unread,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ],
                        ),
                        const Divider(height: 25),
                        _reportInfo(
                          Icons.person,
                          "Citizen: ",
                          r['user']?.toString() ?? "Guest",
                        ),
                        _reportInfo(
                          Icons.phone,
                          "Contact: ",
                          r['phone']?.toString() ?? "N/A",
                        ),
                        _reportInfo(
                          Icons.location_on,
                          "Area: ",
                          r['area']?.toString() ?? "N/A",
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            "\"${r['comment'] ?? 'No comment provided'}\"",
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(
                              Icons.done_all,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "RESOLVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              final db = FirebaseDatabase.instance.ref();
                              
                              // 1. Move to Resolved Node
                              await db.child('resolved_reports').child(key).set({
                                ...r,
                                'status': 'Resolved',
                                'resolved_at': ServerValue.timestamp,
                              });

                              // 2. Notify Citizen (if UID exists)
                              if (r['uid'] != null) {
                                await db.child('citizen_notifications/${r['uid']}').push().set({
                                  'title': 'Report Resolved ✅',
                                  'message': 'Your report regarding ${r['type']} at ${r['area']} has been resolved.',
                                  'timestamp': ServerValue.timestamp,
                                  'status': 'Unread',
                                });
                              }

                              // 3. Remove from Active
                              await db.child('citizen_reports/$key').remove();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Case Resolved & Citizen Notified!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _reportInfo(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class CollectionStatusPage extends StatelessWidget {
  final Map bins;
  const CollectionStatusPage({super.key, required this.bins});
  @override
  Widget build(BuildContext context) {
    var list = bins.entries.where((e) => e.value['fill_level'] == 0).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Collection Photos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: list.isEmpty
          ? const Center(child: Text("No recent collections recorded."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                var bin = list[index].value;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: softMint,
                      child: Icon(Icons.photo_library, color: leafGreen),
                    ),
                    title: Text(
                      bin['area']?.toString() ?? "Area",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "Verified Cleaned ✅",
                      style: TextStyle(
                        color: leafGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
