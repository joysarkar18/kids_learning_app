import 'dart:math';
import 'package:flutter/material.dart';

/// A reusable background widget with gradient, overlay image, and decorative elements
/// matching the style used in namota modules.
class ModuleBackground extends StatelessWidget {
  final String backgroundImage;
  final double overlayOpacity;
  final bool showTopVine;
  final bool showBottomGrass;
  final Color? gradientStart;
  final Color? gradientMiddle;
  final Color? gradientEnd;
  final Color? vineColor;
  final Color? grassColor;
  final Widget? child;

  const ModuleBackground({
    super.key,
    required this.backgroundImage,
    this.overlayOpacity = 0.5,
    this.showTopVine = true,
    this.showBottomGrass = true,
    this.gradientStart,
    this.gradientMiddle,
    this.gradientEnd,
    this.vineColor,
    this.grassColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradientStart ?? const Color.fromARGB(255, 3, 4, 3),
                gradientMiddle ?? const Color.fromARGB(255, 7, 8, 7),
                gradientEnd ?? const Color.fromARGB(255, 3, 3, 3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Background image overlay
        Opacity(
          opacity: overlayOpacity,
          child: Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
        ),

        // Top vine decoration
        if (showTopVine)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _VinePainter(
                color: vineColor ?? const Color(0xFF1B5E20),
              ),
            ),
          ),

        // Bottom grass decoration
        if (showBottomGrass)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _GrassPainter(
                color: grassColor ?? const Color(0xFF33691E),
              ),
            ),
          ),

        // Child content
        if (child != null) child!,
      ],
    );
  }
}

/// Painter for the top vine decoration with wavy pattern
class _VinePainter extends CustomPainter {
  final Color color;

  const _VinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.4);

    // Wavy bottom edge
    for (double x = size.width; x >= 0; x -= 30) {
      path.quadraticBezierTo(
        x - 15,
        size.height * (0.4 + 0.3 * sin(x * 0.05)),
        x - 30,
        size.height * 0.4,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the bottom grass decoration with wavy pattern
class _GrassPainter extends CustomPainter {
  final Color color;

  const _GrassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.5);

    // Wavy grass top edge
    for (double x = size.width; x >= 0; x -= 20) {
      path.quadraticBezierTo(
        x - 10,
        size.height * (0.5 - 0.4 * sin(x * 0.08)),
        x - 20,
        size.height * 0.5,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
