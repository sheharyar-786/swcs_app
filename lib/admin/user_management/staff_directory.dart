import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'user_details_edit.dart';
import '../../widgets/admin_header.dart';

class StaffDirectory extends StatefulWidget {
  final Stream<DatabaseEvent> globalStream;

  const StaffDirectory({super.key, required this.globalStream});

  @override
  State<StaffDirectory> createState() => _StaffDirectoryState();
}

class _StaffDirectoryState extends State<StaffDirectory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: StreamBuilder(
        stream: widget.globalStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A714E)),
            );
          }

          Map allData = snapshot.data!.snapshot.value as Map;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              AdminHeader(
                title: "Staff Directory",
                showBackButton: true,
              ),
              SliverToBoxAdapter(child: _buildStatementBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  child: Container(
                    color: const Color(0xFFF8FAF9),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildTabBar(),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList('manager', allData),
                _buildUserList('driver', allData),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  Widget _buildStatementBar() {
    return FadeInLeft(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A714E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF0A714E).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.people_outline, size: 18, color: Color(0xFF0A714E)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Complete directory of all registered system personnel and managers.",
                style: TextStyle(
                  color: Color(0xFF0A714E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search staff by name...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0A714E)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0A714E),
        ),
        tabs: const [
          Tab(text: "MANAGERS"),
          Tab(text: "DRIVERS"),
        ],
      ),
    );
  }

  Widget _buildUserList(String role, Map allData) {
    Map? users = allData['users'] as Map?;
    Map? verifiedDrivers = allData['verified_drivers'] as Map?;

    List<MapEntry> staffList = [];

    if (role == 'driver') {
      if (verifiedDrivers != null) {
        staffList = verifiedDrivers.entries.where((e) {
          var userMap = e.value as Map;
          String name = userMap['name']?.toString().toLowerCase() ?? "";
          return name.contains(_searchQuery);
        }).toList();
      }
    } else {
      if (users != null) {
        staffList = users.entries.where((e) {
          var userMap = e.value as Map;
          String userRole = userMap['role']?.toString() ?? "";
          String name = userMap['name']?.toString().toLowerCase() ?? "";
          bool isApproved = userMap['isApproved'] ?? false;

          return userRole == role && name.contains(_searchQuery) && isApproved;
        }).toList();
      }
    }

    if (staffList.isEmpty) return _buildEmptyState(role);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        var userMapRaw = staffList[index].value as Map;
        Map user = Map.from(userMapRaw);
        if (role == 'driver' && !user.containsKey('role')) {
          user['role'] = 'driver';
        }
        var uid = staffList[index].key;

        return FadeInLeft(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF0A714E).withValues(alpha: 0.1),
                child: Text(
                  (user['name']?.toString().isNotEmpty == true ? user['name'][0] : "U").toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0A714E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user['name'] ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user['email'] ?? "No email",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserDetailsEdit(uid: uid, userData: user),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String role) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "No active $role found",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 60.0;
  @override
  double get maxExtent => 60.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
