import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final int index; // Added for staggered animation

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.index,
    this.iconColor = const Color(0xFF4CAF50), // Default to Leaf Green
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // --- ANIMATION WRAPPER ---
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 150)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(
              12,
            ), // Slightly reduced padding for better fit
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9), // Soft Mint Background
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment
                  .center, // Center aligned to avoid bottom overflow
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated-style Icon Circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 8),
                // Live Stat Value - FIXED: Added FittedBox to prevent overflow
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor == const Color(0xFFE53935)
                          ? iconColor
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Label - FIXED: Added FittedBox to prevent overflow
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
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
