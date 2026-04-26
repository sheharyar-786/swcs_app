import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'notification_service.dart';

class MonitoringService {
  static StreamSubscription<DatabaseEvent>? _reportsSubscription;
  static StreamSubscription<DatabaseEvent>? _staffSubscription;

  static void startMonitoring() {
    final db = FirebaseDatabase.instance.ref();

    // 1. Monitor Citizen Reports for Escalation
    _reportsSubscription = db.child('citizen_reports').onValue.listen((event) async {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        
        // Fetch Admin's set threshold (Default 48h if not set)
        final settingsSnap = await db.child('system_settings/thresholds/complaint_escalation_hours').get();
        int thresholdHours = (settingsSnap.value as int?) ?? 48;
        
        data.forEach((key, value) {
          if (value['status'] == 'Pending') {
            int timestamp = value['timestamp'] ?? 0;
            if (timestamp > 0) {
              DateTime reportTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              Duration diff = DateTime.now().difference(reportTime);
              
              if (diff.inHours >= thresholdHours) {
                NotificationService.showNotification(
                  "Critical: Complaint Overdue",
                  "Report at ${value['area']} is pending for over $thresholdHours hours!"
                );
              }
            }
          }
        });
      }
    });

    // 2. Monitor Pending Drivers/Staff for New Approvals
    _staffSubscription = db.child('pending_drivers').onChildAdded.listen((event) {
      _triggerNewStaffAlert(event);
    });

    // 3. Monitor Pending Managers
    db.child('pending_managers').onChildAdded.listen((event) {
      _triggerNewStaffAlert(event);
    });
  }

  static void _triggerNewStaffAlert(DatabaseEvent event) {
    if (event.snapshot.exists) {
      final staffData = event.snapshot.value as Map<dynamic, dynamic>;
      String name = staffData['name'] ?? "New User";
      String role = staffData['role'] ?? "Staff";
      
      NotificationService.showNotification(
        "New Approval Pending",
        "$name is waiting for approval as $role."
      );
    }
  }

  static void stopMonitoring() {
    _reportsSubscription?.cancel();
    _staffSubscription?.cancel();
  }
}
