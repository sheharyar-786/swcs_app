import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final int index;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.index,
    this.iconColor = const Color(0xFF4CAF50),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutBack, // Thora sa bounce effect premium lagta hai
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)), // Niche se upar slide hoga
            child: child,
          ),
        );
      },
      child: Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 140, // Uniform height for alignment
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              // Modern Neumorphic and Elevation mix
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(-5, -5),
                ),
              ],
              border: Border.all(
                color: iconColor.withOpacity(0.05),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Glowing Icon Container
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 12),
                // Value Text with Shadow for Depth
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: -0.5,
                      fontWeight:
                          FontWeight.w900, // Extra bold for premium look
                      color: const Color(0xFF263238), // Charcoal Grey
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Elegant Label
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title.toUpperCase(), // All caps for professional UI
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
