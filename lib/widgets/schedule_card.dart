import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String area;
  final String day;
  final String time;
  final String status; // --- NEW: To track if duty is done ---
  final VoidCallback? onEdit;
  final int index;

  const ScheduleCard({
    super.key,
    required this.area,
    required this.day,
    required this.time,
    this.status = "Active", // Default status
    required this.index,
    this.onEdit,
  });

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color alertBlue = Color(0xFF2196F3); // Color for completed tasks

  @override
  Widget build(BuildContext context) {
    // Dynamic color based on status
    bool isCompleted = status.toLowerCase() == "completed";
    Color themeColor = isCompleted ? alertBlue : leafGreen;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Side accent bar changes color based on status
                Container(width: 10, color: themeColor),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // FIXED: Added Flexible for Area Name to prevent overflow
                            Flexible(
                              child: Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: deepForest,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ), // Gap between area and status
                            // --- Status Chip ---
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // FIXED: Wrapped the Row in a Wrap or used Expanded inside to prevent text overflow
                        Wrap(
                          spacing: 15,
                          runSpacing: 8,
                          children: [
                            _buildInfoRow(
                              Icons.calendar_today_rounded,
                              day,
                              themeColor,
                            ),
                            _buildInfoRow(
                              Icons.access_time_filled_rounded,
                              time,
                              themeColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (onEdit != null && !isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CircleAvatar(
                      backgroundColor: softMint,
                      radius: 18, // Slightly smaller to save space
                      child: IconButton(
                        iconSize: 20,
                        icon: Icon(Icons.edit_note_rounded, color: themeColor),
                        onPressed: onEdit,
                      ),
                    ),
                  ),

                // Show a checkmark if completed
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 15.0),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: alertBlue,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    // FIXED: Added Row with mainAxisSize.min to allow Wrap to work correctly
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        // Flexible allows long strings like "Monday, Tuesday, Saturday" to stay safe
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
