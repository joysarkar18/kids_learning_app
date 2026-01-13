import 'package:flutter/material.dart';

class SlatePainter extends CustomPainter {
  final String alphabet;
  final List<Offset?> points;

  SlatePainter({required this.alphabet, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    /// ✨ Guide Alphabet (Glow Effect)
    final textPainter = TextPainter(
      text: TextSpan(
        text: alphabet,
        style: TextStyle(
          fontSize: size.width * 0.6,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = Colors.white.withOpacity(0.3),
          shadows: [
            Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 30),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, offset);

    /// ✏️ Kid Drawing
    final drawPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, drawPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
