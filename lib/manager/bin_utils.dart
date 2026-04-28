/// bin_utils.dart
/// Utility to safely extract bin fields from Firebase data.
/// Supports both nested IoT structure (readings/*, metadata/*)
/// and flat top-level structure for backwards compatibility.

class BinData {
  // --- FILL LEVEL MAPPING ---
  static double fillLevel(dynamic data) {
    if (data == null) return 0.0;
    // Checks readings folder first, then fallback to root level
    var val =
        (data['readings'] != null ? data['readings']['fill_level'] : null) ??
        data['fill_level'] ??
        0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  // --- GAS LEVEL MAPPING ---
  static int gasLevel(dynamic data) {
    if (data == null) return 0;
    // Checks readings folder first, then fallback to root level
    var val =
        (data['readings'] != null ? data['readings']['gas_level'] : null) ??
        data['gas_level'] ??
        0;
    return int.tryParse(val.toString()) ?? 0;
  }

  // --- UPDATED BATTERY LOGIC (PRIORITIZE LIVE VALUE) ---
  static dynamic battery(dynamic data) {
    if (data == null) return null;

    // Checks for live battery_level key at root first, then readings folder
    return data['battery_level'] ??
        (data['readings'] != null ? data['readings']['battery_level'] : null) ??
        data['battery'];
  }

  // --- AREA / LOCATION MAPPING ---
  static String area(dynamic data) {
    if (data == null) return "Unknown";
    return (data['metadata'] != null
            ? data['metadata']['area']?.toString()
            : null) ??
        data['area']?.toString() ??
        "Unknown Location";
  }

  // --- STATUS MAPPING ---
  static String status(dynamic data) {
    if (data == null) return "Unknown";
    return (data['metadata'] != null
            ? data['metadata']['status']?.toString()
            : null) ??
        data['status']?.toString() ??
        "Unknown";
  }

  // --- COORDINATES MAPPING ---
  static double lat(dynamic data) {
    if (data == null) return 0.0;
    final loc = data['metadata']?['location'];
    return double.tryParse(
          (loc != null ? loc['lat'] : null)?.toString() ??
              data['lat']?.toString() ??
              "0.0",
        ) ??
        0.0;
  }

  static double lng(dynamic data) {
    if (data == null) return 0.0;
    final loc = data['metadata']?['location'];
    return double.tryParse(
          (loc != null ? loc['lng'] : null)?.toString() ??
              data['lng']?.toString() ??
              "0.0",
        ) ??
        0.0;
  }

  // --- DISPLAY FORMATTING ---
  static String batteryDisplay(Map data) {
    final b = battery(data);
    // Returns live battery percentage or N/A if missing
    return b == null ? "N/A" : "$b%";
  }

  // ── ONLINE / OFFLINE PRESENCE (UPDATED 10-MIN WINDOW) ───────────────────
  // Returns true if ESP32 sent data within the last 10 minutes.
  static bool isOnline(dynamic data) {
    if (data == null) return false;

    final ts =
        (data['metadata'] != null ? data['metadata']['last_sync'] : null) ??
        data['last_sync'];

    if (ts == null) return false;

    try {
      final lastSync = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());

      // Threshold set to 15 seconds for real-time testing (Switching off ESP shows Offline quickly)
      return DateTime.now().difference(lastSync).inSeconds < 15;
    } catch (_) {
      return false;
    }
  }

  // Returns "Online" or "Offline" based on last_sync timestamp.
  static String connectionStatus(Map data) =>
      isOnline(data) ? "Online" : "Offline";

  // Returns "X min ago" string
  static String lastSeenAgo(dynamic data) {
    if (data == null) return "Never";
    final ts = (data['metadata'] != null ? data['metadata']['last_sync'] : null) ?? data['last_sync'];
    if (ts == null) return "Never";
    try {
      final lastSync = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt());
      final diff = DateTime.now().difference(lastSync);
      if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";

      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "Error";
    }
  }
}

