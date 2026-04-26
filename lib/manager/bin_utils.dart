/// bin_utils.dart
/// Utility to safely extract bin fields from Firebase data.
/// Supports both nested IoT structure (readings/*, metadata/*)
/// and flat top-level structure for backwards compatibility.

class BinData {
  static double fillLevel(dynamic data) {
    if (data == null) return 0.0;
    var val = (data['readings'] != null ? data['readings']['fill_level'] : null) ??
        data['fill_level'] ??
        0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int gasLevel(dynamic data) {
    if (data == null) return 0;
    var val = (data['readings'] != null ? data['readings']['gas_level'] : null) ??
        data['gas_level'] ??
        0;
    return int.tryParse(val.toString()) ?? 0;
  }

  static dynamic battery(dynamic data) {
    if (data == null) return null;
    return (data['readings'] != null ? data['readings']['battery_level'] : null) ??
        data['battery'] ??
        data['battery_level'];
  }

  static String area(dynamic data) {
    if (data == null) return "Unknown";
    return (data['metadata'] != null ? data['metadata']['area']?.toString() : null) ??
        data['area']?.toString() ??
        "Unknown Location";
  }

  static String status(dynamic data) {
    if (data == null) return "Unknown";
    return (data['metadata'] != null ? data['metadata']['status']?.toString() : null) ??
        data['status']?.toString() ??
        "Unknown";
  }

  static double lat(dynamic data) {
    if (data == null) return 0.0;
    final loc = data['metadata']?['location'];
    return double.tryParse((loc != null ? loc['lat'] : null)?.toString() ??
            data['lat']?.toString() ??
            "0.0") ??
        0.0;
  }

  static double lng(dynamic data) {
    if (data == null) return 0.0;
    final loc = data['metadata']?['location'];
    return double.tryParse((loc != null ? loc['lng'] : null)?.toString() ??
            data['lng']?.toString() ??
            "0.0") ??
        0.0;
  }

  static String batteryDisplay(Map data) {
    final b = battery(data);
    return b == null ? "N/A" : "$b%";
  }

  // ── ONLINE / OFFLINE PRESENCE ─────────────────────────────────────────────
  // Returns true if ESP32 sent data within the last 5 minutes.
  static bool isOnline(dynamic data) {
    if (data == null) return false;
    final ts = (data['metadata'] != null ? data['metadata']['last_sync'] : null) ??
        data['last_sync'];
    if (ts == null) return false;
    try {
      final lastSync = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());
      return DateTime.now().difference(lastSync).inMinutes < 5;
    } catch (_) {
      return false;
    }
  }

  // Returns "Online" or "Offline" based on last_sync timestamp.
  static String connectionStatus(Map data) =>
      isOnline(data) ? "Online" : "Offline";
}

