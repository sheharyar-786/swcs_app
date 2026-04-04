import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';
import 'nearby_bins_page.dart'; // Naya page import kiya

class CivillianPage extends StatefulWidget {
  const CivillianPage({super.key});

  @override
  State<CivillianPage> createState() => _CivillianPageState();
}

class _CivillianPageState extends State<CivillianPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);

  String userName = "Citizen";

  // Reporting Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}/name');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() => userName = snapshot.value.toString());
      }
    }
  }

  // --- BACKEND LOGIC: SUBMIT REPORT ---
  Future<void> _submitDetailedReport(String type) async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _msg("Please provide Name and Phone", Colors.redAccent);
      return;
    }

    final String reportId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseDatabase.instance.ref('citizen_reports/$reportId').set({
      "user": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      "area": _addressController.text.trim(),
      "type": type,
      "comment": _commentController.text.trim(),
      "timestamp": ServerValue.timestamp,
      "status": "Pending",
    });

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _commentController.clear();

    Navigator.pop(context);
    _msg("Report Sent Successfully! ✅", leafGreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );

          Map data = snapshot.data!.snapshot.value as Map;
          Map schedules = data['schedules'] ?? {};
          Map bins = data['bins'] ?? {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. PARALLAX HEADER
              SliverAppBar(
                expandedHeight: 220.0,
                pinned: true,
                backgroundColor: leafGreen,
                elevation: 10,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () => _logout(context),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    "Hello, $userName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=1000',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              leafGreen.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. MAIN CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("Quick Report", "📢"),
                      const SizedBox(height: 12),
                      _buildReportGrid(),
                      const SizedBox(height: 35),

                      // --- UPDATED NEARBY BINS SECTION ---
                      _sectionHeader("Nearby Smart Bins", "📡"),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NearbyBinsPage(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: leafGreen.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: softMint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_outlined,
                                  color: leafGreen,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Track Area Bins",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "Real-time sensor monitoring",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader("Area Schedules", "📅"),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ScheduleExplorer(allData: data),
                              ),
                            ),
                            child: const Text(
                              "See More",
                              style: TextStyle(
                                color: leafGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildScheduleMiniGrid(schedules),
                      const SizedBox(height: 35),

                      _buildEmergencyCard(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _sectionHeader(String title, String emoji) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: deepForest,
        ),
      ),
    ],
  );

  Widget _buildReportGrid() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 3,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: 0.85,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _reportOption("Overflow", "🗑️", Colors.orange),
      _reportOption("Missed", "🚚", Colors.blue),
      _reportOption("Damage", "🛠️", Colors.redAccent),
    ],
  );

  Widget _reportOption(String t, String emoji, Color c) => InkWell(
    onTap: () => _showReportingDialog(t),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: c.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 35)),
          const SizedBox(height: 8),
          Text(
            t,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: deepForest,
            ),
          ),
        ],
      ),
    ),
  );

  void _showReportingDialog(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 25,
          right: 25,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Report $type",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: deepForest,
                ),
              ),
              const SizedBox(height: 15),
              _formField(_nameController, "Your Name", Icons.person),
              _formField(_phoneController, "Phone Number", Icons.phone),
              _formField(_addressController, "Area/Address", Icons.location_on),
              _formField(
                _commentController,
                "What's the issue?",
                Icons.chat,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leafGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => _submitDetailedReport(type),
                  child: const Text(
                    "SUBMIT REPORT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController c,
    String h,
    IconData i, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: h,
        prefixIcon: Icon(i, color: leafGreen),
        filled: true,
        fillColor: softMint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildScheduleMiniGrid(Map schedules) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
    ),
    itemCount: schedules.length > 4 ? 4 : schedules.length,
    itemBuilder: (context, index) {
      var s = schedules.values.toList()[index];
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: softMint, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "🏠 ${s['area']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 5),
            Text(
              "🕒 ${s['time']}",
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildEmergencyCard() => Container(
    padding: const EdgeInsets.all(25),
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [deepForest, leafGreen]),
      borderRadius: BorderRadius.circular(25),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Emergency Pickup",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text("Call: 1122", style: TextStyle(color: Colors.white70)),
          ],
        ),
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.phone_enabled, color: Colors.white),
        ),
      ],
    ),
  );

  void _msg(String m, Color c) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _logout(context) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (c) => const AuthPage()),
  );
}

// --- EXPLORER PAGE (STABLE RATING VERSION) ---
class ScheduleExplorer extends StatefulWidget {
  final Map allData;
  const ScheduleExplorer({super.key, required this.allData});

  @override
  State<ScheduleExplorer> createState() => _ScheduleExplorerState();
}

class _ScheduleExplorerState extends State<ScheduleExplorer> {
  String query = "";
  double rating = 0; // Global current rating

  @override
  Widget build(BuildContext context) {
    Map schedules = widget.allData['schedules'] ?? {};
    Map drivers = widget.allData['verified_drivers'] ?? {};
    var list = schedules.values
        .where(
          (s) =>
              s['area'].toString().toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "🔍 Area Explorer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: "Search your area...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4CAF50)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                var s = list[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE8F5E9), width: 2),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      onExpansionChanged: (bool expanded) {
                        if (expanded) setState(() => rating = 0);
                      },
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Text("🏙️"),
                      ),
                      title: Text(
                        s['area'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("⏰ ${s['day']} at ${s['time']}"),
                      children: [_buildDetails(s, drivers)],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Map s, Map drivers) {
    String collectorEmail = s['collector'] ?? "Not Assigned";
    var driverEntry = drivers.entries.firstWhere(
      (d) =>
          d.value['email'].toString().toLowerCase() ==
          collectorEmail.toLowerCase(),
      orElse: () => const MapEntry("", {}),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFBFDFB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          _detailRow(Icons.person_pin_rounded, "Collector: $collectorEmail"),
          _detailRow(
            Icons.stars_rounded,
            "Current Points: ${driverEntry.key.isNotEmpty ? driverEntry.value['points'] ?? 0 : 'N/A'}",
          ),
          const SizedBox(height: 15),
          const Text(
            "Rate Service Quality:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    rating = i + 1.0;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _updatePoints(
                  driverEntry.key,
                  this.rating,
                ); // FIX: Stable rating passing
              },
              child: const Text(
                "Submit Feedback",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePoints(String uid, double r) async {
    if (uid.isEmpty || r == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a star rating first! ⚠️"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int pts = (r * 50).toInt();

    try {
      await FirebaseDatabase.instance
          .ref('verified_drivers/$uid/last_rating_received')
          .set(r);

      await FirebaseDatabase.instance
          .ref('latest_activity')
          .set("Citizen gave $r stars to a collector! ⭐");

      await FirebaseDatabase.instance
          .ref('verified_drivers/$uid')
          .runTransaction((Object? post) {
            if (post == null) return Transaction.abort();
            Map d = Map<String, dynamic>.from(post as Map);
            d['points'] = (d['points'] ?? 0) + pts;
            return Transaction.success(d);
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Awesome! Feedback sent and Driver rewarded. 🌟🏆"),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => rating = 0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sync Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _detailRow(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(i, size: 18, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 12),
        Text(t, style: const TextStyle(color: Colors.black87)),
      ],
    ),
  );
}
