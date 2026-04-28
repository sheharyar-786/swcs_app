import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'user_details_edit.dart';
import '../../widgets/admin_header.dart';

class StaffDirectory extends StatefulWidget {
  final Stream<DatabaseEvent> globalStream;
  final int initialTabIndex;
  final DatabaseEvent? initialData;

  const StaffDirectory({
    super.key,
    required this.globalStream,
    this.initialTabIndex = 0,
    this.initialData,
  });

  @override
  State<StaffDirectory> createState() => _StaffDirectoryState();
}

class _StaffDirectoryState extends State<StaffDirectory>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, Verified, Pending

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
        initialData: widget.initialData,
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
              SliverToBoxAdapter(child: _buildFilterSection()),
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

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        children: [
          _filterChip("All"),
          const SizedBox(width: 10),
          _filterChip("Verified"),
          const SizedBox(width: 10),
          _filterChip("Pending"),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A714E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A714E) : Colors.grey.withValues(alpha: 0.2),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0A714E).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
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
      // 1. Get drivers from verified_drivers node
      if (verifiedDrivers != null) {
        staffList.addAll(verifiedDrivers.entries);
      }
      
      // 2. Get drivers from users node (that might not be in verified_drivers yet)
      if (users != null) {
        var userDrivers = users.entries.where((e) {
          var u = e.value as Map;
          return u['role'] == 'driver' && !staffList.any((existing) => existing.key == e.key);
        });
        staffList.addAll(userDrivers);
      }
    } else {
      // Managers
      if (users != null) {
        var managerList = users.entries.where((e) {
          var userMap = e.value as Map;
          return userMap['role'] == 'manager';
        });
        staffList.addAll(managerList);
      }
    }

    // 3. Filter by search query & Status Filter
    staffList = staffList.where((e) {
      var userMap = e.value as Map;
      String name = userMap['name']?.toString().toLowerCase() ?? "";
      bool matchesSearch = name.contains(_searchQuery);

      bool isVerified = false;
      if (role == 'driver') {
        isVerified = (verifiedDrivers ?? {}).containsKey(e.key);
      } else {
        isVerified = userMap['isApproved'] ?? false;
      }

      bool matchesFilter = true;
      if (_selectedFilter == "Verified") matchesFilter = isVerified;
      if (_selectedFilter == "Pending") matchesFilter = !isVerified;

      return matchesSearch && matchesFilter;
    }).toList();

    // --- SORTING: Pending/Unverified staff at the top ---
    staffList.sort((a, b) {
      bool isAApproved = false;
      bool isBApproved = false;

      if (role == 'driver') {
        isAApproved = (verifiedDrivers ?? {}).containsKey(a.key);
        isBApproved = (verifiedDrivers ?? {}).containsKey(b.key);
      } else {
        isAApproved = (a.value as Map)['isApproved'] ?? false;
        isBApproved = (b.value as Map)['isApproved'] ?? false;
      }

      if (isAApproved == isBApproved) return 0;
      return isAApproved ? 1 : -1; // Unverified first
    });

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
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      user['name'] ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(role, user, uid, verifiedDrivers ?? {}),
                ],
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

  Widget _buildStatusBadge(String role, Map user, String uid, Map verifiedDrivers) {
    bool isVerified = false;
    if (role == 'driver') {
      isVerified = verifiedDrivers.containsKey(uid);
    } else {
      isVerified = user['isApproved'] ?? false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isVerified ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        isVerified ? "VERIFIED" : "PENDING",
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: isVerified ? Colors.green[700] : Colors.orange[700],
          letterSpacing: 0.5,
        ),
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
