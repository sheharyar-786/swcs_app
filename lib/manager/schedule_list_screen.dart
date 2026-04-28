import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_schedule_screen.dart';
import '../widgets/schedule_card.dart';
import '../widgets/universal_header.dart';

class ScheduleManagementPage extends StatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  State<ScheduleManagementPage> createState() => _ScheduleManagementPageState();
}

class _ScheduleManagementPageState extends State<ScheduleManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);


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

  Future<void> _moveToPast(String id, String area) async {
    await FirebaseDatabase.instance.ref('schedules/$id').update({
      "status": "Completed",
      "archivedAt": ServerValue.timestamp,
    });
    _msg("$area moved to History 📁");
  }

  Future<void> _deletePermanently(String id, String area) async {
    await FirebaseDatabase.instance.ref('schedules/$id').remove();
    _msg("$area deleted permanently 🗑️");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            UniversalHeader(
              title: "Collection Hub",
              showBackButton: true,
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: leafGreen,
                  indicatorWeight: 4,
                  labelColor: leafGreen,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(text: "ACTIVE DUTIES"),
                    Tab(text: "PAST HISTORY"),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveWrapper(child: _buildLiveScheduleList("Active")),
            KeepAliveWrapper(child: _buildLiveScheduleList("Completed")),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSchedule(context),
        backgroundColor: deepForest,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text(
          "CREATE SCHEDULE",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveScheduleList(String statusFilter) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('schedules').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        // FIX: Handle loading state correctly
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: leafGreen),
          );
        }

        // FIX: Handle null/empty data from Firebase to remove infinite loader
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return _buildEmptyState(statusFilter);
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

        // If list is empty after filtering by status
        if (liveList.isEmpty) return _buildEmptyState(statusFilter);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 100),
          physics: const BouncingScrollPhysics(),
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
              background: _buildActionBg(
                isActive ? Icons.archive : Icons.delete,
                isActive ? Colors.orange : Colors.redAccent,
              ),
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

  Widget _buildEmptyState(String filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 15),
          Text(
            "No $filter duties found.",
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBg(IconData icon, Color color) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 30),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(25),
    ),
    child: Icon(icon, color: Colors.white, size: 30),
  );

  Future<bool?> _showArchiveDialog(BuildContext context, String area) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "Archive Schedule? 📁",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text("Do you want to move '$area' to history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("BACK"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("ARCHIVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String area) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          "Delete Forever? 🗑️",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red),
        ),
        content: Text("Permanent deletion of '$area' cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: deepForest,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
