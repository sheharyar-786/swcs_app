import 'package:flutter/material.dart';

class StatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // String value ko double mein convert karna animation ke liye
    double endValue = double.tryParse(widget.value) ?? 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered
              ? 1.02
              : 1.0, // Thoda kam scale kiya taake layout break na ho
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(

          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFF2E7D32).withValues(alpha: 0.05), // Subtle Green tint
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 15 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Content ke hisab se height lega
            children: [
              // Icon Section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(height: 10),

              // Value Section with FittedBox to prevent overflow
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: endValue),
                    duration: const Duration(seconds: 1),
                    builder: (context, value, child) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Title Section
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              // Bottom Indicator
              const SizedBox(height: 8),
              Container(
                width: 25,
                height: 3,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
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

