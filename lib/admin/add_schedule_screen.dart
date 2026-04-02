import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddScheduleScreen extends StatefulWidget {
  final dynamic existingData; // --- NEW: To receive data for editing ---
  const AddScheduleScreen({super.key, this.existingData});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);

  final TextEditingController _areaController = TextEditingController();
  String? _selectedDriverEmail;
  String? _selectedDriverName; // Added to store display name
  List<String> _selectedDays = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _areaController.text = widget.existingData['area'] ?? "";
      _selectedDriverEmail =
          widget.existingData['driver_email']; // Using specific key
      _selectedDriverName =
          widget.existingData['collector']; // This links to Civilian Hub

      String daysStr = widget.existingData['day'] ?? "";
      if (daysStr.isNotEmpty) {
        _selectedDays = daysStr.split(", ").toList();
      }

      try {
        String timeStr = widget.existingData['time'];
        final format = RegExp(r'(\d+):(\d+)\s+(AM|PM)');
        final match = format.firstMatch(timeStr);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          String period = match.group(3)!;
          if (period == "PM" && hour < 12) hour += 12;
          if (period == "AM" && hour == 12) hour = 0;
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        debugPrint("Time parsing error: $e");
      }
    }
  }

  // --- FIXED: Now saves both Email and Display Name for Civilian Dashboard ---
  Future<void> _saveToFirebase() async {
    if (_areaController.text.isEmpty ||
        _selectedDriverEmail == null ||
        _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select at least one day"),
        ),
      );
      return;
    }

    final String scheduleId = widget.existingData != null
        ? widget.existingData['id']
        : DateTime.now().millisecondsSinceEpoch.toString();

    String daysString = _selectedDays.join(", ");

    await FirebaseDatabase.instance.ref('schedules/$scheduleId').update({
      "id": scheduleId,
      "area": _areaController.text,
      "driver_email": _selectedDriverEmail, // For backend reference
      "collector":
          _selectedDriverName, // --- FIXED: This key displays name on Civilian Hub ---
      "day": daysString,
      "time": _selectedTime.format(context),
      "status": widget.existingData != null
          ? widget.existingData['status']
          : "Active",
      "updatedAt": ServerValue.timestamp,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingData != null
              ? "Duty Updated! ✨"
              : "Schedule Created! ✅",
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: leafGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null
              ? "Edit Collection Duty"
              : "Create Collection Duty",
        ),
        backgroundColor: leafGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingData != null
                  ? "Update Duty Details"
                  : "Duty Details",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: deepForest,
              ),
            ),
            const SizedBox(height: 25),
            _inputLabel("Area/Street Name"),
            TextField(
              controller: _areaController,
              decoration: _inputStyle(
                "e.g. Model Town Block B",
                Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 20),
            _inputLabel("Assign Driver"),
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null)
                  return const Text("Loading drivers...");
                Map drivers = snapshot.data!.snapshot.value as Map;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: softMint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: const Text("Select Approved Driver"),
                      value: _selectedDriverEmail,
                      isExpanded: true,
                      items: drivers.values.map((d) {
                        String name = d['email']
                            .toString()
                            .split('@')[0]
                            .toUpperCase();
                        return DropdownMenuItem<String>(
                          value: d['email'],
                          child: Text(name),
                          onTap: () =>
                              _selectedDriverName = name, // Capture name on tap
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDriverEmail = val),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _inputLabel("Select Collection Days (Multi)"),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _days.map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: leafGreen.withOpacity(0.3),
                  checkmarkColor: leafGreen,
                  onSelected: (bool selected) {
                    setState(() {
                      selected
                          ? _selectedDays.add(day)
                          : _selectedDays.remove(day);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _inputLabel("Collection Time"),
            InkWell(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: softMint,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: leafGreen),
                    const SizedBox(width: 15),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      "Change",
                      style: TextStyle(
                        color: leafGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: leafGreen,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: _saveToFirebase,
              child: Text(
                widget.existingData != null
                    ? "UPDATE SCHEDULE"
                    : "CREATE SCHEDULE",
                style: const TextStyle(
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

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: leafGreen),
    filled: true,
    fillColor: softMint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );
}
