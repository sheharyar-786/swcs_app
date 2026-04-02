import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/bin_card.dart';
import '../auth/login_screen.dart';

class CivillianPage extends StatefulWidget {
  const CivillianPage({super.key});

  @override
  State<CivillianPage> createState() => _CivillianPageState();
}

class _CivillianPageState extends State<CivillianPage> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  String _searchQuery = "";
  double collectorRating = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // --- Logic: Submit Rating and Update Driver Points ---
  Future<void> _submitRating(String driverUid, double rating) async {
    if (rating == 0) return;
    int pointsToAdd = (rating * 50).toInt();
    final driverRef = FirebaseDatabase.instance.ref(
      'verified_drivers/$driverUid',
    );

    await driverRef.runTransaction((Object? post) {
      if (post == null) return Transaction.abort();
      Map<String, dynamic> driverData = Map<String, dynamic>.from(post as Map);
      driverData['points'] = (driverData['points'] ?? 0) + pointsToAdd;
      return Transaction.success(driverData);
    });

    setState(() => collectorRating = rating);
    _msg("Thanks! Driver awarded $pointsToAdd points. 🌟", leafGreen);
  }

  // --- Logic: Send Detailed Report to Admin ---
  Future<void> _submitDetailedReport(String type) async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _msg("Please provide your Name and Phone", Colors.redAccent);
      return;
    }

    final String reportId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseDatabase.instance.ref('citizen_reports/$reportId').set({
      "user": _nameController.text,
      "phone": _phoneController.text,
      "address": _addressController.text,
      "type": type,
      "comment": _commentController.text,
      "area": _addressController.text.isEmpty
          ? "General"
          : _addressController.text,
      "timestamp": ServerValue.timestamp,
      "status": "Pending",
    });

    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _commentController.clear();

    Navigator.pop(context);
    _msg("Report Sent Successfully! Admin will contact you.", leafGreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "🌿 Citizen Hub",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: leafGreen,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _navigateLogout(context),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref().onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          Map? allData = snapshot.data?.snapshot.value as Map?;
          Map bins = allData?['bins'] ?? {};
          Map schedules = allData?['schedules'] ?? {};
          Map drivers = allData?['verified_drivers'] ?? {};

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildWelcomeHeader(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 25),
                      _sectionHeader(
                        "Quick Report",
                        Icons.report_gmailerrorred_rounded,
                      ),
                      _buildReportGrid(),
                      const SizedBox(height: 25),

                      if (_searchQuery.isNotEmpty) ...[
                        _sectionHeader("Area Collector", Icons.stars_rounded),
                        _buildCollectorSection(drivers, schedules),
                        const SizedBox(height: 25),
                      ],

                      _sectionHeader("Smart Bin Status", Icons.sensors_rounded),
                      _buildLiveBinList(bins),
                      const SizedBox(height: 25),
                      _sectionHeader("Area Schedule", Icons.calendar_month),
                      _buildLiveScheduleList(schedules),
                      const SizedBox(height: 30),
                      _buildContactCard(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectorSection(Map drivers, Map schedules) {
    var activeSchedule = schedules.values.firstWhere(
      (s) => s['area'].toString().toLowerCase().contains(_searchQuery),
      orElse: () => null,
    );

    if (activeSchedule == null) return const SizedBox();
    String collectorName = activeSchedule['collector'] ?? "";

    var assignedDriver = drivers.values.firstWhere(
      (d) => d['email'].toString().toUpperCase().contains(
        collectorName.toUpperCase(),
      ),
      orElse: () => null,
    );

    if (assignedDriver == null)
      return _infoBox("Waiting for Admin to assign collector...");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: leafGreen,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collectorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: deepForest,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Collector for ${activeSchedule['area']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: leafGreen),
            ],
          ),
          const Divider(height: 25),
          const Text(
            "Rate this collector to award points:",
            style: TextStyle(
              color: deepForest,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => _submitRating(assignedDriver['uid'], i + 1.0),
                icon: Icon(
                  i < collectorRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBinList(Map binsData) {
    var filteredBins = binsData.entries
        .where(
          (e) => (e.value['area'] ?? "").toString().toLowerCase().contains(
            _searchQuery,
          ),
        )
        .toList();
    if (filteredBins.isEmpty)
      return _infoBox("No bins found in '$_searchQuery'");

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filteredBins.map((e) {
          int fillLevel = e.value['fill_level'] ?? 0;
          double progress = (fillLevel / 100).toDouble();
          Color statusColor = fillLevel >= 80 ? Colors.redAccent : leafGreen;

          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: deepForest,
                      ),
                    ),
                    Icon(Icons.circle, color: statusColor, size: 12),
                  ],
                ),
                Text(
                  e.value['area'] ?? "Location",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  "$fillLevel% Full",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: softMint,
                  color: statusColor,
                  minHeight: 8,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLiveScheduleList(Map schedules) {
    var filtered = schedules.values
        .where((s) => s['area'].toString().toLowerCase().contains(_searchQuery))
        .toList();
    if (filtered.isEmpty) return _infoBox("No schedules for this area.");
    return Column(
      children: filtered
          .map((s) => _scheduleTile(s['area'], "${s['day']} • ${s['time']}"))
          .toList(),
    );
  }

  Widget _buildWelcomeHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    color: leafGreen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hello, Sheharyar!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _searchQuery.isEmpty
              ? "Let's keep Sadiqabad clean today."
              : "Searching in: $_searchQuery",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    ),
  );

  Widget _buildSearchBar() => TextField(
    controller: _searchController,
    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
    decoration: InputDecoration(
      hintText: "Enter your area name...",
      prefixIcon: const Icon(Icons.search, color: leafGreen),
      filled: true,
      fillColor: softMint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _sectionHeader(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 15, top: 10),
    child: Row(
      children: [
        Icon(icon, color: deepForest, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: deepForest,
          ),
        ),
      ],
    ),
  );

  Widget _buildReportGrid() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.85,
    children: [
      _reportOption("Overflow", Icons.delete_forever, Colors.orange),
      _reportOption("Missed", Icons.moped_rounded, Colors.blue),
      _reportOption("Damage", Icons.build_circle, Colors.redAccent),
    ],
  );

  Widget _reportOption(String title, IconData icon, Color color) =>
      GestureDetector(
        onTap: () => _showReportingDialog(title),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: deepForest,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _scheduleTile(String area, String dateTime) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: softMint),
    ),
    child: Row(
      children: [
        const Icon(Icons.timer_outlined, color: leafGreen),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              area,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: deepForest,
              ),
            ),
            Text(
              dateTime,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildContactCard() => Container(
    padding: const EdgeInsets.all(20),
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [deepForest, leafGreen]),
      borderRadius: BorderRadius.circular(25),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Need Emergency Pickup?",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          "Call: 1122 (Toll Free)",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );

  void _msg(String m, Color c) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  void _navigateLogout(BuildContext context) => Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const AuthPage()),
    (route) => false,
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
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Report $type",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: deepForest,
                ),
              ),
              const SizedBox(height: 15),
              _formField(
                _nameController,
                "Your Full Name",
                Icons.person_outline,
              ),
              _formField(
                _phoneController,
                "Mobile Number",
                Icons.phone_android_outlined,
              ),
              _formField(
                _addressController,
                "Street Address",
                Icons.location_on_outlined,
              ),
              _formField(
                _commentController,
                "What's the issue?",
                Icons.chat_bubble_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => _submitDetailedReport(type),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: leafGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "SEND TO ADMIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: leafGreen),
          filled: true,
          fillColor: softMint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        msg,
        style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    ),
  );
}
