import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'analytics_screen.dart';
import 'schedule_list_screen.dart';
import 'driver_approval_screen.dart';
import 'live_map_screen.dart';
import '../auth/login_screen.dart';
import '../widgets/summary_card.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // --- Master Theme Colors ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color alertRed = Color(0xFFE53935);
  static const Color starGold = Color(0xFFFFB300);

  late Stream<DatabaseEvent> _globalStream;

  // --- Sadiqabad Precise Coordinates for Simulation ---
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
    {"id": "bin_09", "area": "Civil Line", "lat": 28.3061, "lng": 70.1369},
    {
      "id": "bin_10",
      "area": "Zaka Center Market",
      "lat": 28.3125,
      "lng": 70.1399,
    },
  ];

  @override
  void initState() {
    super.initState();
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
  }

  // --- LOGIC: Assign Duty to Active Drivers ---
  void _openAssignmentSheet(String binId, String area) {
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
          Map drivers = snapshot.data!.snapshot.value as Map? ?? {};
          var activeDrivers = drivers.entries
              .where((d) => d.value['attendance'] == 'Present')
              .toList();

          return Container(
            padding: const EdgeInsets.all(25),
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                _sectionTitle(
                  "Assign Active Driver to $area",
                  Icons.person_add_alt_1,
                ),
                const Divider(),
                if (activeDrivers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text("No drivers are currently Present! 🛑"),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: activeDrivers.length,
                    itemBuilder: (context, index) {
                      var driver = activeDrivers[index];
                      return Card(
                        elevation: 0,
                        color: softMint.withOpacity(0.5),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: leafGreen,
                            child: Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            driver.value['name'] ?? "Driver",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Points: ${driver.value['points'] ?? 0}",
                          ),
                          trailing: const Icon(
                            Icons.send_rounded,
                            color: leafGreen,
                          ),
                          onTap: () => _finalizeDuty(
                            binId,
                            driver.key,
                            driver.value['name'],
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
        .set("Mission Assigned: $name is on route! 🚛");
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
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );

          Map data = snapshot.data!.snapshot.value as Map? ?? {};
          Map bins = data['bins'] ?? {};
          Map reports = data['citizen_reports'] ?? {};
          Map pending = data['drivers_pending_approval'] ?? {};
          Map verifiedDrivers = data['verified_drivers'] ?? {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildParallaxHeader(data['latest_activity']?.toString()),
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: Image.network(
                          'https://www.transparenttextures.com/patterns/leaf.png',
                          repeat: ImageRepeat.repeat,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _buildSummarySection(bins, reports),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: const BoxDecoration(
                            color: softMint,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 25),
                              _build8GridMenu(
                                pending.length,
                                verifiedDrivers,
                                bins,
                              ),
                              _sectionTitle(
                                "Sadiqabad Live Test Simulator",
                                Icons.tune_rounded,
                              ),
                              _buildSimulatorPanel(bins),
                              _sectionTitle(
                                "Urgent Duty Assignments",
                                Icons.priority_high_rounded,
                              ),
                              _buildCriticalList(bins),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
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

  // --- UI COMPONENTS ---

  Widget _buildParallaxHeader(String? msg) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: leafGreen,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _handleLogout(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "🌿 Admin Control Hub",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?q=80&w=1000',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.transparent,
                    leafGreen.withOpacity(0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: Colors.blue, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        msg ?? "Monitoring Sensors...",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: deepForest,
                        ),
                        maxLines: 1,
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
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              index: 0,
              title: "Active Bins",
              value: bins.length.toString(),
              icon: Icons.delete,
              iconColor: leafGreen,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SummaryCard(
              index: 1,
              title: "Critical",
              value: critical.toString(),
              icon: Icons.warning,
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
                      right: -5,
                      top: -5,
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

  Widget _build8GridMenu(int pCount, Map drivers, Map bins) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.3,
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
      _gridItem("Simulation", "🎮", Colors.teal.shade100, null),
      _gridItem("Duty Assign", "📝", Colors.indigo.shade100, null),
      _gridItem(
        "Drivers",
        "👤",
        Colors.brown.shade100,
        DriversStatusPage(drivers: drivers),
      ),
      _gridItem(
        "Collection",
        "📸",
        Colors.red.shade100,
        CollectionStatusPage(bins: bins),
      ),
    ],
  );

  Widget _buildSimulatorPanel(Map bins) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: sadiqabadGrid.length,
        itemBuilder: (context, index) {
          var config = sadiqabadGrid[index];
          var bData = bins[config['id']] ?? {'fill_level': 0, 'gas_level': 0};
          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 15, bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text(
                  config['id'].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _sliderLabel("Fill: ${bData['fill_level']}%"),
                Slider(
                  value: (bData['fill_level'] ?? 0).toDouble(),
                  min: 0,
                  max: 100,
                  activeColor: leafGreen,
                  onChanged: (v) => _updateFB(config, 'fill_level', v.toInt()),
                ),
                _sliderLabel("Gas: ${bData['gas_level']}"),
                Slider(
                  value: (bData['gas_level'] ?? 0).toDouble(),
                  min: 0,
                  max: 1000,
                  activeColor: Colors.orange,
                  onChanged: (v) => _updateFB(config, 'gas_level', v.toInt()),
                ),
                Text(
                  config['area'],
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCriticalList(Map bins) {
    var list = bins.entries
        .where((e) => (e.value['fill_level'] ?? 0) >= 75)
        .toList();
    if (list.isEmpty)
      return const Center(child: Text("No critical bins right now. ✨"));
    return Column(
      children: list
          .map(
            (e) => Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: Icon(Icons.error, color: alertRed),
                title: Text(e.value['area'] ?? "Sector"),
                subtitle: Text("Level: ${e.value['fill_level']}%"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepForest,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _openAssignmentSheet(e.key, e.value['area']),
                  child: const Text(
                    "Assign",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _updateFB(Map loc, String field, int val) {
    FirebaseDatabase.instance.ref('bins/${loc['id']}').update({
      field: val,
      'lat': loc['lat'],
      'lng': loc['lng'],
      'area': loc['area'],
    });
    if (field == 'fill_level' && val > 95) {
      FirebaseDatabase.instance
          .ref('latest_activity')
          .set("CRITICAL: Overflow at ${loc['area']}! 🚨");
    }
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
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: deepForest,
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

  Widget _badge(String count) => Container(
    padding: const EdgeInsets.all(6),
    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    child: Text(
      count,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
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
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        Icon(i, color: leafGreen, size: 24),
        const SizedBox(width: 10),
        Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: deepForest,
          ),
        ),
      ],
    ),
  );
  Widget _sliderLabel(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      t,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

// --- NEW SYNCED PAGES ---

class DriversStatusPage extends StatelessWidget {
  final Map drivers;
  const DriversStatusPage({super.key, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drivers Live Tracking"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Status")),
            DataColumn(label: Text("Points")),
            DataColumn(label: Text("Leave/Reason")),
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
                DataCell(
                  Text(
                    d['leave_reason'] ?? "N/A",
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
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
    var collectionList = bins.entries
        .where((e) => e.value['status'] == "Cleaned")
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collection Proofs"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: collectionList.isEmpty
          ? const Center(child: Text("No proofs yet today."))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: collectionList.length,
              itemBuilder: (context, index) {
                var bin = collectionList[index].value;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(bin['area'] ?? "Area"),
                        subtitle: Text(
                          "By: ${bin['last_cleaned_by'] ?? 'Driver'}",
                        ),
                      ),
                      if (bin['last_evidence'] != null)
                        Image.memory(
                          base64Decode(bin['last_evidence']),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class CitizenReportsPage extends StatelessWidget {
  final Map reports;
  const CitizenReportsPage({super.key, required this.reports});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports Center"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: reports.isEmpty
          ? const Center(child: Text("Clear! ✨"))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                var r = reports.values.toList()[index];
                var key = reports.keys.toList()[index];
                return Card(
                  child: ListTile(
                    title: Text(r['user'] ?? "Guest"),
                    subtitle: Text(r['area'] ?? "Location"),
                    trailing: IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => FirebaseDatabase.instance
                          .ref('citizen_reports/$key')
                          .remove(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
