import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:scribble/scribble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChalkBoardScreen extends StatefulWidget {
  final String alphabet;
  final String languageCode;

  const ChalkBoardScreen({
    super.key,
    required this.alphabet,
    this.languageCode = 'en',
  });

  @override
  State<ChalkBoardScreen> createState() => _ChalkBoardScreenState();
}

class _ChalkBoardScreenState extends State<ChalkBoardScreen>
    with TickerProviderStateMixin {
  late ScribbleNotifier _notifier;
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;

  late AnimationController _handController;
  late Animation<Offset> _handAnimation;

  Timer? _debounceTimer;
  bool _isEraserMode = false;
  bool _hasStartedDrawing = false;
  bool _isSuccess = false;

  final GlobalKey _textRepaintKey = GlobalKey();
  List<Offset> _perfectShapePoints = [];
  bool _isShapeScanned = false;
  Rect _letterBounds = Rect.zero;
  Offset _letterGlobalPosition = Offset.zero;

  Offset _chalkPosition = Offset.zero;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    _initScribble();
    AudioService().resume();
    _audioPlayer = AudioPlayer();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _handController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _handAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0.2, 0.2),
        ).animate(
          CurvedAnimation(parent: _handController, curve: Curves.easeInOut),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      _extractShapePoints();
    });
  }

  void _initScribble() {
    _notifier = ScribbleNotifier();
    _notifier.setColor(Colors.white);
    _notifier.setStrokeWidth(12.0);
    _notifier.addListener(_onScribbleUpdate);
  }

  Future<void> _extractShapePoints() async {
    try {
      final RenderRepaintBoundary? boundary =
          _textRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _extractShapePoints();
        return;
      }

      // --- CRITICAL FIX START: Handle FittedBox Scaling ---
      // 1. Get the global position (top-left) of the widget
      _letterGlobalPosition = boundary.localToGlobal(Offset.zero);

      // 2. Calculate the ACTUAL visible size on screen
      // boundary.localToGlobal of the bottom-right corner gives us the screen end point
      final Offset globalBottomRight = boundary.localToGlobal(
        Offset(boundary.size.width, boundary.size.height),
      );

      final double screenWidth =
          globalBottomRight.dx - _letterGlobalPosition.dx;
      final double screenHeight =
          globalBottomRight.dy - _letterGlobalPosition.dy;

      // 3. Calculate Scale Factor
      // (Screen Size / Original Logical Size)
      final double scaleX = screenWidth / boundary.size.width;
      final double scaleY = screenHeight / boundary.size.height;
      // --- CRITICAL FIX END ---

      // Use PixelRatio 3.0 for sharp detection of thin letters
      const double pixelRatio = 3.0;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final int width = image.width;
      final int height = image.height;
      List<Offset> points = [];

      double minX = double.infinity,
          maxX = double.negativeInfinity,
          minY = double.infinity,
          maxY = double.negativeInfinity;

      for (int y = 0; y < height; y += 4) {
        for (int x = 0; x < width; x += 4) {
          final int pixelIndex = (y * width + x) * 4;
          final int alpha = buffer[pixelIndex + 3];

          if (alpha > 20) {
            // Get original logical coordinates
            final double originalLogicalX = x / pixelRatio;
            final double originalLogicalY = y / pixelRatio;

            // APPLY THE SCALE FACTOR
            // This shrinks the points to match the FittedBox's visual result
            final double finalX = originalLogicalX * scaleX;
            final double finalY = originalLogicalY * scaleY;

            points.add(Offset(finalX, finalY));

            if (finalX < minX) minX = finalX;
            if (finalX > maxX) maxX = finalX;
            if (finalY < minY) minY = finalY;
            if (finalY > maxY) maxY = finalY;
          }
        }
      }
      if (points.isEmpty) return;
      setState(() {
        _perfectShapePoints = points;
        _letterBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
        _isShapeScanned = true;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _onScribbleUpdate() {
    if (!_hasStartedDrawing && _notifier.currentSketch.lines.isNotEmpty) {
      setState(() => _hasStartedDrawing = true);
    }
    if (_isSuccess) return;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), _validateDrawing);
  }

  void _validateDrawing() {
    if (!_isShapeScanned || _perfectShapePoints.isEmpty) return;
    final sketch = _notifier.currentSketch;
    if (sketch.lines.isEmpty) return;

    int validPointsHit = 0;
    int totalUserPointsToCheck = 0;
    int badOutsidePoints = 0;

    // Use a forgiving hit radius since 'আ' is complex
    const double hitRadius = 35.0;
    const double hitRadiusSq = hitRadius * hitRadius;

    List<Offset> userPoints = [];
    for (final line in sketch.lines) {
      for (int i = 0; i < line.points.length; i += 2) {
        userPoints.add(Offset(line.points[i].x, line.points[i].y));
      }
    }
    totalUserPointsToCheck = userPoints.length;
    if (totalUserPointsToCheck < 15) return;

    // Expand bounds for messiness check
    final expandedBounds = _letterBounds
        .shift(_letterGlobalPosition)
        .inflate(50);

    for (final uPoint in userPoints) {
      if (!expandedBounds.contains(uPoint)) {
        badOutsidePoints++;
      }
    }

    double messinessRatio = badOutsidePoints / totalUserPointsToCheck;
    // Allow 40% messiness for complex letters
    if (messinessRatio > 0.4) {
      debugPrint("Too messy! Outside ratio: $messinessRatio");
      return;
    }

    for (final targetPoint in _perfectShapePoints) {
      final globalTarget = targetPoint + _letterGlobalPosition;
      bool isHit = false;

      for (final uPoint in userPoints) {
        final dx = uPoint.dx - globalTarget.dx;
        final dy = uPoint.dy - globalTarget.dy;
        if (dx * dx + dy * dy < hitRadiusSq) {
          isHit = true;
          break;
        }
      }
      if (isHit) validPointsHit++;
    }

    final double coverage = validPointsHit / _perfectShapePoints.length;
    debugPrint("Coverage: ${(coverage * 100).toStringAsFixed(1)}%");

    if (coverage > 0.8) {
      _triggerSuccess();
    }
  }

  Future<void> _triggerSuccess() async {
    if (_isSuccess) return;
    setState(() {
      _isSuccess = true;
      _isWriting = false;
    });
    _confettiController.play();
    try {
      await _audioPlayer.play(AssetSource('audios/ui/yay_sound.wav'));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _toggleEraser() {
    setState(() {
      _isEraserMode = !_isEraserMode;
      if (_isEraserMode) {
        _notifier.setEraser();
        _notifier.setStrokeWidth(40.0);
      } else {
        _notifier.setColor(Colors.white);
        _notifier.setStrokeWidth(12.0);
      }
    });
  }

  @override
  void dispose() {
    AudioService().pause();
    _debounceTimer?.cancel();
    _notifier.removeListener(_onScribbleUpdate);
    _notifier.dispose();
    _confettiController.dispose();
    _handController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Thinner Font Weight (w500) as requested
    final textStyle = GoogleFonts.mali(
      fontSize: 350.sp,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.25),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF202020),
        body: Stack(
          children: [
            // Background
            Positioned.fill(
              child: CustomPaint(painter: RealisticChalkBoardPainter()),
            ),

            // THE LETTER
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 0.85.sw,
                  maxHeight: 0.7.sh,
                ),
                child: FittedBox(
                  fit: BoxFit.contain, // Scaling happens here
                  child: RepaintBoundary(
                    key: _textRepaintKey,
                    // Single outline text
                    child: Text(widget.alphabet, style: textStyle),
                  ),
                ),
              ),
            ),

            // Drawing Layer
            Positioned.fill(
              child: Listener(
                onPointerDown: (details) {
                  if (!_isSuccess) {
                    setState(() {
                      _isWriting = true;
                      _chalkPosition = details.position;
                    });
                  }
                },
                onPointerMove: (details) {
                  if (_isWriting) {
                    setState(() {
                      _chalkPosition = details.position;
                    });
                  }
                },
                onPointerUp: (_) => setState(() => _isWriting = false),
                child: Scribble(notifier: _notifier, drawPen: true),
              ),
            ),

            // Chalk Cursor
            if (_isWriting && !_isEraserMode)
              Positioned(
                left: _chalkPosition.dx,
                top: _chalkPosition.dy,
                child: Transform.translate(
                  offset: const Offset(-10, -55),
                  child: Transform.rotate(
                    angle: 0.4,
                    child: IgnorePointer(
                      child: SizedBox(
                        width: 40,
                        height: 80,
                        child: CustomPaint(painter: RealisticChalkPainter()),
                      ),
                    ),
                  ),
                ),
              ),

            // Eraser Cursor
            if (_isWriting && _isEraserMode)
              Positioned(
                left: _chalkPosition.dx - 25,
                top: _chalkPosition.dy - 50,
                child: IgnorePointer(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black26),
                      ],
                    ),
                    child: const Center(
                      child: Icon(FontAwesomeIcons.eraser, color: Colors.black),
                    ),
                  ),
                ),
              ),

            // Hand Guide
            if (!_hasStartedDrawing)
              Align(
                alignment: Alignment.center,
                child: SlideTransition(
                  position: _handAnimation,
                  child: Transform.translate(
                    offset: Offset(40.w, 40.h),
                    child: const Icon(
                      FontAwesomeIcons.handPointUp,
                      color: Colors.white,
                      size: 60,
                      shadows: [Shadow(blurRadius: 15, color: Colors.black)],
                    ),
                  ),
                ),
              ),

            // Top Buttons
            Positioned(
              top: 50.h,
              left: 20.w,
              child: _WoodButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.pop(context, false),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 40.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 25.w,
                    vertical: 15.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.brown[900]?.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: const Color(0xFF5D4037),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _WoodButton(
                        icon: Icons.undo_rounded,
                        iconColor: Colors.amber,
                        onTap: _notifier.undo,
                        size: 50.w,
                      ),
                      SizedBox(width: 25.w),
                      _WoodButton(
                        icon: FontAwesomeIcons.eraser,
                        iconColor: _isEraserMode
                            ? Colors.redAccent
                            : Colors.white,
                        isActive: _isEraserMode,
                        onTap: _toggleEraser,
                        size: 60.w,
                      ),
                      SizedBox(width: 25.w),
                      _WoodButton(
                        icon: Icons.delete,
                        iconColor: Colors.redAccent,
                        onTap: () {
                          _notifier.clear();
                          setState(() {
                            _hasStartedDrawing = false;
                            _isSuccess = false;
                          });
                        },
                        size: 50.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 25,
                minBlastForce: 10,
                emissionFrequency: 0.05,
                numberOfParticles: 40,
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- VISUAL HELPERS ---
class RealisticChalkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPath = Path();
    shadowPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 5, size.width, size.height),
        const Radius.circular(5),
      ),
    );
    canvas.drawShadow(shadowPath, Colors.black, 8.0, true);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEEEEEE), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
        stops: [0.1, 0.5, 0.9],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, paint);

    final tipPaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromLTWH(2, size.height - 10, size.width - 4, 12),
      tipPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RealisticChalkBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final basePaint = Paint()..color = const Color(0xFF263238);
    canvas.drawRect(rect, basePaint);

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
        stops: const [0.6, 1.0],
        radius: 1.2,
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);

    final random = Random(42);
    final dustPaint = Paint()..color = Colors.white.withOpacity(0.03);
    for (int i = 0; i < 8000; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.0,
        dustPaint,
      );
    }
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        40 + random.nextDouble() * 60,
        cloudPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WoodButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double? size;
  final Color iconColor;

  const _WoodButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = size ?? 55.w;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: btnSize,
        width: btnSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.yellowAccent : const Color(0xFF3E2723),
            width: isActive ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: btnSize * 0.5),
      ),
    );
  }
}
