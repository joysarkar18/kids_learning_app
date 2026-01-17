import 'package:flutter/material.dart';
import 'package:floodfill_image_ihux/floodfill_image.dart';
import 'dart:async';
import 'dart:ui' as ui;

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  Color _selectedColor = const Color(0xFFE74C3C);
  bool _isEraser = false;
  bool _isLoading = true;

  // New State: To track if user is currently zooming/pinching
  bool _isInteracting = false;

  final TransformationController _transformationController =
      TransformationController();
  final String _assetImage = 'assets/images/lion_image.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheImage();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _precacheImage() async {
    try {
      final imageProvider = AssetImage(_assetImage);
      await precacheImage(imageProvider, context);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Expanded Palette - 30 Colors
  final List<Color> _crayonColors = [
    // Reds & Pinks
    const Color(0xFFE74C3C), // Red
    const Color(0xFFC0392B), // Dark Red
    const Color(0xFFFF99CC), // Carnation Pink
    const Color(0xFFFF1493), // Deep Pink
    const Color(0xFFE91E63), // Pink
    // Oranges & Yellows
    const Color(0xFFFF8C00), // Dark Orange
    const Color(0xFFFF6347), // Tomato
    const Color(0xFFFFA500), // Orange
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFFFF00), // Yellow
    const Color(0xFFFFFACD), // Lemon Chiffon
    // Greens
    const Color(0xFFADFF2F), // Green Yellow
    const Color(0xFF32CD32), // Lime Green
    const Color(0xFF228B22), // Forest Green
    const Color(0xFF006400), // Dark Green
    const Color(0xFF00FA9A), // Medium Spring Green
    // Blues & Cyans
    const Color(0xFF00CED1), // Dark Turquoise
    const Color(0xFF00BFFF), // Deep Sky Blue
    const Color(0xFF1E90FF), // Dodger Blue
    const Color(0xFF0000FF), // Blue
    const Color(0xFF00008B), // Dark Blue
    // Purples
    const Color(0xFF9370DB), // Medium Purple
    const Color(0xFF8A2BE2), // Blue Violet
    const Color(0xFF4B0082), // Indigo
    const Color(0xFF800080), // Purple
    // Browns & Neutrals
    const Color(0xFFD2691E), // Chocolate
    const Color(0xFF8B4513), // Saddle Brown
    const Color(0xFFA0522D), // Sienna
    const Color(0xFF808080), // Gray
    const Color(0xFF000000), // Black
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Soft Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green[50]!, Colors.green[100]!],
                ),
              ),
            ),

            Column(
              children: [
                // 2. Header
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _WoodenCloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Drawing Area
                Expanded(
                  child: _isLoading
                      ? const _ShimmerLoadingWidget()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return InteractiveViewer(
                              transformationController:
                                  _transformationController,
                              minScale: 1.0,
                              maxScale: 5.0,
                              boundaryMargin: EdgeInsets.zero,
                              panEnabled: false,
                              scaleEnabled: true,

                              // FIX: Track Interaction Start/End
                              onInteractionStart: (details) {
                                setState(() {
                                  _isInteracting = true;
                                });
                              },
                              onInteractionEnd: (details) {
                                setState(() {
                                  _isInteracting = false;
                                });
                              },

                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  // FIX: AbsorbPointer prevents touches from reaching the Image while zooming
                                  child: AbsorbPointer(
                                    absorbing: _isInteracting,
                                    child: FloodFillImage(
                                      imageProvider: AssetImage(_assetImage),
                                      fillColor: _isEraser
                                          ? Colors.white
                                          : _selectedColor,
                                      avoidColor: const [
                                        Colors.black,
                                        Colors.transparent,
                                      ],
                                      tolerance: 25,
                                      width: constraints.maxWidth.toInt(),
                                      height: constraints.maxHeight.toInt(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 4. Enhanced Crayon Tray
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                    border: const Border(
                      top: BorderSide(color: Color(0xFFBCAAA4), width: 3),
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Eraser
                          GestureDetector(
                            onTap: () => setState(() => _isEraser = true),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 20,
                                right: 20,
                                top: 6,
                              ),
                              child: _SingleShapeCrayon(
                                color: Colors.white,
                                isEraser: true,
                                isSelected: _isEraser,
                              ),
                            ),
                          ),
                          // 30 Crayons
                          ..._crayonColors.map((color) {
                            final isSelected =
                                _selectedColor == color && !_isEraser;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = color;
                                  _isEraser = false;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 20,
                                  left: 6,
                                  right: 6,
                                ),
                                child: _SingleShapeCrayon(
                                  color: color,
                                  isEraser: false,
                                  isSelected: isSelected,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Single Shape Crayon/Eraser
// ---------------------------------------------------------------------------
class _SingleShapeCrayon extends StatelessWidget {
  final Color color;
  final bool isEraser;
  final bool isSelected;

  const _SingleShapeCrayon({
    required this.color,
    required this.isEraser,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    const double width = 24;
    const double height = 80;

    return CustomPaint(
      size: const Size(width, height),
      painter: _CrayonMasterPainter(
        color: color,
        isEraser: isEraser,
        isSelected: isSelected,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. The Master Painter (Handles Shape matching Glow)
// ---------------------------------------------------------------------------
class _CrayonMasterPainter extends CustomPainter {
  final Color color;
  final bool isEraser;
  final bool isSelected;

  _CrayonMasterPainter({
    required this.color,
    required this.isEraser,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define the Path
    final Path shapePath = Path();

    if (isEraser) {
      final r = 4.0;
      shapePath.moveTo(0, r);
      shapePath.quadraticBezierTo(0, 0, r, 0);
      shapePath.lineTo(w - r, 0);
      shapePath.quadraticBezierTo(w, 0, w, r);
      shapePath.lineTo(w, h - r);
      shapePath.quadraticBezierTo(w, h, w - r, h);
      shapePath.lineTo(r, h);
      shapePath.quadraticBezierTo(0, h, 0, h - r);
      shapePath.close();
    } else {
      final tipHeight = 16.0;
      shapePath.moveTo(0, h - 3);
      shapePath.lineTo(0, tipHeight);
      shapePath.quadraticBezierTo(w * 0.2, tipHeight * 0.5, w / 2, 0);
      shapePath.quadraticBezierTo(w * 0.8, tipHeight * 0.5, w, tipHeight);
      shapePath.lineTo(w, h - 3);
      shapePath.quadraticBezierTo(w / 2, h, 0, h - 3);
      shapePath.close();
    }

    // Draw Rainbow Glow
    if (isSelected) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..shader = const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

      canvas.drawPath(shapePath, glowPaint);

      final Paint borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = Colors.white.withOpacity(0.8);

      canvas.drawPath(shapePath, borderPaint);
    }

    // Draw Fill
    final Paint fillPaint = Paint()..style = PaintingStyle.fill;

    if (isEraser) {
      fillPaint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0.6, 0.6],
        colors: [Color(0xFFF48FB1), Color(0xFF64B5F6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      fillPaint.color = color;
    }

    canvas.drawPath(shapePath, fillPaint);

    // Add Details for Crayons
    if (!isEraser) {
      final shadowPath = Path();
      shadowPath.moveTo(w / 2, 0);
      shadowPath.lineTo(w, 16);
      shadowPath.lineTo(w, h);
      shadowPath.lineTo(w / 2, h);
      shadowPath.close();
      canvas.drawPath(
        shadowPath,
        Paint()..color = Colors.black.withOpacity(0.1),
      );

      final wrapperTop = 22.0;
      final wrapperBottom = h - 6.0;

      canvas.save();
      canvas.clipPath(shapePath);

      final wrapperRect = Rect.fromLTRB(0, wrapperTop, w, wrapperBottom);
      final wrapperPaint = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.fill;

      canvas.drawRect(wrapperRect, wrapperPaint);

      final linePaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawRect(wrapperRect, linePaint);

      final wavePath = Path();
      final midY = wrapperTop + (wrapperBottom - wrapperTop) / 2;
      wavePath.moveTo(2, midY);
      wavePath.quadraticBezierTo(w / 4, midY - 3, w / 2, midY);
      wavePath.quadraticBezierTo(w * 0.75, midY + 3, w - 2, midY);

      canvas.drawPath(wavePath, linePaint);

      canvas.restore();
    }

    // Add "ERASER" text
    if (isEraser) {
      const textSpan = TextSpan(
        text: 'ERASER',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(w / 2, h / 2);
      canvas.rotate(-1.5708);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CrayonMasterPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected || oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// 3. Wooden Close Button
// ---------------------------------------------------------------------------
class _WoodenCloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WoodenCloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD7CCC8), Color(0xFF8D6E63)],
          ),
          border: Border.all(color: const Color(0xFF5D4037), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: Color(0xFF3E2723),
          size: 28,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Loading State
// ---------------------------------------------------------------------------
class _ShimmerLoadingWidget extends StatelessWidget {
  const _ShimmerLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.brown[400]),
          const SizedBox(height: 16),
          Text(
            "Loading Canvas...",
            style: TextStyle(
              color: Colors.brown[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
