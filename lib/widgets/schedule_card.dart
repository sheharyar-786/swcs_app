import 'package:flutter/material.dart';

class ScheduleCard extends StatelessWidget {
  final String area;
  final String day;
  final String time;
  final String status;
  final String? assignedDriver; // NEW: Premium touch
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
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutQuart,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(40 * (1 - animValue), 0), // Side slide-in effect
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: themeColor.withOpacity(0.1), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // Premium Background Accent Bubble
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: themeColor.withOpacity(0.03),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic Leading Icon with Glow
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.verified_rounded
                                : Icons.pending_actions_rounded,
                            color: themeColor,
                            size: 24,
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: deepForest,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _statusBadge(status, themeColor),
                            ],
                          ),
                        ),

                        // Premium Edit Button
                        if (onEdit != null && !isCompleted)
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(height: 1, color: Color(0xFFF1F1F1)),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Time & Day Info with Icons
                        Row(
                          children: [
                            _miniInfo(
                              Icons.calendar_month_outlined,
                              day,
                              themeColor,
                            ),
                            const SizedBox(width: 15),
                            _miniInfo(
                              Icons.access_time_rounded,
                              time,
                              themeColor,
                            ),
                          ],
                        ),

                        // Assigned Driver (Mini Profile)
                        if (assignedDriver != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: themeColor,
                                  child: const Icon(
                                    Icons.person,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  assignedDriver!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }
}
