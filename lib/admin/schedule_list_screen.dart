import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_schedule_screen.dart';
import '../widgets/schedule_card.dart';

class ScheduleManagementPage extends StatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  State<ScheduleManagementPage> createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<DatabaseEvent> _scheduleStream;

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scheduleStream = FirebaseDatabase.instance
        .ref('schedules')
        .onValue
        .asBroadcastStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC 1: Move to Past (Archive) ---
  Future<void> _moveToPast(String id, String area) async {
    await FirebaseDatabase.instance.ref('schedules/$id').update({
      "status": "Completed",
      "archivedAt": ServerValue.timestamp,
    });
    _msg("$area moved to Past History 📁");
  }

  // --- LOGIC 2: Permanent Delete (From History) ---
  Future<void> _deletePermanently(String id, String area) async {
    await FirebaseDatabase.instance.ref('schedules/$id').remove();
    _msg("$area deleted permanently 🗑️");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: leafGreen,
      appBar: AppBar(
        title: const Text(
          "📅 Collection Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: "Active Duties"),
            Tab(text: "Past History"),
          ],
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: softMint,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveWrapper(child: _buildLiveScheduleList("Active")),
            KeepAliveWrapper(child: _buildLiveScheduleList("Completed")),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSchedule(context),
        backgroundColor: leafGreen,
        label: const Text(
          "New Duty",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildLiveScheduleList(String statusFilter) {
    return StreamBuilder(
      stream: _scheduleStream,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text("No duties found."));
        }

        Map data = snapshot.data!.snapshot.value as Map;
        List liveList = data.entries
            .map(
              (e) => {
                "id": e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              },
            )
            .where((s) => (s['status'] ?? "Active") == statusFilter)
            .toList();

        if (liveList.isEmpty) {
          return Center(
            child: Text(
              "No $statusFilter duties.",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: liveList.length,
          itemBuilder: (context, index) {
            final item = liveList[index];
            bool isActive = statusFilter == "Active";

            return Dismissible(
              key: Key(item['id'].toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (dir) => isActive
                  ? _showArchiveDialog(context, item['area'])
                  : _showDeleteDialog(context, item['area']),
              onDismissed: (dir) => isActive
                  ? _moveToPast(item['id'], item['area'])
                  : _deletePermanently(item['id'], item['area']),
              background: isActive ? _buildArchiveBg() : _buildDeleteBg(),
              child: ScheduleCard(
                index: index,
                area: item['area'] ?? "Unknown",
                day: item['day'] ?? "N/A",
                time: item['time'] ?? "N/A",
                status: item['status'] ?? "Active",
                onEdit: item['status'] == "Completed"
                    ? null
                    : () => _openEditSchedule(context, item),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArchiveBg() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 25),
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.orangeAccent,
      borderRadius: BorderRadius.circular(25),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.archive_rounded, color: Colors.white, size: 30),
        Text(
          "ARCHIVE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );

  Widget _buildDeleteBg() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 25),
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(25),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete_forever_rounded, color: Colors.white, size: 30),
        Text(
          "DELETE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );

  Future<bool?> _showArchiveDialog(BuildContext context, String area) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text(
          "Move to History? 📁",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        content: Text("Mark '$area' as completed and move it to past history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("MOVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String area) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text(
          "Delete Permanently? 🗑️",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          "Are you sure you want to completely remove '$area'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: deepForest,
      behavior: SnackBarBehavior.floating,
    ),
  );

  void _openAddSchedule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddScheduleScreen(),
    );
  }

  void _openEditSchedule(BuildContext context, dynamic scheduleData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleScreen(existingData: scheduleData),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});
  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
