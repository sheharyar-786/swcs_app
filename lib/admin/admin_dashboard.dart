import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'analytics_screen.dart';
import 'schedule_list_screen.dart';
import 'driver_approval_screen.dart';
import 'live_map_screen.dart';
import 'simulation_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/summary_card.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color alertRed = Color(0xFFE53935);

  late Stream<DatabaseEvent> _globalStream;

  @override
  void initState() {
    super.initState();
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
  }

  // --- LOGIC: Haversine Formula (Distance Calculation) ---
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

  // --- LOGIC: Nearest Driver Assignment Logic ---
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StreamBuilder(
        stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          Map driversData = snapshot.data!.snapshot.value as Map? ?? {};

          var activeDrivers = driversData.entries
              .where((d) => d.value['attendance'] == 'Present')
              .map((d) {
                double dLat = double.tryParse(d.value['lat'].toString()) ?? 0.0;
                double dLng = double.tryParse(d.value['lng'].toString()) ?? 0.0;
                return {
                  'uid': d.key,
                  'name': d.value['name'] ?? "Driver",
                  'points': d.value['points'] ?? 0,
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
                  child: ListView.builder(
                    itemCount: activeDrivers.length,
                    itemBuilder: (context, index) {
                      var driver = activeDrivers[index];
                      bool isNearest = index == 0;
                      return Card(
                        color: isNearest
                            ? Colors.blue.shade50
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      backgroundColor: Colors.white,
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
          Map pending = snapshotValue['drivers_pending_approval'] as Map? ?? {};
          Map verifiedDrivers = snapshotValue['verified_drivers'] as Map? ?? {};

          // SMART RADAR LOGIC
          String activityMsg =
              snapshotValue['latest_activity']?.toString() ??
              "System Monitoring... 🟢";
          if (reports.isNotEmpty)
            activityMsg = "New Reports Pending in Inbox! 📬";
          int leaveCount = verifiedDrivers.values
              .where((d) => d['attendance'] == 'On Leave')
              .length;
          if (leaveCount > 0)
            activityMsg = "Notice: $leaveCount Drivers are On Leave.";

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildCompactHeader(activityMsg),
              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 500),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        _buildSummarySection(
                          bins,
                          reports,
                        ), // FIXED OVERFLOW SECTION
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: softMint,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(35),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _build8GridMenu(
                                pending.length,
                                verifiedDrivers,
                                bins,
                              ),
                              _sectionTitle(
                                "Urgent Duty Assignments",
                                Icons.priority_high_rounded,
                              ),
                              _buildCriticalList(bins),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI: Compact Header ---
  Widget _buildCompactHeader(String msg) {
    return SliverAppBar(
      expandedHeight: 160.0,
      pinned: true,
      elevation: 0,
      backgroundColor: leafGreen,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20),
          onPressed: () => _handleLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 50),
        title: const Text(
          "ADMIN HUB",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1.5,
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
              bottom: 12,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: Colors.blue, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontSize: 9,
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

  // --- UI: Summary Section (FIXED OVERFLOW) ---
  Widget _buildSummarySection(Map bins, Map reports) {
    int critical = bins.values
        .where((b) => (b['fill_level'] ?? 0) >= 80)
        .length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      height: 110, // Explicit height to prevent internal overflow
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              index: 0,
              title: "Bins",
              value: bins.length.toString(),
              icon: Icons.delete,
              iconColor: leafGreen,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: SummaryCard(
              index: 1,
              title: "Critical",
              value: critical.toString(),
              icon: Icons.warning,
              iconColor: alertRed,
            ),
          ),
          const SizedBox(width: 5),
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
                    icon: Icons.chat_bubble,
                    iconColor: Colors.orange,
                  ),
                  if (reports.isNotEmpty)
                    Positioned(
                      right: -2,
                      top: -2,
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

  // --- UI: 8-Grid Menu ---
  Widget _build8GridMenu(int pCount, Map drivers, Map bins) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.4,
    children: [
      _gridItem("City Map", "📍", Colors.blue.shade100, const LiveMapScreen()),
      _gridItem(
        "Analytics",
        "📊",
        Colors.purple.shade100,
        const AnalyticsPage(),
      ),
      _gridItem(
        "Schedule",
        "📅",
        Colors.orange.shade100,
        const ScheduleManagementPage(),
      ),
      _gridItem(
        "Approvals",
        "✅",
        Colors.green.shade200,
        const DriverApprovalScreen(),
        badge: pCount,
      ),
      _gridItem(
        "Simulation",
        "🎮",
        Colors.teal.shade100,
        const SimulationScreen(),
      ),
      _gridItem("Duty Logs", "📝", Colors.indigo.shade100, null),
      _gridItem(
        "Drivers",
        "👤",
        Colors.brown.shade100,
        DriversStatusPage(drivers: drivers),
      ),
      _gridItem(
        "Photos",
        "📸",
        Colors.red.shade100,
        CollectionStatusPage(bins: bins),
      ),
    ],
  );

  Widget _buildCriticalList(Map bins) {
    var list = bins.entries
        .where((e) => (e.value['fill_level'] ?? 0) >= 75)
        .toList();
    if (list.isEmpty)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No critical bins. ✨",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    return Column(
      children: list.map((e) {
        double bLat = double.tryParse(e.value['lat'].toString()) ?? 0.0;
        double bLng = double.tryParse(e.value['lng'].toString()) ?? 0.0;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.error_outline, color: alertRed, size: 24),
            title: Text(
              e.value['area'] ?? "Sector",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              "Level: ${e.value['fill_level']}%",
              style: const TextStyle(fontSize: 11),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: deepForest,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () =>
                  _openAssignmentSheet(e.key, e.value['area'], bLat, bLng),
              child: const Text(
                "Assign",
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gridItem(String t, String e, Color c, Widget? p, {int badge = 0}) =>
      InkWell(
        onTap: p == null
            ? null
            : () =>
                  Navigator.push(context, MaterialPageRoute(builder: (c) => p)),
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
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(e, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 5),
                  Text(
                    t,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: deepForest,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(right: 12, top: 12, child: _badge(badge.toString())),
          ],
        ),
      );

  Widget _badge(String count) => Container(
    padding: const EdgeInsets.all(5),
    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    child: Text(
      count,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
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
    ),
  );
  Widget _sectionTitle(String t, IconData i) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        Icon(i, color: leafGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: deepForest,
          ),
        ),
      ],
    ),
  );
}

// --- UPDATED: Detailed Citizen Reports Inbox ---
class CitizenReportsPage extends StatelessWidget {
  final Map reports;
  const CitizenReportsPage({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text("Citizen Inbox"),
        backgroundColor: const Color(0xFF4CAF50),
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

// --- Driver Tracking & Photos ---
class DriversStatusPage extends StatelessWidget {
  final Map drivers;
  const DriversStatusPage({super.key, required this.drivers});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers Status"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Points")),
          ],
          rows: drivers.values.map((d) {
            bool isActive = d['attendance'] == "Present";
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    d['name'] ?? "Driver",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isActive ? "Active" : "Inactive",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                DataCell(Text("${d['points'] ?? 0} ⭐")),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class CollectionStatusPage extends StatelessWidget {
  final Map bins;
  const CollectionStatusPage({super.key, required this.bins});
  @override
  Widget build(BuildContext context) {
    var list = bins.entries.where((e) => e.value['fill_level'] == 0).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Photos"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: list.isEmpty
          ? const Center(child: Text("No records."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                var bin = list[index].value;
                return Card(
                  child: ListTile(
                    title: Text(bin['area'] ?? "Area"),
                    subtitle: const Text("Cleaned ✅"),
                  ),
                );
              },
            ),
    );
  }
}
