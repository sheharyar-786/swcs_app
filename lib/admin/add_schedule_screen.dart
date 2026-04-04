import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddScheduleScreen extends StatefulWidget {
  final dynamic existingData;
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
  String? _selectedDriverName;
  List<String> _selectedDays = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSaving = false; // Loading state for sync fix

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
      _selectedDriverEmail = widget.existingData['driver_email'];
      _selectedDriverName = widget.existingData['collector'];

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

  Future<void> _saveToFirebase() async {
    if (_areaController.text.isEmpty ||
        _selectedDriverEmail == null ||
        _selectedDays.isEmpty) {
      _showMsg("Please fill all fields!", Colors.orange);
      return;
    }

    setState(() => _isSaving = true); // Start loading

    final String scheduleId = widget.existingData != null
        ? widget.existingData['id']
        : DateTime.now().millisecondsSinceEpoch.toString();

    String daysString = _selectedDays.join(", ");

    try {
      // Async update ensures Firebase handles the request properly before UI pops
      await FirebaseDatabase.instance.ref('schedules/$scheduleId').update({
        "id": scheduleId,
        "area": _areaController.text.trim(),
        "driver_email": _selectedDriverEmail,
        "collector": _selectedDriverName,
        "day": daysString,
        "time": _selectedTime.format(context),
        "status": widget.existingData != null
            ? widget.existingData['status']
            : "Active",
        "updatedAt": ServerValue.timestamp,
      });

      if (mounted) {
        Navigator.pop(context); // Close sheet
        _showMsg(
          widget.existingData != null
              ? "Duty Updated! ✨"
              : "Schedule Created! ✅",
          leafGreen,
        );
      }
    } catch (e) {
      _showMsg("Error saving data: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMsg(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              widget.existingData != null
                  ? "Update Schedule"
                  : "Create New Schedule",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: deepForest,
              ),
            ),
            const SizedBox(height: 30),

            _inputLabel("ZONE / AREA NAME"),
            TextField(
              controller: _areaController,
              decoration: _inputStyle(
                "Enter street or block name",
                Icons.map_rounded,
              ),
            ),

            const SizedBox(height: 25),
            _inputLabel("ASSIGN FIELD OFFICER"),
            _buildDriverDropdown(),

            const SizedBox(height: 25),
            _inputLabel("SELECT OPERATIONAL DAYS"),
            _buildDaysWrap(),

            const SizedBox(height: 25),
            _inputLabel("COLLECTION WINDOW"),
            _buildTimePicker(),

            const SizedBox(height: 40),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDropdown() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        Map drivers = (snapshot.data?.snapshot.value as Map?) ?? {};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: softMint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text(
                "Choose an Active Driver",
                style: TextStyle(fontSize: 14),
              ),
              value: _selectedDriverEmail,
              isExpanded: true,
              items: drivers.values.map((d) {
                String name =
                    d['name'] ??
                    d['email'].toString().split('@')[0].toUpperCase();
                return DropdownMenuItem<String>(
                  value: d['email'],
                  onTap: () => _selectedDriverName = name,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDriverEmail = val),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaysWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _days.map((day) {
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(
            day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          selected: isSelected,
          selectedColor: leafGreen,
          checkmarkColor: Colors.white,
          backgroundColor: softMint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (bool selected) {
            setState(() {
              selected ? _selectedDays.add(day) : _selectedDays.remove(day);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: softMint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: leafGreen),
            const SizedBox(width: 15),
            Text(
              _selectedTime.format(context),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            const Text(
              "EDIT",
              style: TextStyle(
                color: leafGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepForest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        onPressed: _isSaving ? null : _saveToFirebase,
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.existingData != null
                    ? "UPDATE MISSION"
                    : "CONFIRM MISSION",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 10,
        color: Colors.blueGrey,
        letterSpacing: 1,
      ),
    ),
  );

  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: leafGreen),
    filled: true,
    fillColor: softMint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}
