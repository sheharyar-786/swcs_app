import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String area;
  final String day;
  final String time;
  final String status;
  final String? assignedDriver;
  final VoidCallback? onEdit;
  final int index;

  const ScheduleCard({
    super.key,
    required this.area,
    required this.day,
    required this.time,
    this.status = "Active",
    this.assignedDriver,
    required this.index,
    this.onEdit,
  });

  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color deepForest = Color(0xFF1B5E20);
  static const Color softMint = Color(0xFFE8F5E9);
  static const Color alertBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    bool isCompleted = status.toLowerCase() == "completed";
    Color themeColor = isCompleted ? alertBlue : leafGreen;

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutQuart,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(30 * (1 - animValue), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: themeColor.withValues(alpha: 0.12), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              // Decorative Background Accent
              Positioned(
                right: -15,
                top: -15,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: themeColor.withValues(alpha: 0.04),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Icon Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.task_alt_rounded
                                : Icons.schedule_send_rounded,
                            color: themeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                area,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: deepForest,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              _statusBadge(status, themeColor),
                            ],
                          ),
                        ),

                        if (onEdit != null && !isCompleted)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: Color(0xFFF5F5F5)),
                    ),

                    // INFO ROW: Fixed the Overflow here
                    Row(
                      children: [
                        // Calendar Icon and Days (Expanded to prevent overflow)
                        Expanded(
                          flex: 3,
                          child: _miniInfo(
                            Icons.calendar_month_outlined,
                            day,
                            themeColor,
                            isFlexible: true,
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Time Info (Fixed width to ensure it is always visible)
                        _miniInfo(
                          Icons.access_time_rounded,
                          time,
                          themeColor,
                          isFlexible: false,
                        ),

                        // Driver Info (Only if assigned)
                        if (assignedDriver != null) ...[
                          const SizedBox(width: 10),
                          _driverChip(assignedDriver!, themeColor),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _miniInfo(
    IconData icon,
    String text,
    Color color, {
    required bool isFlexible,
  }) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 5),
        isFlexible
            ? Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis, // Fixes the 73 pixel overflow
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade600,
                ),
              ),
      ],
    );

    return isFlexible ? Row(children: [Expanded(child: content)]) : content;
  }

  Widget _driverChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_pin_circle_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
