import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:floodfill_image_ihux/floodfill_image.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import '../bloc/guided_drawing_bloc.dart';
import '../bloc/guided_drawing_event.dart';
import '../bloc/guided_drawing_state.dart';
import '../data/models/drawing_template.dart';
import 'widgets/freehand_painter.dart';
import 'widgets/template_selector.dart';

class GuidedDrawingScreen extends StatelessWidget {
  const GuidedDrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuidedDrawingBloc()..add(const InitTemplates()),
      child: const _GuidedDrawingContent(),
    );
  }
}

class _GuidedDrawingContent extends StatefulWidget {
  const _GuidedDrawingContent();

  @override
  State<_GuidedDrawingContent> createState() => _GuidedDrawingContentState();
}

class _GuidedDrawingContentState extends State<_GuidedDrawingContent>
    with TickerProviderStateMixin {
  late AnimationController _previewFadeController;
  late ConfettiController _confettiController;
  Timer? _previewTimer;
  bool _previewImageLoaded = false;

  // ── Local drawing state (NOT in BLoC — smooth 60fps) ──
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  // Decoded outline image for crosshatch overlay
  ui.Image? _outlineUiImage;
  String? _loadedOutlinePath;

  // Colors for the coloring palette — big squares like the reference app
  static const List<_PaletteColor> _defaultPalette = [
    _PaletteColor(Color(0xFFE53935), 'Red'),
    _PaletteColor(Color(0xFFFF9800), 'Orange'),
    _PaletteColor(Color(0xFFFFEB3B), 'Yellow'),
    _PaletteColor(Color(0xFF4CAF50), 'Green'),
    _PaletteColor(Color(0xFF2196F3), 'Blue'),
    _PaletteColor(Color(0xFF9C27B0), 'Purple'),
    _PaletteColor(Color(0xFFFF80AB), 'Pink'),
    _PaletteColor(Color(0xFF795548), 'Brown'),
  ];

  @override
  void initState() {
    super.initState();
    _previewFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewFadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ── Load outline as ui.Image for crosshatch painter ──

  Future<void> _loadOutlineImage(String assetPath) async {
    if (_loadedOutlinePath == assetPath && _outlineUiImage != null) return;
    _loadedOutlinePath = assetPath;

    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _outlineUiImage = frame.image);
    }
  }

  // ────────────── Actions ──────────────

  void _onPreviewImageLoaded() {
    if (!_previewImageLoaded && mounted) {
      _previewImageLoaded = true;
      _previewTimer?.cancel();
      _previewTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) _dismissPreview();
      });
    }
  }

  void _dismissPreview() {
    _previewTimer?.cancel();
    AudioPlayerService.instance.playUi(key: UiAudioKey.image_fill);
    _previewFadeController.forward().then((_) {
      if (mounted) {
        context.read<GuidedDrawingBloc>().add(const DismissPreview());
        _previewFadeController.reset();
      }
    });
  }

  void _showPreview() {
    _previewImageLoaded = false;
    _clearStrokes();
    context.read<GuidedDrawingBloc>().add(const ResetDrawing());
  }

  void _onTemplateSelected(DrawingTemplate template) {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _previewImageLoaded = false;
    _clearStrokes();
    _outlineUiImage = null;
    _loadedOutlinePath = null;
    context.read<GuidedDrawingBloc>().add(SelectTemplate(template.id));
  }

  void _onNext() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    DailyChallengeService.instance.reportProgress('guided_drawing');
    _previewImageLoaded = false;
    _clearStrokes();
    _outlineUiImage = null;
    _loadedOutlinePath = null;
    context.read<GuidedDrawingBloc>().add(const LoadNextTemplate());
  }

  void _onReset() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _previewImageLoaded = false;
    _clearStrokes();
    context.read<GuidedDrawingBloc>().add(const ResetDrawing());
  }

  void _onFinishTracing() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _confettiController.play();
    context.read<GuidedDrawingBloc>().add(const FinishTracing());
  }

  void _onUndo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  // ────────────── Build ──────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: BlocConsumer<GuidedDrawingBloc, GuidedDrawingState>(
          listener: (context, state) {
            if (state is GuidedDrawingActive &&
                state.phase == DrawingPhase.preview) {
              _strokes.clear();
              _currentStroke = [];
            }
            // Preload outline image for crosshatch
            if (state is GuidedDrawingActive &&
                !state.template.isNetworkImage) {
              _loadOutlineImage(state.template.outlineImage);
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                // Background
                Container(color: const Color(0xFFF5F5F5)),

                SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      _buildTopBar(state),
                      // Canvas
                      Expanded(child: _buildCanvas(state)),
                      // Bottom bar
                      if (state is GuidedDrawingActive) _buildBottomBar(state),
                    ],
                  ),
                ),

                // Reference preview overlay
                if (state is GuidedDrawingActive &&
                    state.phase == DrawingPhase.preview)
                  _buildReferencePreview(state),

                // Confetti
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 30,
                    maxBlastForce: 20,
                    minBlastForce: 5,
                    emissionFrequency: 0.05,
                    gravity: 0.2,
                    colors: const [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFD93D),
                      Color(0xFF6BCB77),
                      Color(0xFF4D96FF),
                      Color(0xFFFF6B81),
                      Color(0xFFA66CFF),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ────────────────────── Top Bar ──────────────────────

  Widget _buildTopBar(GuidedDrawingState state) {
    final active = state is GuidedDrawingActive ? state : null;
    final isTracing = active?.phase == DrawingPhase.tracing;
    final isColoring = active?.phase == DrawingPhase.coloring;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back button
          _SquareIconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: 8),

          // Template picker
          if (active != null)
            _SquareIconBtn(
              icon: Icons.grid_view_rounded,
              onTap: () => TemplateSelectorSheet.show(
                context,
                active.allTemplates,
                _onTemplateSelected,
              ),
            ),

          const Spacer(),

          // Template name + phase label
          if (active != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    active.template.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (isTracing || isColoring) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isTracing
                            ? const Color(0xFF42A5F5)
                            : const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isTracing ? 'Trace' : 'Color',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const Spacer(),

          // Reference thumb (tap to re-show preview)
          if (active != null && active.phase != DrawingPhase.preview)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _showPreview,
                child: _ReferenceThumb(
                  imagePath: active.template.referenceImage,
                  isNetwork: active.template.isNetworkImage,
                ),
              ),
            ),

          // Undo (tracing only)
          if (isTracing && _strokes.isNotEmpty)
            _SquareIconBtn(icon: Icons.undo_rounded, onTap: _onUndo),

          // Reset
          if (active != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SquareIconBtn(
                icon: Icons.refresh_rounded,
                onTap: _onReset,
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────── Reference Preview ──────────────────────

  Widget _buildReferencePreview(GuidedDrawingActive state) {
    return GestureDetector(
      onTap: _dismissPreview,
      child: AnimatedBuilder(
        animation: _previewFadeController,
        builder: (context, child) {
          final fade = 1.0 - _previewFadeController.value;
          return Container(
            color: Colors.black.withValues(alpha: 0.7 * fade),
            child: Center(
              child: Transform.scale(
                scale: 0.85 + (0.15 * fade),
                child: Opacity(opacity: fade, child: child),
              ),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview image card
            Container(
              width: MediaQuery.of(context).size.width * 0.72,
              height: MediaQuery.of(context).size.width * 0.72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFCC02), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: state.template.isNetworkImage
                      ? Image.network(
                          state.template.referenceImage,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _onPreviewImageLoaded(),
                              );
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFFF7043),
                                strokeWidth: 4,
                              ),
                            );
                          },
                        )
                      : Builder(
                          builder: (context) {
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _onPreviewImageLoaded(),
                            );
                            return Image.asset(
                              state.template.referenceImage,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tap hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Tap to start tracing!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────── Canvas ──────────────────────

  Widget _buildCanvas(GuidedDrawingState state) {
    if (state is GuidedDrawingLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
      );
    }

    if (state is GuidedDrawingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                state.message,
                style: TextStyle(color: Colors.red[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<GuidedDrawingBloc>().add(const InitTemplates()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is GuidedDrawingActive) {
      switch (state.phase) {
        case DrawingPhase.preview:
        case DrawingPhase.tracing:
          return _buildTracingCanvas(state);
        case DrawingPhase.coloring:
          return _buildColoringCanvas(state);
      }
    }

    return const SizedBox.shrink();
  }

  // ────────────────── Tracing Canvas ──────────────────

  Widget _buildTracingCanvas(GuidedDrawingActive state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentStroke = [d.localPosition];
                });
              },
              onPanUpdate: (d) {
                setState(() {
                  _currentStroke = [..._currentStroke, d.localPosition];
                });
              },
              onPanEnd: (_) {
                setState(() {
                  if (_currentStroke.length > 1) {
                    _strokes.add(_currentStroke);
                  }
                  _currentStroke = [];
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Crosshatch pattern background (guideline texture)
                  if (_outlineUiImage != null)
                    CustomPaint(
                      size: canvasSize,
                      painter: CrosshatchOverlayPainter(
                        outlineImage: _outlineUiImage!,
                      ),
                    ),

                  // Outline guide (faint — the dotted look)
                  Opacity(
                    opacity: 0.22,
                    child: _TemplateImage(
                      imagePath: state.template.outlineImage,
                      isNetwork: state.template.isNetworkImage,
                    ),
                  ),

                  // Kid's tracing strokes (solid dark)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: canvasSize,
                      painter: FreehandPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                    ),
                  ),

                  // Hint when canvas is empty
                  if (_strokes.isEmpty && _currentStroke.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.gesture_rounded,
                            size: 52,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Trace over the outline!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ────────────────── Coloring Canvas ──────────────────

  Widget _buildColoringCanvas(GuidedDrawingActive state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillColor = state.isEraser ? Colors.white : state.selectedColor;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FloodFillImage(
              imageProvider: state.template.isNetworkImage
                  ? NetworkImage(state.template.outlineImage) as ImageProvider
                  : AssetImage(state.template.outlineImage),
              fillColor: fillColor,
              avoidColor: const [Colors.black, Colors.transparent],
              tolerance: 32,
              width: constraints.maxWidth.toInt(),
              height: constraints.maxHeight.toInt(),
            ),
          ),
        );
      },
    );
  }

  // ────────────────── Bottom Bar ──────────────────

  Widget _buildBottomBar(GuidedDrawingActive state) {
    switch (state.phase) {
      case DrawingPhase.preview:
        return const SizedBox(height: 12);
      case DrawingPhase.tracing:
        return _buildTracingBottomBar();
      case DrawingPhase.coloring:
        return _buildColoringBottomBar(state);
    }
  }

  Widget _buildTracingBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          // Skip / Next
          Expanded(
            child: _LargeActionBtn(
              label: 'Skip',
              icon: Icons.skip_next_rounded,
              color: const Color(0xFF90A4AE),
              onTap: _onNext,
            ),
          ),
          const SizedBox(width: 12),
          // Color It! (main CTA)
          Expanded(
            flex: 2,
            child: _LargeActionBtn(
              label: 'Color It!',
              icon: Icons.palette_rounded,
              color: const Color(0xFF4CAF50),
              onTap: _strokes.isNotEmpty ? _onFinishTracing : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColoringBottomBar(GuidedDrawingActive state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color palette — large squares
        _buildColorPalette(state),
        const SizedBox(height: 8),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // Eraser
              _SquareIconBtn(
                icon: Icons.auto_fix_high_rounded,
                onTap: () =>
                    context.read<GuidedDrawingBloc>().add(const ToggleEraser()),
                isActive: state.isEraser,
                size: 48,
              ),
              const Spacer(),
              // Done / Next
              _LargeActionBtn(
                label: 'Done!',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF4CAF50),
                onTap: _onNext,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPalette(GuidedDrawingActive state) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _defaultPalette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final palette = _defaultPalette[index];
          final isSelected =
              state.selectedColor == palette.color && !state.isEraser;

          return GestureDetector(
            onTap: () => context.read<GuidedDrawingBloc>().add(
              SelectColor(palette.color),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF333333)
                      : Colors.grey[300]!,
                  width: isSelected ? 3.5 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: palette.color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────── Helper Widgets ────────────────────────

class _PaletteColor {
  final Color color;
  final String name;
  const _PaletteColor(this.color, this.name);
}

class _TemplateImage extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;

  const _TemplateImage({required this.imagePath, required this.isNetwork});

  @override
  Widget build(BuildContext context) {
    if (isNetwork) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _ReferenceThumb extends StatelessWidget {
  final String imagePath;
  final bool isNetwork;

  const _ReferenceThumb({required this.imagePath, required this.isNetwork});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC02), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: isNetwork
            ? Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 20, color: Colors.grey),
              )
            : Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
      ),
    );
  }
}

/// Rounded-square icon button used in top bar and bottom bar.
class _SquareIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double size;

  const _SquareIconBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF42A5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF555555),
          size: size * 0.52,
        ),
      ),
    );
  }
}

/// Large action button used in bottom bar.
class _LargeActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _LargeActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
