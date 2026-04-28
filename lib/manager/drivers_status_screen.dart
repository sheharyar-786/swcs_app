import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_database/firebase_database.dart';

class DriversStatusPage extends StatefulWidget {
  final Map drivers;
  const DriversStatusPage({super.key, required this.drivers});

  @override
  State<DriversStatusPage> createState() => _DriversStatusPageState();
}

class _DriversStatusPageState extends State<DriversStatusPage> {
  late Map _localDrivers;

  @override
  void initState() {
    super.initState();
    _localDrivers = {};
    widget.drivers.forEach((key, value) {
      if (value is Map) {
        _localDrivers[key] = Map.from(value);
      } else {
        _localDrivers[key] = value;
      }
    });
  }

  // Theme Colors
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color premiumNavy = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    // Analytics Calculations
    int totalDrivers = _localDrivers.length;
    int activeNow = _localDrivers.values
        .where((d) => d['attendance'] == "Present")
        .length;
    int onLeave = totalDrivers - activeNow;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Professional Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'lib/assets/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context),

              // 3. STATS SECTION (Now separated from header)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: leafGreen.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headerStat("TOTAL STAFF", totalDrivers.toString(), leafGreen),
                      _headerStat("ON-DUTY", activeNow.toString(), Colors.blue),
                      _headerStat("LEAVE", onLeave.toString(), Colors.orange),
                    ],
                  ),
                ),
              ),

              // 4. Main Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _sectionLabel("Verified Team Members"),
                    const SizedBox(height: 15),

                    // 4. Staggered List of Drivers
                    AnimationLimiter(
                      child: Column(
                        children: _localDrivers.entries.map((entry) {
                          int index = _localDrivers.keys.toList().indexOf(entry.key);
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildDriverCard(
                                  context,
                                  entry.key,
                                  entry.value,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showExportPreview(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: premiumNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.table_view_rounded, color: Colors.white),
                        label: const Text(
                          "GENERATE XL REPORT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
  ) {
    return SliverAppBar(
      expandedHeight: 120.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: true,
      title: const Text(
        "STAFF DIRECTORY",
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Image.asset(
                'lib/assets/bg.jpeg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, String val, Color color) => Column(
    children: [
      Text(
        val,
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ],
  );

  Widget _buildDriverCard(BuildContext context, String uid, dynamic data) {
    bool isPresent = data['attendance'] == "Present";
    bool onRoute = data['status'] == "On Route";
    bool isOnLeave = data['attendance'] == "On Leave" || (data['leave_reason'] != null && data['leave_reason'].toString().isNotEmpty);
    String leaveReason = data['leave_reason']?.toString() ?? "No reason provided";
    String leaveStatus = data['leave_status']?.toString() ?? "Pending";

    return GestureDetector(
      onTap: () => _openDriverDetails(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Driver Profile Pic Placeholder with Status Glow
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isPresent
                      ? leafGreen.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  child: Icon(
                    Icons.person_rounded,
                    color: isPresent ? leafGreen : Colors.grey,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "Driver",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    data['assignedDuty'] ?? "General Duty",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.delete_sweep_rounded, size: 12, color: leafGreen),
                      const SizedBox(width: 4),
                      Text(
                        "${data['total_collections'] ?? 0} Bins Collected",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        data['attendance'] == "Present" ? Icons.check_circle_outline : Icons.event_busy_rounded,
                        size: 12, 
                        color: data['attendance'] == "Present" ? leafGreen : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${data['attendance'] ?? 'Absent'} - ${data['attendance_time'] != null && int.tryParse(data['attendance_time'].toString()) != null && int.parse(data['attendance_time'].toString()) > 0 ? DateFormat('hh:mm a, MMM d').format(DateTime.fromMillisecondsSinceEpoch(int.parse(data['attendance_time'].toString()))) : "Time N/A"}",
                        style: TextStyle(
                          fontSize: 9, 
                          color: data['attendance'] == "Present" ? leafGreen : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${data['points'] ?? 0} ⭐",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 5),
                _statusChip(
                  onRoute ? "ON ROUTE" : (isPresent ? "FREE" : "OFF-DUTY"),
                  onRoute ? Colors.blue : (isPresent ? leafGreen : Colors.grey),
                ),
              ],
            ),
          ],
        ),
        if (isOnLeave) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),
          Row(
            children: [
              const Icon(Icons.description_rounded, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "Leave Reason: $leaveReason",
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (leaveStatus == "Pending")
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateLeaveStatus(uid, "Rejected"),
                  child: const Text("REJECT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leafGreen,
                    minimumSize: const Size(80, 30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _updateLeaveStatus(uid, "Approved"),
                  child: const Text("APPROVE", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: leaveStatus == "Approved" ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "Leave $leaveStatus",
                    style: TextStyle(
                      color: leaveStatus == "Approved" ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ],
    ),
  ),
);
}

void _updateLeaveStatus(String uid, String status) async {
  final db = FirebaseDatabase.instance.ref();
  
  // 1. Update Leave Status
  await db.child('verified_drivers/$uid').update({
    'leave_status': status,
  });

  // 2. Notify Driver
  await db.child('driver_notifications/$uid').push().set({
    'title': 'Leave Request $status',
    'message': status == "Approved" 
        ? "Your leave request has been accepted. Enjoy your day! ✅"
        : "Your leave request was not approved. Please contact management for details. ❌",
    'timestamp': ServerValue.timestamp,
    'status': 'Unread',
    'type': 'leave_alert'
  });

  if (mounted) {
    setState(() {
      if (_localDrivers[uid] != null) {
        _localDrivers[uid]['leave_status'] = status;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Leave $status & Driver Notified!"),
        backgroundColor: status == "Approved" ? Colors.green : Colors.red,
      ),
    );
  }
}

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
    ),
  );

  void _openDriverDetails(BuildContext context, dynamic data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data['name'].toString().toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: deepForest,
              ),
            ),
            const Divider(height: 30),
            _detailRow(
              Icons.email_outlined,
              "Email Address",
              data['email'] ?? "N/A",
            ),
            _detailRow(
              Icons.local_shipping_outlined,
              "Assigned Vehicle",
              data['vehicleId'] ?? "Not Assigned",
            ),
            _detailRow(
              Icons.location_on_outlined,
              "Assigned Area",
              data['area'] ?? "Sector Global",
            ),
            _detailRow(
              Icons.analytics_outlined,
              "Total Collections",
              "${data['total_collections'] ?? 0} Bins",
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: leafGreen,
                shape: const StadiumBorder(),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CLOSE PROFILE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, size: 18, color: leafGreen),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const Spacer(),
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    ),
  );

  void _showExportPreview(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String csv = "Driver Name,Email,Assigned Duty,Status,Time,Total Bins Collected,Points/Rating,Leave Reason,Leave Status\n";
      _localDrivers.forEach((key, val) {
        String name = val['name']?.toString() ?? 'N/A';
        String email = val['email']?.toString() ?? 'N/A';
        String duty = val['assignedDuty']?.toString() ?? 'General Duty';
        String attendance = val['attendance']?.toString() ?? 'Absent';
        
        String timeStr = "N/A";
        if (val['attendance_time'] != null) {
          int ms = int.tryParse(val['attendance_time'].toString()) ?? 0;
          if (ms > 0) {
            timeStr = DateFormat('hh:mm a, MMM d').format(DateTime.fromMillisecondsSinceEpoch(ms));
          }
        }
        
        int cols = int.tryParse(val['total_collections']?.toString() ?? '0') ?? 0;
        int pts = int.tryParse(val['points']?.toString() ?? '0') ?? 0;
        
        String leaveReason = val['leave_reason']?.toString() ?? '';
        String leaveStatus = val['leave_status']?.toString() ?? '';
        
        // Escape commas for CSV
        name = name.replaceAll(',', ' ');
        email = email.replaceAll(',', ' ');
        duty = duty.replaceAll(',', ' ');
        timeStr = timeStr.replaceAll(',', ' ');
        leaveReason = leaveReason.replaceAll(',', ' ');
        
        csv += "$name,$email,$duty,$attendance,$timeStr,$cols,$pts,$leaveReason,$leaveStatus\n";
      });

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/driver_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      // Use Share from share_plus (Updated to avoid deprecation hint if possible)
      await Share.shareXFiles([XFile(file.path)], text: 'Verified Drivers Collection & Attendance Report');
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating report: $e")));
      }
    }
  }

  Widget _sectionLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w900,
      color: deepForest,
      letterSpacing: 1,
    ),
  );
}
