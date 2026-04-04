import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Map screen ka path sahi kar lijiyega agar folder different hai
import '../admin/live_map_screen.dart';

class AssignDutiesPage extends StatefulWidget {
  const AssignDutiesPage({super.key});

  @override
  State<AssignDutiesPage> createState() => _AssignDutiesPageState();
}

class _AssignDutiesPageState extends State<AssignDutiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text(
          "MISSION CONTROL",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 8,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellowAccent,
          indicatorWeight: 4,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded), text: "Collection"),
            Tab(
              icon: Icon(Icons.bolt_rounded, color: Colors.yellowAccent),
              text: "Emergency",
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCollectionTab(), _buildEmergencyTab()],
      ),
    );
  }

  // --- 1. Collection Tab (Routine Schedules) ---
  Widget _buildCollectionTab() {
    return StreamBuilder(
      // .asBroadcastStream() add kiya hai taake red screen error na aaye
      stream: FirebaseDatabase.instance
          .ref()
          .child('schedules')
          .onValue
          .asBroadcastStream(),
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _emptyState(
            "No schedules found in Database.",
            Icons.cloud_off,
          );
        }

        Map data = snapshot.data!.snapshot.value as Map;
        var myTasks = data.entries.where((e) {
          var val = e.value;
          return val['driver_email'] == userEmail && val['status'] == "Active";
        }).toList();

        if (myTasks.isEmpty) {
          return _emptyState(
            "No active schedules for $userEmail",
            Icons.task_alt,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: myTasks.length,
          itemBuilder: (context, index) {
            var task = myTasks[index].value;
            return _dutyCard(
              title: task['area'] ?? "Unknown Area",
              subtitle: "Days: ${task['day']}\nTime: ${task['time']}",
              tag: "SCHEDULED",
              icon: Icons.map_outlined,
              color: Colors.blueAccent,
            );
          },
        );
      },
    );
  }

  // --- 2. Emergency Tab (IoT Critical Bins) ---
  Widget _buildEmergencyTab() {
    return StreamBuilder(
      // .asBroadcastStream() yahan bhi zaroori hai switching ke liye
      stream: FirebaseDatabase.instance
          .ref()
          .child('bins')
          .onValue
          .asBroadcastStream(),
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _emptyState(
            "No alerts from IoT sensors.",
            Icons.sensors_rounded,
          );
        }

        Map bins = snapshot.data!.snapshot.value as Map;
        var criticalTasks = bins.entries
            .where(
              (e) =>
                  e.value['assigned_to'] == userId &&
                  ((e.value['fill_level'] ?? 0) >= 80 ||
                      (e.value['gas_level'] ?? 0) > 400),
            )
            .toList();

        if (criticalTasks.isEmpty) {
          return _emptyState(
            "No emergency pickups assigned to you.",
            Icons.notifications_none_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: criticalTasks.length,
          itemBuilder: (context, index) {
            var bin = criticalTasks[index].value;
            bool isGas = (bin['gas_level'] ?? 0) > 400;
            return _dutyCard(
              title: bin['area'] ?? "Critical Zone",
              subtitle: isGas
                  ? "⚠️ DANGER: HIGH GAS DETECTED"
                  : "🚨 ALERT: BIN OVERFLOW",
              tag: "EMERGENCY",
              icon: isGas
                  ? Icons.gas_meter_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.redAccent,
              isEmergency: true,
            );
          },
        );
      },
    );
  }

  Widget _dutyCard({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required Color color,
    bool isEmergency = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: InkWell(
          onTap: () => _showStartDialog(title),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 35),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStartDialog(String area) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_rounded, color: Color(0xFF1B5E20)),
            const SizedBox(width: 10),
            const Text(
              "Deploy Mission?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Target Area: $area\n\nSystems will now calculate the most fuel-efficient route using ACO Logic. Proceed?",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              "STAND BY",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(c); // Close Dialog

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LiveMapScreen()),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("🚚 MISSION STARTED: Routing to $area..."),
                  backgroundColor: const Color(0xFF1B5E20),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              "LET'S GO",
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
}
