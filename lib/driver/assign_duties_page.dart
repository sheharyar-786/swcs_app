import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../manager/live_map_screen.dart';
import '../manager/bin_utils.dart';
import '../widgets/universal_header.dart';

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

  late Stream<DatabaseEvent> _scheduleStream;
  late Stream<DatabaseEvent> _binStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _scheduleStream = FirebaseDatabase.instance
        .ref()
        .child('schedules')
        .onValue
        .asBroadcastStream();

    _binStream = FirebaseDatabase.instance
        .ref()
        .child('bins')
        .onValue
        .asBroadcastStream();
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          UniversalHeader(
            title: "Mission Control",
            showBackButton: true,
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.green,
                indicatorWeight: 4,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.calendar_month_rounded), text: "Collection"),
                  Tab(
                    icon: Icon(Icons.bolt_rounded),
                    text: "Emergency",
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('lib/assets/bg.jpeg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.92),
                BlendMode.lighten,
              ),
            ),
          ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _CollectionTab(
              stream: _scheduleStream,
              userEmail: userEmail,
              onAction: _showStartDialog,
            ),
            _EmergencyTab(
              stream: _binStream,
              userId: userId,
              onAction: _showStartDialog,
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showStartDialog(String area) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Row(
          children: [
            Icon(Icons.local_shipping_rounded, color: Color(0xFF1B5E20)),
            SizedBox(width: 10),
            Text(
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
            ),
            onPressed: () {
              Navigator.pop(c);
              // PASS THE AREA NAME HERE
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveMapScreen(assignedArea: area),
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

// --- Internal Collection Tab Class ---
class _CollectionTab extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final String? userEmail;
  final Function(String) onAction;

  const _CollectionTab({
    required this.stream,
    required this.userEmail,
    required this.onAction,
  });

  @override
  State<_CollectionTab> createState() => _CollectionTabState();
}

class _CollectionTabState extends State<_CollectionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _emptyState(
            "No schedules found in Database.",
            Icons.cloud_off,
          );
        }

        Map data = snapshot.data!.snapshot.value as Map;
        var myTasks = data.entries.where((e) {
          var val = e.value;
          return val['driver_email'] == widget.userEmail &&
              val['status'] == "Active";
        }).toList();

        if (myTasks.isEmpty) {
          return _emptyState(
            "No active schedules for ${widget.userEmail}",
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
              onTap: () => widget.onAction(task['area'] ?? "Unknown Area"),
            );
          },
        );
      },
    );
  }
}

// --- Internal Emergency Tab Class ---
class _EmergencyTab extends StatefulWidget {
  final Stream<DatabaseEvent> stream;
  final String? userId;
  final Function(String) onAction;

  const _EmergencyTab({
    required this.stream,
    required this.userId,
    required this.onAction,
  });

  @override
  State<_EmergencyTab> createState() => _EmergencyTabState();
}

class _EmergencyTabState extends State<_EmergencyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _emptyState(
            "No alerts from IoT sensors.",
            Icons.sensors_rounded,
          );
        }

        Map bins = snapshot.data!.snapshot.value as Map;
        var criticalTasks = bins.entries.where((e) {
          var val = e.value;
          return val['assigned_to'] == widget.userId &&
              (BinData.fillLevel(val) >= 80 || BinData.gasLevel(val) > 400);
        }).toList();

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
            String area = BinData.area(bin);
            bool isGas = BinData.gasLevel(bin) > 400;
            return _dutyCard(
              title: area,
              subtitle: isGas
                  ? "⚠️ DANGER: HIGH GAS DETECTED"
                  : "🚨 ALERT: BIN OVERFLOW",
              tag: "EMERGENCY",
              icon: isGas
                  ? Icons.gas_meter_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.redAccent,
              onTap: () => widget.onAction(area),
            );
          },
        );
      },
    );
  }
}

// --- Shared Helper UI Methods ---
Widget _dutyCard({
  required String title,
  required String subtitle,
  required String tag,
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(color: color.withValues(alpha: 0.1)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(20),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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
      trailing: IconButton(
        icon: Icon(Icons.play_arrow_rounded, color: color, size: 40),
        onPressed: onTap,
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
