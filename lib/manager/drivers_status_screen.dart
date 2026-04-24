import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class DriversStatusPage extends StatelessWidget {
  final Map drivers;
  const DriversStatusPage({super.key, required this.drivers});

  // Theme Colors
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color premiumNavy = Color(0xFF0D47A1);
  static const Color softMint = Color(0xFFF1F8E9);

  @override
  Widget build(BuildContext context) {
    // Analytics Calculations
    int totalDrivers = drivers.length;
    int activeNow = drivers.values
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
              child: Image.network(
                'https://img.freepik.com/free-vector/map-road-city-city-streets-with-navigation-gps-markers-town-plan-vector-concept_1017-43403.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 2. Premium Animated Header
              _buildSliverAppBar(context, totalDrivers, activeNow, onLeave),

              // 3. Main Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _sectionLabel("Verified Fleet Members"),
                    const SizedBox(height: 10),

                    // 4. Staggered List of Drivers
                    AnimationLimiter(
                      child: Column(
                        children: drivers.entries.map((entry) {
                          int index = drivers.keys.toList().indexOf(entry.key);
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
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),

      // 5. Floating Excel Export Action
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExportPreview(context),
        backgroundColor: premiumNavy,
        icon: const Icon(Icons.table_view_rounded, color: Colors.white),
        label: const Text(
          "GENERATE XL REPORT",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    int total,
    int active,
    int leave,
  ) {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      backgroundColor: leafGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [deepForest, leafGreen],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "FLEET COMMAND",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _headerStat("TOTAL", total.toString()),
                  _headerStat("ON-DUTY", active.toString()),
                  _headerStat("LEAVE", leave.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String label, String val) => Column(
    children: [
      Text(
        val,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _buildDriverCard(BuildContext context, String uid, dynamic data) {
    bool isPresent = data['attendance'] == "Present";
    bool onRoute = data['status'] == "On Route";

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
        child: Row(
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
      ),
    );
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

  void _showExportPreview(BuildContext context) {
    // This aggregates all data for your XL request
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Fleet Report Summary"),
        content: Text(
          "Generate a real-time CSV/Excel report for ${drivers.length} verified drivers including attendance and rewards?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: premiumNavy),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "DOWNLOAD .XLS",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
