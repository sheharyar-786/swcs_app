import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ReportCenter extends StatelessWidget {
  const ReportCenter({super.key, this.globalStream});
  final Stream<DatabaseEvent>? globalStream;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAF9),
        body: Column(
          children: [
            /// Premium Header (Safe Design - Square)
            Container(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'lib/assets/bg.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0A714E)),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            const Color(0xFF0A714E).withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            "REPORT CENTER",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Info Bar (Statement Bar)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A714E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment_outlined, color: Color(0xFF0A714E), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Monitor and resolve citizen grievances and public reports.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A714E)),
                    ),
                  ),
                ],
              ),
            ),

            /// Tabs
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: const TabBar(
                labelColor: Color(0xFF0A714E),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF0A714E),
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: "PENDING"),
                  Tab(text: "RESOLVED"),
                ],
              ),
            ),

            /// Data Content
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref().onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0A714E)));
                  }
                  
                  final data = Map<String, dynamic>.from(snapshot.data?.snapshot.value as Map? ?? {});
                  final pending = Map<String, dynamic>.from(data['citizen_reports'] as Map? ?? {});
                  final resolved = Map<String, dynamic>.from(data['resolved_reports'] as Map? ?? {});

                  return TabBarView(
                    children: [
                      _buildReportList(pending, false),
                      _buildReportList(resolved, true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(Map<String, dynamic> reports, bool isResolved) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No ${isResolved ? 'resolved' : 'pending'} reports", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final list = reports.entries.toList();
    list.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final report = Map<String, dynamic>.from(list[index].value as Map);
        final date = DateFormat("dd MMM, hh:mm a").format(
          DateTime.fromMillisecondsSinceEpoch(report['timestamp'] ?? 0),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(report['type'] ?? "General", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  _statusChip(isResolved),
                ],
              ),
              const SizedBox(height: 10),
              Text(report['comment'] ?? "No details provided.", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              const Divider(height: 30),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF0A714E)),
                  const SizedBox(width: 5),
                  Expanded(child: Text(report['area'] ?? "Unknown", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text("Reported by: ${report['user'] ?? 'Anonymous'}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic)),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(bool resolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: resolved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        resolved ? "RESOLVED" : "PENDING",
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: resolved ? Colors.green : Colors.red),
      ),
    );
  }
}
