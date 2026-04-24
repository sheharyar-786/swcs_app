import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class ReportCenter extends StatelessWidget {
  final Stream<DatabaseEvent> globalStream;

  const ReportCenter({super.key, required this.globalStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: globalStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0A714E))));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0A714E))));
        }

        Map allData = snapshot.data!.snapshot.value as Map;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAF9),
            body: Column(
              children: [
                _buildPremiumHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildReportList('Pending', allData), 
                      _buildReportList('Resolved', allData), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // --- UI Components ---

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A714E), Color(0xFF1E3C31)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Public Complaints",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Monitoring citizen reports & resolutions",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const TabBar(
        labelColor: Color(0xFF0A714E),
        unselectedLabelColor: Colors.grey,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 20),
        indicatorColor: Color(0xFF0A714E),
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Text(
              "PENDING",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Tab(
            child: Text(
              "RESOLVED",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(String filterTab, Map allData) {
    Map? reportsData;
    if (filterTab == 'Pending') {
      reportsData = allData['citizen_reports'] as Map?;
    } else {
      reportsData = allData['resolved_reports'] as Map?;
    }

    if (reportsData == null) return _buildEmptyState(filterTab);

    var filteredList = reportsData.entries.toList();
    if (filterTab == 'Pending') {
      filteredList = filteredList.where((e) {
        var val = e.value as Map;
        return val['status'] == 'Pending' || val['status'] == null;
      }).toList();
    }

    // Sorting latest first
    filteredList.sort((a, b) {
      int timeA = (a.value as Map)['timestamp'] ?? int.tryParse(a.key.toString()) ?? 0;
      int timeB = (b.value as Map)['timestamp'] ?? int.tryParse(b.key.toString()) ?? 0;
      return timeB.compareTo(timeA);
    });

    if (filteredList.isEmpty) return _buildEmptyState(filterTab);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var report = filteredList[index].value as Map;

        // Formatting Timestamp
        int ts = report['timestamp'] ?? int.tryParse(filteredList[index].key.toString()) ?? 0;
        DateTime date = DateTime.fromMillisecondsSinceEpoch(ts > 0 ? ts : DateTime.now().millisecondsSinceEpoch);
        String formattedDate = DateFormat('dd MMM, hh:mm a').format(date);

        String uiStatus = filterTab == 'Resolved' ? 'Resolved' : 'Pending';

              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: 50 * index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // SCREENSHOT FIX: Field 'type' used as title
                        Text(
                          report['type'] ?? "General",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // SCREENSHOT FIX: Field 'comment' used as description
                        Text(
                          report['comment'] ?? "No details provided.",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFF0A714E),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report['area'] ?? "Unknown Area",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildStatusChip(uiStatus),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Reported by: ${report['user'] ?? report['phone'] ?? 'N/A'}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          Text(
            "No $status reports",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'Pending'
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: status == 'Pending' ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}
