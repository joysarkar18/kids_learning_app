import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:floodfill_image_ihux/floodfill_image.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_bloc.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_event.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_state.dart';
import 'dart:async'; // Required for Timer

class DrawingScreen extends StatelessWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DrawingBloc()..add(const LoadRandomImage()),
      child: const _DrawingScreenContent(),
    );
  }
}

class _DrawingScreenContent extends StatefulWidget {
  const _DrawingScreenContent();

  @override
  State<_DrawingScreenContent> createState() => _DrawingScreenContentState();
}

class _DrawingScreenContentState extends State<_DrawingScreenContent>
    with SingleTickerProviderStateMixin {
  Color _selectedColor = const Color(0xFFE74C3C);
  bool _isEraser = false;
  bool _isInteracting = false;

  // Preview State Management
  bool _showFullPreview = true;
  bool _imageLoaded = false;
  Timer? _previewTimer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final TransformationController _transformationController =
      TransformationController();
  // The Classic 64-Crayon Box Palette (Reordered: Common Colors First)
  final List<Color> _crayonColors = [
    // --- 1. MOST COMMON / PRIMARY COLORS (The "Top 12") ---
    const Color(0xFFED0A3F), // Red
    const Color(0xFF0066FF), // Blue
    const Color(0xFF1CAC78), // Green
    const Color(0xFFFCE883), // Yellow
    const Color(0xFFFF7538), // Orange
    const Color(0xFF8359A3), // Violet (Purple)
    const Color(0xFFFFA6C9), // Carnation Pink
    const Color(0xFFA52A2A), // Brown
    const Color(0xFF000000), // Black
    const Color(0xFF95918C), // Gray
    const Color(0xFFFFFFFF), // White
    const Color(0xFF76D7EA), // Sky Blue
    // --- 2. REDS & PINKS ---
    const Color(0xFFC40233), // Brick Red
    const Color(0xFFFD0E35), // Tractor Red
    const Color(0xFFC32148), // Maroon
    const Color(0xFFCA3435), // Mahogany
    const Color(0xFFFF5349), // Red Orange
    const Color(0xFFE6335F), // Radical Red
    const Color(0xFFFF43A4), // Wild Strawberry
    const Color(0xFFFC89AC), // Tickle Me Pink
    const Color(0xFFF664AF), // Magenta
    const Color(0xFFFB7EFD), // Shocking Pink
    const Color(0xFFFFBCD9), // Cotton Candy
    const Color(0xFFFDD7E4), // Piggy Pink
    const Color(0xFFDA3287), // Violet Red
    const Color(0xFFF75394), // Violet Red (Light)
    const Color(0xFFC54B8C), // Mulberry
    // --- 3. ORANGES & YELLOWS ---
    const Color(0xFFFE4C40), // Sunset Orange
    const Color(0xFFFF681F), // Neon Red Orange
    const Color(0xFFFF7F49), // Burnt Orange
    const Color(0xFFFF9F80), // Peach
    const Color(0xFFFFAE42), // Yellow Orange
    const Color(0xFFFFB653), // Macaroni and Cheese
    const Color(0xFFFFCF48), // Sunglow
    const Color(0xFFFCD975), // Goldenrod
    const Color(0xFFFFFF99), // Canary
    const Color(0xFFF8E473), // Lemon Yellow
    const Color(0xFFE7C697), // Gold
    // --- 4. GREENS ---
    const Color(0xFFC5E384), // Yellow Green
    const Color(0xFFADFF2F), // Green Yellow
    const Color(0xFF87A96B), // Asparagus
    const Color(0xFFA8E4A0), // Granny Smith Apple
    const Color(0xFF01786F), // Pine Green
    const Color(0xFF2E8B57), // Sea Green
    const Color(0xFF45CEA2), // Shamrock
    const Color(0xFF006400), // Dark Green
    const Color(0xFF17806D), // Tropical Rain Forest
    const Color(0xFF8B8680), // Olive Green
    // --- 5. BLUES & TEALS ---
    const Color(0xFF1DACD6), // Cerulean
    const Color(0xFF2EB4E6), // Pacific Blue
    const Color(0xFF1974D2), // Navy Blue
    const Color(0xFF2B6CC4), // Denim
    const Color(0xFF000080), // Midnight Blue
    const Color(0xFF93CCEA), // Cornflower
    const Color(0xFF1FCECB), // Robin's Egg Blue
    const Color(0xFF008080), // Teal Blue
    // --- 6. PURPLES & VIOLETS ---
    const Color(0xFF7442C8), // Blue Violet
    const Color(0xFF5D35D1), // Indigo
    const Color(0xFFA2A2D0), // Wisteria
    const Color(0xFFD6AEDD), // Plum
    // --- 7. BROWNS & NEUTRALS ---
    const Color(0xFF9E5B40), // Sepia
    const Color(0xFF8A3324), // Burnt Sienna
    const Color(0xFFD68A59), // Raw Sienna
    const Color(0xFFDEA5A4), // Pastel Brown
    const Color(0xFFCD9575), // Antique Brass
    const Color(0xFFD27D46), // Raw Umber
    const Color(0xFFB4674D), // Light Brown
    const Color(0xFFC0C0C0), // Silver
    const Color(0xFF2D383A), // Outer Space Grey
  ];
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // FIX: Tween goes from 1.0 (Visible) to 0.0 (Hidden)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  // Helper: Starts the auto-hide timer
  void _startPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _showFullPreview) {
        _hidePreview();
      }
    });
  }

  // Helper: Called when network image finishes loading
  void _onImageLoaded() {
    if (!_imageLoaded && mounted) {
      setState(() => _imageLoaded = true);
      _startPreviewTimer();
    }
  }

  // Action: User manually asks to see preview
  void _showPreviewPopup() {
    _previewTimer?.cancel();
    setState(() {
      _showFullPreview = true;
      _imageLoaded = true; // Assume loaded if manually triggering
    });

    // FIX: Reset controller to 0. Since our Tween starts at 1.0,
    // this makes the image immediately fully visible.
    _animationController.value = 0;

    _startPreviewTimer();
  }

  // Action: Hide the preview with animation
  void _hidePreview() {
    // FIX: Play forward (0 -> 1). This runs the Tween (1.0 -> 0.0), causing shrink/fade.
    AudioPlayerService.instance.playUi(key: UiAudioKey.image_fill);
    _animationController.forward().then((_) {
      if (mounted) {
        setState(() => _showFullPreview = false);
        _animationController.reset();
      }
    });
  }

  // Action: Load Next Image
  void _onNextImage() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _previewTimer?.cancel();
    setState(() {
      _showFullPreview = true;
      _imageLoaded = false; // Reset so timer waits for new image load
    });
    _animationController.value = 0;
    context.read<DrawingBloc>().add(const LoadNextImage());
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<DrawingBloc, DrawingState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Background
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
                    // Header
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Reference Image Preview (Left)
                            if (state is DrawingLoaded && !_showFullPreview)
                              GestureDetector(
                                onTap: _showPreviewPopup,
                                child: _ReferenceImagePreview(
                                  imageUrl: state.filledImageUrl,
                                  size: 48,
                                ),
                              )
                            else
                              const SizedBox(width: 48),

                            // Next Button (Center)
                            _WoodenNextButton(onTap: _onNextImage),

                            // Close Button (Right)
                            _WoodenCloseButton(
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Drawing Area
                    Expanded(child: _buildDrawingArea(state)),

                    // Crayon Tray
                    _buildCrayonTray(),
                  ],
                ),

                // Full Screen Preview Overlay
                if (state is DrawingLoaded && _showFullPreview)
                  GestureDetector(
                    onTap: _hidePreview, // Tap anywhere to close immediately
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        // FIX: Use value directly.
                        // At start (Controller 0) -> Value 1.0 (Fully Visible)
                        // At end (Controller 1) -> Value 0.0 (Invisible)
                        final double value = _scaleAnimation.value;

                        return Container(
                          color: Colors.black.withOpacity(0.7 * value),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {}, // Prevent tap through
                              child: Transform.scale(
                                scale: value, // Scale 1.0 -> 0.0
                                child: Opacity(
                                  opacity: value, // Opacity 1.0 -> 0.0
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    height:
                                        MediaQuery.of(context).size.width * 0.7,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF8D6E63),
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        state.filledImageUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            // Image loaded. Start timer now.
                                            if (!_imageLoaded) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    _onImageLoaded();
                                                  });
                                            }
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              color: Colors.brown[400],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawingArea(DrawingState state) {
    if (state is DrawingLoading) {
      return const _LoadingWidget();
    }

    if (state is DrawingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(color: Colors.red[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<DrawingBloc>().add(const LoadRandomImage());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is DrawingLoaded) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 5.0,
            boundaryMargin: EdgeInsets.zero,
            panEnabled: false,
            scaleEnabled: true,
            onInteractionStart: (details) {
              setState(() => _isInteracting = true);
            },
            onInteractionEnd: (details) {
              setState(() => _isInteracting = false);
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
                child: AbsorbPointer(
                  absorbing: _isInteracting,
                  child: FloodFillImage(
                    imageProvider: NetworkImage(state.drawingImageUrl),
                    fillColor: _isEraser ? Colors.white : _selectedColor,
                    avoidColor: const [Colors.black, Colors.transparent],
                    // CHANGE HERE: Increased tolerance from 25 to 50
                    // This allows the color to bleed slightly into the anti-aliased
                    // gray edges, removing the "white dots" or halo effect.
                    tolerance: 50,
                    width: constraints.maxWidth.toInt(),
                    height: constraints.maxHeight.toInt(),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return const _LoadingWidget();
  }

  Widget _buildCrayonTray() {
    return Container(
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
                  padding: const EdgeInsets.only(bottom: 20, right: 20, top: 6),
                  child: _SingleShapeCrayon(
                    color: Colors.white,
                    isEraser: true,
                    isSelected: _isEraser,
                  ),
                ),
              ),
              // Crayons
              ..._crayonColors.map((color) {
                final isSelected = _selectedColor == color && !_isEraser;
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
    );
  }
}

// --------------------------------------------------------------------------
// Helper Widgets (Same as before, included for completeness)
// --------------------------------------------------------------------------

class _ReferenceImagePreview extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _ReferenceImagePreview({required this.imageUrl, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8D6E63), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: Colors.brown[400],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 24),
            );
          },
        ),
      ),
    );
  }
}

class _WoodenNextButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WoodenNextButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Next',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF3E2723),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

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
    return CustomPaint(
      size: const Size(24, 80),
      painter: _CrayonMasterPainter(
        color: color,
        isEraser: isEraser,
        isSelected: isSelected,
      ),
    );
  }
}

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
      canvas.drawRect(
        wrapperRect,
        Paint()..color = Colors.white.withOpacity(0.25),
      );

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

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

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
