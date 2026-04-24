import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // Added for Global Stream
import 'admin_home_view.dart';
import '../approvals/manager_approvals.dart';
import '../user_management/staff_directory.dart';
import '../reports/report_center.dart';
import '../settings/profile_settings.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _currentIndex = 0;

  // --- FIX: Global Broadcast Stream ---
  // Is se "Stream has already been listened to" wala error khatam ho jayega
  late Stream<DatabaseEvent> _globalStream;

  @override
  void initState() {
    super.initState();
    // Pure database ki aik hi stream banai jo broadcast hai (multiple listeners allowed)
    _globalStream = FirebaseDatabase.instance.ref().onValue.asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    // Pages list ko build ke andar rakha hai taake stream pass ho sake
    final List<Widget> pages = [
      AdminHomeView(globalStream: _globalStream), // Stats Page
      ManagerApprovals(globalStream: _globalStream), // Approvals
      StaffDirectory(globalStream: _globalStream), // Users Page
      ReportCenter(globalStream: _globalStream), // Reports
      const ProfileSettings(), // Profile & Config
    ];

    return Scaffold(
      // IndexedStack use karne se state maintain rehti hai
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
          onTap: (index) => setState(() => _currentIndex = index),
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
