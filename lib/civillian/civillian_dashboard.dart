import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/login_screen.dart';
import 'nearby_bins_page.dart';

class CivillianPage extends StatefulWidget {
  const CivillianPage({super.key});

  @override
  State<CivillianPage> createState() => _CivillianPageState();
}

class _CivillianPageState extends State<CivillianPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

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
      final snapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}/name')
          .get();
      if (snapshot.exists) {
        setState(() => userName = snapshot.value.toString());
      }
    }
  }

  Future<void> _submitDetailedReport(String type) async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _msg("Please provide Name and Phone", Colors.redAccent);
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final String reportId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseDatabase.instance.ref('citizen_reports/$reportId').set({
      "user": _nameController.text.trim(),
      "phone": _phoneController.text.trim(),
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
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Report Sent! Admin will take action. ✅"),
        backgroundColor: leafGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: leafGreen),
            );
          }

          Map data = snapshot.data!.snapshot.value as Map? ?? {};
          Map schedules = data['schedules'] ?? {};

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildParallaxHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("Quick Report", "📢"),
                      const SizedBox(height: 15),
                      _buildReportGrid(),
                      const SizedBox(height: 35),
                      _sectionHeader("Nearby Smart Bins", "📡"),
                      const SizedBox(height: 15),
                      _buildTrackBinCard(),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader("Area Schedules", "📅"),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => ScheduleExplorer(allData: data),
                              ),
                            ),
                            child: const Text(
                              "See More",
                              style: TextStyle(
                                color: leafGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildScheduleMiniGrid(schedules),
                      const SizedBox(height: 30),
                      _buildEmergencyCard(),
                      const SizedBox(height: 100),
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

  Widget _buildParallaxHeader() => SliverAppBar(
    expandedHeight: 220.0,
    pinned: true,
    backgroundColor: leafGreen,
    elevation: 10,
    // Ensure the title is not centered by the system
    centerTitle: false,
    actions: [
      IconButton(
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        onPressed: () => _logout(context),
      ),
    ],
    flexibleSpace: FlexibleSpaceBar(
      // Ensure left alignment during expansion/contraction
      centerTitle: false,
      // Padding ensures the text aligns with your grid content below
      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      title: Text(
        "Hello, $userName",
        // Force single line and add "..." if name is too long
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
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
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  leafGreen.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _buildReportGrid() => Row(
    children: [
      Expanded(child: _reportOption("Overflow", "🗑️", Colors.orange)),
      const SizedBox(width: 10),
      Expanded(child: _reportOption("Missed", "🚚", Colors.blue)),
      const SizedBox(width: 10),
      Expanded(child: _reportOption("Damage", "🛠️", Colors.redAccent)),
    ],
  );

  Widget _reportOption(String t, String emoji, Color c) => InkWell(
    onTap: () => _showReportingDialog(t),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 10)],
        border: Border.all(color: c.withValues(alpha: 0.1)),
      ),
      child: Column(
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

  Widget _buildTrackBinCard() => InkWell(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => const NearbyBinsPage()),
    ),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: leafGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: softMint,
            child: Icon(Icons.analytics_outlined, color: leafGreen),
          ),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Track Area Bins",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Real-time sensor monitoring",
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );

  Widget _buildScheduleMiniGrid(Map schedules) {
    var items = schedules.values.take(2).toList();
    return Column(
      children: items
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: softMint, width: 2),
              ),
              child: Row(
                children: [
                  const Text("🏠", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['area'] ?? "Unknown Area",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "🕒 ${s['time']}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmergencyCard() => Container(
    padding: const EdgeInsets.all(25),
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

  void _showReportingDialog(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(
          25,
          20,
          25,
          MediaQuery.of(c).viewInsets.bottom + 20,
        ),
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
              "Issue details...",
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
          ],
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
  Widget _sectionHeader(String t, String e) => Row(
    children: [
      Text(e, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Text(
        t,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: deepForest,
        ),
      ),
    ],
  );
  void _msg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
    ),
  );
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
  // LOGIC FIX: Stores independent rating for each area in the list
  Map<int, double> areaRatings = {};

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
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Text("🏙️"),
                    ),
                    title: Text(
                      s['area'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("⏰ ${s['day']} at ${s['time']}"),
                    children: [_buildRatingSection(s, drivers, index)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(Map s, Map drivers, int index) {
    // Determine the Collector
    String collectorEmail = s['driver_email'] ?? "Not Assigned";
    var driverEntry = drivers.entries.firstWhere(
      (d) =>
          d.value['email'].toString().toLowerCase() ==
          collectorEmail.toLowerCase(),
      orElse: () => const MapEntry("", {}),
    );

    double currentRating = areaRatings[index] ?? 0.0;

    return FutureBuilder<Position>(
      future: Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ),
      builder: (context, geoSnapshot) {
        if (!geoSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Verifying location... 🛰️",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        // GEOFENCE LOGIC
        double binLat = double.tryParse(s['lat']?.toString() ?? "0") ?? 28.3067;
        double binLng = double.tryParse(s['lng']?.toString() ?? "0") ?? 70.1411;
        double distance = Geolocator.distanceBetween(
          geoSnapshot.data!.latitude,
          geoSnapshot.data!.longitude,
          binLat,
          binLng,
        );

        bool isNear = distance <= 500; // 500 Meters Range

        return Container(
          padding: const EdgeInsets.all(20),
          color: const Color(0xFFFBFDFB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              _row(Icons.person, "Collector: $collectorEmail"),
              _row(
                Icons.location_on,
                "Distance: ${distance.toStringAsFixed(0)}m away",
              ),
              const SizedBox(height: 15),

              if (isNear) ...[
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
                        i < currentRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.orange,
                        size: 35,
                      ),
                      onPressed: () =>
                          setState(() => areaRatings[index] = i + 1.0),
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
                    onPressed: () => _updateDriverPoints(
                      driverEntry.key,
                      currentRating,
                      index,
                    ),
                    child: const Text(
                      "SUBMIT FEEDBACK",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "⚠️ Rating Locked: You must be in this area to provide feedback.",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDriverPoints(String uid, double r, int index) async {
    if (uid.isEmpty || r == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a star rating first! ⚠️"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Notify Driver (Triggers Confetti)
      await FirebaseDatabase.instance
          .ref('verified_drivers/$uid/last_rating_received')
          .set(r);
      // 2. Award XP Points
      int pts = (r * 50).toInt();
      await FirebaseDatabase.instance
          .ref('verified_drivers/$uid/points')
          .runTransaction((Object? post) {
            if (post == null) return Transaction.abort();
            int current = post as int? ?? 0;
            return Transaction.success(current + pts);
          });
      // 3. Update Admin Feed
      await FirebaseDatabase.instance
          .ref('latest_activity')
          .set("Citizen gave $r stars to a collector! ⭐");

      messenger.showSnackBar(
        const SnackBar(
          content: Text("Feedback Sent! Driver rewarded. 🌟🏆"),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => areaRatings[index] = 0); // Reset after success
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Widget _row(IconData i, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(i, size: 16, color: Colors.green),
        const SizedBox(width: 10),
        Text(t, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}
