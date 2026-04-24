import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'user_details_edit.dart';

class StaffDirectory extends StatefulWidget {
  // Receive broadcast stream from AdminMainShell
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
      // BouncingScrollPhysics adds a premium feel to the whole column if needed
      body: StreamBuilder(
        stream: widget.globalStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A714E)));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0A714E)));
          }
          
          Map allData = snapshot.data!.snapshot.value as Map;

          return Column(
            children: [
              _buildPremiumHeader(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList('manager', allData), 
                    _buildUserList('driver', allData)
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- UI Components ---

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0A714E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Staff Directory",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Monitor and manage your city's workforce",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
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
        indicatorSize:
            TabBarIndicatorSize.tab, // Ensures indicator covers full tab
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

          return userRole == role &&
              name.contains(_searchQuery) &&
              isApproved;
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
                        (user['name'] ?? "U")[0].toUpperCase(),
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
