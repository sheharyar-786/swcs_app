import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_home_view.dart';
import '../approvals/manager_approvals.dart';
import '../user_management/staff_directory.dart';
import '../reports/report_center.dart';
import '../settings/profile_settings.dart';
import '../../services/monitoring_service.dart';
import 'dart:async';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _currentIndex = 0;

  void _onTabRequested(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  void initState() {
    super.initState();
    MonitoringService.startMonitoring();
  }

  @override
  void dispose() {
    MonitoringService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rootStream = FirebaseDatabase.instance.ref().onValue;

    final List<Widget> pages = [
      AdminHomeView(globalStream: rootStream, onTabRequested: _onTabRequested),

      ManagerApprovals(
        globalStream: FirebaseDatabase.instance.ref('pending_managers').onValue,
      ),

      StaffDirectory(globalStream: rootStream),

      /// FIXED REPORT PAGE
      ReportCenter(globalStream: rootStream),

      const ProfileSettings(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF0A714E),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 20,
          type: BottomNavigationBarType.fixed,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),

          unselectedLabelStyle: const TextStyle(fontSize: 11),

          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_rounded),
              label: 'Approvals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_late_rounded),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_pin_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
