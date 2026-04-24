import 'package:flutter/material.dart';

class BinInfoCard extends StatelessWidget {
  final String binId;
  final double fillLevel;
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

  // --- Premium Theme Colors ---
  static const Color leafGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFF44336);
  static const Color deepForest = Color(0xFF1B5E20);

  Color _getStatusColor() {
    if (fillLevel >= 0.9) return dangerRed;
    if (fillLevel >= 0.6) return warningYellow;
    return leafGreen;
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();

    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 2, right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: statusColor.withValues(alpha: 0.05), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // Subtle Background Glow
              Positioned(
                top: -50,
                right: -50,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: statusColor.withValues(alpha: 0.03),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Bin ID and Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              binId.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: deepForest.withValues(alpha: 0.5),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              area ?? "General Area",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ],
                        ),
                        _statusBadge(status, statusColor),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Progress Section with Percentage
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fill Level",
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "${(fillLevel * 100).toInt()}%",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Premium Gradient Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          height: 14,
                          width:
                              MediaQuery.of(context).size.width *
                              0.7 *
                              fillLevel, // Balanced width
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withValues(alpha: 0.7),
                                statusColor,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Conditional Action Button
                    if (actionLabel != null) ...[
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: onActionPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: statusColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            actionLabel!.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
