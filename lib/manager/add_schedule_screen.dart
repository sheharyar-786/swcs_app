import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';

class AddScheduleScreen extends StatefulWidget {
  final dynamic existingData;
  const AddScheduleScreen({super.key, this.existingData});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  static const Color leafGreen = Color(0xFF2E7D32);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFF1F8E9);


  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String? _selectedDriverEmail;
  String? _selectedDriverName;
  String? _selectedDriverUid;
  List<String> _selectedDays = [];
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSaving = false;

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
      _latController.text = widget.existingData['lat']?.toString() ?? "";
      _lngController.text = widget.existingData['lng']?.toString() ?? "";
      _selectedDriverEmail = widget.existingData['driver_email'];
      _selectedDriverName = widget.existingData['collector'];
      _selectedDriverUid = widget.existingData['assigned_to'];

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

  void _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
      });
      _showMsg("Location Locked 📍", Colors.blue);
    }
  }

  Future<void> _saveToFirebase() async {
    if (_areaController.text.isEmpty ||
        _selectedDriverEmail == null ||
        _latController.text.isEmpty ||
        _lngController.text.isEmpty ||
        _selectedDays.isEmpty) {
      _showMsg("Please complete all mission details!", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    final String scheduleId = widget.existingData != null
        ? widget.existingData['id']
        : DateTime.now().millisecondsSinceEpoch.toString();

    String daysString = _selectedDays.join(", ");

    try {
      await FirebaseDatabase.instance.ref('schedules/$scheduleId').update({
        "id": scheduleId,
        "area": _areaController.text.trim(),
        "lat": double.tryParse(_latController.text.trim()) ?? 0.0,
        "lng": double.tryParse(_lngController.text.trim()) ?? 0.0,
        "driver_email": _selectedDriverEmail,
        "collector": _selectedDriverName,
        "assigned_to": _selectedDriverUid,
        "day": daysString,
        "time": _selectedTime.format(context),
        "status": widget.existingData != null
            ? widget.existingData['status']
            : "Active",
        "updatedAt": ServerValue.timestamp,
      });

      await FirebaseDatabase.instance
          .ref('latest_activity')
          .set("Schedule Configured: ${_areaController.text}");

      if (mounted) {
        Navigator.pop(context);
        _showMsg(
          widget.existingData != null ? "Duty Updated! ✨" : "Schedule Live! ✅",
          leafGreen,
        );
      }
    } catch (e) {
      _showMsg("Error syncing mission: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMsg(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          m,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        backgroundColor: c,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: leafGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existingData != null
                  ? "Modify Schedule"
                  : "New Duty Setup",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: deepForest,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 25),

            _inputLabel("ZONE / AREA NAME"),
            TextField(
              controller: _areaController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: _inputStyle(
                "e.g. Sadiqabad Block-5",
                Icons.location_on_rounded,
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_inputLabel("GPS COORDINATES"), _buildMapPickerLink()],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle("Latitude", Icons.gps_fixed),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: TextInputType.number,
                    decoration: _inputStyle("Longitude", Icons.gps_fixed),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            _inputLabel("ASSIGN FIELD OFFICER"),
            _buildDriverDropdown(),

            const SizedBox(height: 25),
            _inputLabel("OPERATIONAL DAYS"),
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

  Widget _buildMapPickerLink() {
    return InkWell(
      onTap: _openMapPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.map_rounded, size: 14, color: Colors.blue),
            SizedBox(width: 6),
            Text(
              "OPEN MAP",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDropdown() {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('verified_drivers').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator(color: leafGreen);
        }
        Map drivers = (snapshot.data?.snapshot.value as Map?) ?? {};
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            color: softMint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text(
                "Select Field Officer",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              value: _selectedDriverEmail,
              isExpanded: true,
              items: drivers.entries.map((e) {
                var d = e.value;
                return DropdownMenuItem<String>(
                  value: d['email'],
                  onTap: () {
                    _selectedDriverName = d['name'];
                    _selectedDriverUid = e.key;
                  },
                  child: Text(
                    d['name'] ?? "Driver",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: deepForest,
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          selected: isSelected,
          selectedColor: leafGreen,
          checkmarkColor: Colors.white,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? leafGreen : Colors.grey.shade300,
            ),
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
          border: Border.all(color: leafGreen.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_filled_rounded, color: leafGreen),
            const SizedBox(width: 15),
            Text(
              _selectedTime.format(context),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: deepForest,
              ),
            ),
            const Spacer(),
            const Text(
              "SET TIME",
              style: TextStyle(
                color: leafGreen,
                fontWeight: FontWeight.w900,
                fontSize: 11,
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
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepForest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: deepForest.withValues(alpha: 0.4),
        ),
        onPressed: _isSaving ? null : _saveToFirebase,
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                widget.existingData != null
                    ? "UPDATE MISSION"
                    : "ACTIVATE MISSION",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _inputLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
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
    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
    prefixIcon: Icon(icon, color: leafGreen, size: 20),
    filled: true,
    fillColor: softMint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 15),
  );
}
