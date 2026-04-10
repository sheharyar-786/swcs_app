import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// Your existing imports
import 'analytics_screen.dart';
import 'schedule_list_screen.dart';
import 'driver_approval_screen.dart';
import 'live_map_screen.dart';
import 'simulation_screen.dart';
import 'bin_details.dart';
import 'drivers_status_screen.dart';
import 'collection_history_screen.dart'; // Added this import
import '../auth/login_screen.dart';
import '../widgets/summary_card.dart';

// GLOBAL CONSTANTS FOR COLOR UNIFORMITY
const Color leafGreen = Color(0xFF4CAF50);
const Color deepForest = Color(0xFF1B5E20);
const Color softMint = Color(0xFFE8F5E9);
const Color alertRed = Color(0xFFE53935);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Stream<DatabaseEvent> _globalStream;
  final ScrollController _scrollController = ScrollController();

  // ADDED: Scaffold key to control the drawer from a custom button
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
  }

  // --- LOGIC: Distance Calculation ---
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

  // --- LOGIC: Driver Assignment Sheet ---
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
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );
          Map driversData = snapshot.data!.snapshot.value as Map? ?? {};

          var activeDrivers = driversData.entries
              .where((d) => d.value['attendance'] == 'Present')
              .map((d) {
                double dLat =
                    double.tryParse(d.value['lat']?.toString() ?? "0.0") ?? 0.0;
                double dLng =
                    double.tryParse(d.value['lng']?.toString() ?? "0.0") ?? 0.0;
                return {
                  'uid': d.key,
                  'name': d.value['name'] ?? "Driver",
                  'distance': _calculateDistance(binLat, binLng, dLat, dLng),
                };
              })
              .toList();

          activeDrivers.sort(
            (a, b) =>
                (a['distance'] as double).compareTo(b['distance'] as double),
          );

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
                                  ? Colors.blue.withOpacity(0.1)
                                  : softMint.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isNearest
                                      ? Colors.blue
                                      : leafGreen,
                                  child: const Icon(
                                    Icons.delivery_dining,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  driver['name'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "${driver['distance'].toStringAsFixed(2)} km away",
                                ),
                                trailing: const Icon(
                                  Icons.send_rounded,
                                  color: leafGreen,
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
    Navigator.pop(context);
    _msg("Duty Assigned to $name Successfully!", leafGreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Link key for drawer control
      backgroundColor: Colors.white,
      // --- ADDED: DRAWER FOR SIMULATION ACCESS ---
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [deepForest, leafGreen]),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 50,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "SYSTEM MENU",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_remote, color: leafGreen),
              title: const Text("IoT Simulation"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SimulationScreen()),
                );
              },
            ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: alertRed),
              title: const Text("Logout"),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: _globalStream,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );
          }

          final snapshotValue = snapshot.data?.snapshot.value as Map? ?? {};
          Map bins = snapshotValue['bins'] as Map? ?? {};
          Map reports = snapshotValue['citizen_reports'] as Map? ?? {};
          Map pending = snapshotValue['pending_drivers'] as Map? ?? {};
          Map verifiedDrivers = snapshotValue['verified_drivers'] as Map? ?? {};

          var unassignedCritical = bins.entries.where((e) {
            double level = (e.value['fill_level'] ?? 0).toDouble();
            String status = e.value['status'] ?? "";
            return level >= 75 && status != 'Assigned' && status != 'On Route';
          }).toList();

          String activityMsg =
              snapshotValue['latest_activity']?.toString() ??
              "System Monitoring... 🟢";

          return Column(
            children: [
              if (unassignedCritical.isNotEmpty)
                _buildTopNotificationBar(unassignedCritical.length),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildCompactHeader(activityMsg),
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          // SOFT FADED BACKGROUND IMAGE BEHIND GRID
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.08,
                              child: Image.network(
                                'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=1000',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 600),
                                childAnimationBuilder: (widget) =>
                                    FadeInAnimation(
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: widget,
                                      ),
                                    ),
                                children: [
                                  _buildSummarySection(bins, reports),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softMint.withOpacity(0.92),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(40),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 25),
                                        // UPDATED 6-GRID MENU
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopNotificationBar(int count) {
    return Container(
      width: double.infinity,
      color: alertRed,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              "CRITICAL ALERT: $count Bins require immediate assignment!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(String msg) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      elevation: 0,
      backgroundColor: leafGreen,
      // OPEN DRAWER BUTTON
      leading: IconButton(
        icon: const Icon(
          Icons.menu_open_rounded,
          color: Colors.white,
          size: 28,
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 22, color: Colors.white),
          onPressed: () => _handleLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "ADMIN HUB",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=1000',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    leafGreen.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.radar_rounded,
                      color: Colors.blue,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: deepForest,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
        .where((b) => (b['fill_level'] ?? 0) >= 80)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      height: 160,
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
            child: InkWell(
              onTap: () => _scrollController.animateTo(
                500,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              ),
              child: SummaryCard(
                index: 1,
                title: "Critical",
                value: critical.toString(),
                icon: Icons.error_outline,
                iconColor: alertRed,
              ),
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

  // UPDATED: CORE 6 GRID MENU
  Widget _build6GridMenu(int pCount, Map drivers, Map bins) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: 1.3,
    children: [
      _gridItem("City Map", "📍", Colors.blue, const LiveMapScreen()),
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
      // COMBINED COLLECTION HISTORY GRID
      _gridItem(
        "History",
        "📂",
        Colors.indigo,
        CollectionHistoryPage(bins: bins),
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
                    color: c.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.5)),
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
                      color: c.withOpacity(0.8),
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
      double level = (e.value['fill_level'] ?? 0).toDouble();
      String status = e.value['status'] ?? "";
      return level >= 75 && status != "Assigned" && status != "On Route";
    }).toList();

    if (list.isEmpty)
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

    return Column(
      children: list.map((e) {
        double bLat =
            double.tryParse(e.value['lat']?.toString() ?? "0.0") ?? 0.0;
        double bLng =
            double.tryParse(e.value['lng']?.toString() ?? "0.0") ?? 0.0;
        return AnimationConfiguration.staggeredList(
          position: list.indexOf(e),
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            horizontalOffset: 50,
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => BinDetailsPage(binId: e.key),
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
                  e.value['area'] ?? "Sector",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "Level: ${e.value['fill_level']}% • Action Needed",
                  style: const TextStyle(
                    fontSize: 11,
                    color: alertRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepForest,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () =>
                      _openAssignmentSheet(e.key, e.value['area'], bLat, bLng),
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

  void _handleLogout(context) => Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (c) => const AuthPage()),
    (r) => false,
  );
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

// --- SUB PAGES (Citizen Inbox & Photo Logic kept as provided) ---

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
        elevation: 0,
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
                          r['user'] ?? "Guest",
                        ),
                        _reportInfo(
                          Icons.phone,
                          "Contact: ",
                          r['phone'] ?? "N/A",
                        ),
                        _reportInfo(
                          Icons.location_on,
                          "Area: ",
                          r['area'] ?? "N/A",
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
                            onPressed: () {
                              FirebaseDatabase.instance
                                  .ref('citizen_reports/$key')
                                  .remove();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Case Resolved!")),
                              );
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
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

// NOTE: CollectionStatusPage is kept here for reference but the Dashboard now uses CollectionHistoryPage which you have in a separate file.
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
                      bin['area'] ?? "Area",
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
