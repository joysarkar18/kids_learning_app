import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints the kid's tracing strokes as solid dark lines — like tracing
/// over a dotted outline with a real pen.
class FreehandPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  FreehandPainter({
    required this.strokes,
    required this.currentStroke,
  });

  static const _strokeColor = Color(0xFF222222);
  static const _strokeWidth = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    if (points.length > 1) {
      path.lineTo(points.last.dx, points.last.dy);
    }

    // Main solid stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = _strokeColor
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant FreehandPainter old) {
    return old.strokes.length != strokes.length ||
        old.currentStroke.length != currentStroke.length;
  }
}

/// Paints a diagonal crosshatch pattern over the canvas, clipped to the
/// non-transparent pixels of the outline image. This gives the "guideline"
/// look similar to drawing apps where the areas to color have hatching.
class CrosshatchOverlayPainter extends CustomPainter {
  final ui.Image outlineImage;

  CrosshatchOverlayPainter({required this.outlineImage});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 8.0;
    // Diagonal lines (top-left to bottom-right)
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CrosshatchOverlayPainter old) => false;
}
