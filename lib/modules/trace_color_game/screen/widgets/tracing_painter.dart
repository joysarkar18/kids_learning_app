import 'package:flutter/material.dart';

/// Paints the kid's tracing strokes as solid dark lines —
/// like tracing over a dotted outline with a real pen.
class TracingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  TracingPainter({
    required this.strokes,
    required this.currentStroke,
  });

  static const _color = Color(0xFF222222);
  static const _width = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _draw(canvas, stroke);
    }
    if (currentStroke.isNotEmpty) {
      _draw(canvas, currentStroke);
    }
  }

  void _draw(Canvas canvas, List<Offset> pts) {
    if (pts.length < 2) return;

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);

    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = _color
        ..strokeWidth = _width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant TracingPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentStroke.length != currentStroke.length;
}

/// Draws diagonal hatching lines across the canvas.
/// Used inside the coloring phase to show "empty" areas.
class HatchPainter extends CustomPainter {
  const HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    const gap = 10.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HatchPainter old) => false;
}
