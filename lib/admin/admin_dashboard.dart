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
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color warningYellow = Color(0xFFFFD54F);
  static const Color alertRed = Color(0xFFE53935);
  static const Color starGold = Color(0xFFFFB300);

  // --- Persistent Streams to stop loading/crash issues ---
  late Stream<DatabaseEvent> _globalStream;
  late Stream<DatabaseEvent> _binStream;

  @override
  void initState() {
    super.initState();
    // Streams initialized as broadcast to prevent "Already listened" errors
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
    _binStream = FirebaseDatabase.instance
        .ref('bins/bin_01')
        .onValue
        .asBroadcastStream();
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🌿 SWCS Admin Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildAdminHeader(),

              // --- 1. FYP SIMULATION TOOL ---
              _buildSimulationTool(),

              // --- 2. SUMMARY CARDS ---
              _buildSummarySection(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: softMint,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMainGrid(),

                    // --- 3. DRIVER COLLECTION STATUS ---
                    _sectionTitle(
                      "Driver Collection Status",
                      Icons.delivery_dining_rounded,
                    ),
                    _buildDriverStatusList(),

                    const SizedBox(height: 20),

                    // --- 4. DETAILED CITIZEN REPORTS ---
                    _sectionTitle(
                      "Recent Citizen Reports",
                      Icons.report_problem_rounded,
                    ),
                    _buildDetailedCitizenReports(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminHeader() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('latest_activity').onValue,
      builder: (context, snapshot) {
        String msg =
            snapshot.data?.snapshot.value?.toString() ??
            "System Online & Monitoring";
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
          color: leafGreen,
          child: Column(
            children: [
              const Text(
                "Welcome, Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _statusNotificationBar(Icons.sync_rounded, msg, Colors.blue),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimulationTool() {
    return Container(
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report, color: Colors.orange),
        title: const Text(
          "FYP Simulation Mode (Live Testing)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        children: [
          StreamBuilder(
            stream: _binStream,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              double level = 0;
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                level = (snapshot.data!.snapshot.value as Map)['fill_level']
                    .toDouble();
              }
              return Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    Text(
                      "Bin #01 Level: ${level.toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: level,
                      min: 0,
                      max: 100,
                      activeColor: level > 80 ? alertRed : leafGreen,
                      onChanged: (v) => FirebaseDatabase.instance
                          .ref('bins/bin_01')
                          .update({"fill_level": v.toInt()}),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deepForest,
                          ),
                          onPressed: () {
                            FirebaseDatabase.instance
                                .ref('bins/bin_01/fill_level')
                                .set(0);
                            FirebaseDatabase.instance
                                .ref('latest_activity')
                                .set("Bin #01 Cleaned Successfully ✅");
                          },
                          child: const Text(
                            "Reset Bin",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            FirebaseDatabase.instance
                                .ref('bins/bin_01/gas_level')
                                .set(500);
                            FirebaseDatabase.instance
                                .ref('latest_activity')
                                .set("Gas Leakage Simulated! ⚠️");
                          },
                          child: const Text(
                            "Simulate Gas",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return StreamBuilder(
      stream: _globalStream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        String binsCount = "00", highCount = "00", topDriver = "N/A";
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          Map data = snapshot.data!.snapshot.value as Map;
          if (data['bins'] != null) {
            Map binsData = data['bins'] as Map;
            binsCount = binsData.length.toString().padLeft(2, '0');
            highCount = binsData.values
                .where((b) => (b['fill_level'] ?? 0) >= 80)
                .length
                .toString()
                .padLeft(2, '0');
          }
          if (data['verified_drivers'] != null) {
            var dList = (data['verified_drivers'] as Map).values.toList();
            dList.sort(
              (a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0),
            );
            topDriver = dList[0]['email'].split('@')[0].toUpperCase();
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: SizedBox(
            height: 170,
            child: Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    index: 0,
                    title: "Active Bins",
                    value: binsCount,
                    icon: Icons.delete,
                    iconColor: leafGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SummaryCard(
                    index: 1,
                    title: "High Fill",
                    value: highCount,
                    icon: Icons.warning,
                    iconColor: alertRed,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SummaryCard(
                    index: 2,
                    title: "Top Driver",
                    value: topDriver.length > 7
                        ? topDriver.substring(0, 6)
                        : topDriver,
                    icon: Icons.emoji_events,
                    iconColor: starGold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverStatusList() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          return const Text("No drivers online.");
        Map drivers = snapshot.data!.snapshot.value as Map;
        return Column(
          children: drivers.values.map((d) {
            bool isDone = d['status'] == "completed";
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDone ? leafGreen : warningYellow,
                  child: Icon(
                    isDone ? Icons.check : Icons.timer,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  d['email'].split('@')[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  isDone ? "Pickup Done ✅" : "On the way / Pending ⏳",
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text(
                  d['vehicleId'] ?? "N/A",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDetailedCitizenReports() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('citizen_reports').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
          return const Text("No active reports.");
        Map reports = snapshot.data!.snapshot.value as Map;
        return Column(
          children: reports.entries.map((e) {
            var r = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r['user'] ?? "Guest",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: deepForest,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: alertRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r['type'] ?? "Alert",
                          style: const TextStyle(
                            color: alertRed,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "📞 ${r['phone'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                  Text(
                    "📍 Street: ${r['address'] ?? 'N/A'}",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Divider(height: 20),
                  Text(
                    r['comment'] ?? "No additional details.",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: leafGreen,
                      ),
                      onPressed: () => FirebaseDatabase.instance
                          .ref('citizen_reports/${e.key}')
                          .remove(),
                      child: const Text(
                        "SOLVED",
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMainGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCartoonCard(
          context,
          title: "Live Map",
          icon: "📍",
          color: Colors.blue.shade100,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LiveMapScreen()),
          ),
        ),
        _buildCartoonCard(
          context,
          title: "Analytics",
          icon: "📊",
          color: Colors.purple.shade100,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsPage()),
          ),
        ),
        _buildCartoonCard(
          context,
          title: "Schedule",
          icon: "📅",
          color: Colors.orange.shade100,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleManagementPage(),
            ),
          ),
        ),
        _buildCartoonCard(
          context,
          title: "Approvals",
          icon: "✅",
          color: Colors.green.shade200,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DriverApprovalScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusNotificationBar(IconData icon, String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: deepForest,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: starGold, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: deepForest,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonCard(
    BuildContext context, {
    required String title,
    required String icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: leafGreen.withOpacity(0.08), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 25)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: deepForest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
