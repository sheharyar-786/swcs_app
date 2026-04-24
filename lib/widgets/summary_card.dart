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
      curve: Curves.easeOutBack, // Premium bounce effect
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)), // Slide up animation
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          // Note: Height is now flexible based on parent or fixed in admin_dashboard.dart
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
            border: Border.all(color: iconColor.withValues(alpha: 0.05), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Premium Glowing Icon Container (Optimized Size)
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),

              const SizedBox(height: 10),

              // 2. Value Text (Extra bold for premium look)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF263238),
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // 3. Elegant Label
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    color: Colors.blueGrey.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
