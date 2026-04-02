import 'package:flutter/material.dart';

class BinInfoCard extends StatelessWidget {
  final String binId;
  final double fillLevel; // Value between 0.0 and 1.0
  final String status;
  final String? area;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const BinInfoCard({
    super.key,
    required this.binId,
    required this.fillLevel,
    required this.status,
    this.area,
    this.actionLabel,
    this.onActionPressed,
  });

  // --- Theme Colors ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFD54F);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color deepForest = Color(0xFF1B5E20);

  // Updated Traffic Light Logic
  Color _getStatusColor() {
    if (fillLevel >= 0.9) return dangerRed; // Critical
    if (fillLevel >= 0.6) return warningYellow; // Warning
    return leafGreen; // Safe
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          25,
        ), // Cartoon-style rounded corners
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Section: ID and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      binId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: deepForest,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (area != null)
                      Text(
                        area!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
                _statusBadge(status, statusColor),
              ],
            ),
            const SizedBox(height: 20),

            // Middle Section: Thicker Progress Indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: fillLevel,
                          minHeight: 12, // Thicker for better visibility
                          backgroundColor: Colors.grey.shade100,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "${(fillLevel * 100).toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            // Bottom Section: Optional Action Button
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: onActionPressed,
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == warningYellow ? Colors.orange.shade700 : color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
