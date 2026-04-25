import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import '../bloc/trace_color_bloc.dart';
import '../bloc/trace_color_event.dart';
import '../bloc/trace_color_state.dart';
import '../data/game_level.dart';
import 'widgets/auto_trace_canvas.dart';
import 'widgets/coloring_canvas.dart';

class TraceColorScreen extends StatelessWidget {
  const TraceColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TraceColorBloc()..add(const StartGame()),
      child: const _GameContent(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────

class _GameContent extends StatefulWidget {
  const _GameContent();
  @override
  State<_GameContent> createState() => _GameContentState();
}

class _GameContentState extends State<_GameContent>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _previewFade;
  Timer? _previewTimer;
  bool _showPreview = false;

  // Keys for child canvas widgets
  final _traceKey = GlobalKey<AutoTraceCanvasState>();
  final _colorKey = GlobalKey<MaskedColoringCanvasState>();

  // Pen cursor position (null = finger up)
  Offset? _penPos;
  bool _hasColorStrokes = false;
  bool _isEraser = false;

  /// Preset brush sizes for the picker (extra-small / small / medium / large).
  static const List<double> _brushSizes = [8.0, 16.0, 28.0, 44.0];
  double _brushSize = 16.0;

  /// Brush popup state — `_brushBtnKey` is attached to the brush button
  /// so we can read its screen position when the popup opens.
  final GlobalKey _brushBtnKey = GlobalKey();
  bool _brushPopupOpen = false;
  Offset _brushBtnCenter = Offset.zero;
  double _brushBtnTop = 0;

  // Captured colored canvas image (shown in celebration)
  ui.Image? _coloredImage;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _previewFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewFade.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _togglePreview() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _previewTimer?.cancel();
    if (_showPreview) {
      _hidePreview();
    } else {
      setState(() => _showPreview = true);
      _previewFade.forward(from: 0);
      _previewTimer = Timer(const Duration(milliseconds: 2500), _hidePreview);
    }
  }

  void _hidePreview() {
    _previewTimer?.cancel();
    if (!_showPreview) return;
    _previewFade.reverse().then((_) {
      if (mounted) setState(() => _showPreview = false);
    });
  }

  // ── Actions ──

  /// Called automatically by AutoTraceCanvas when ≥ 95 % traced.
  void _onTracingComplete() async {
    _confetti.play();
    AudioPlayerService.instance.playUi(key: UiAudioKey.image_fill);

    // Brief pause so the kid sees the completed outline before transition
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.read<TraceColorBloc>().add(const FinishTracing());
    }
  }

  Future<void> _finishColoring() async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _confetti.play();

    // Capture the painted canvas so the celebration shows what the kid
    // actually coloured (not a solid correctColor rect).
    final captured = await _colorKey.currentState?.captureColoredImage();
    if (!mounted) return;
    setState(() => _coloredImage = captured);
    context.read<TraceColorBloc>().add(const FinishColoring());
  }

  void _nextLevel() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    DailyChallengeService.instance.reportProgress('guided_drawing');
    _hasColorStrokes = false;
    _isEraser = false;
    _penPos = null;
    _coloredImage = null;
    context.read<TraceColorBloc>().add(const NextLevel());
  }

  void _reset() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _traceKey.currentState?.clearAll();
    _colorKey.currentState?.clearAll();
    _hasColorStrokes = false;
    _isEraser = false;
    _penPos = null;
    _coloredImage = null;
    context.read<TraceColorBloc>().add(const ResetLevel());
  }

  void _toggleBrushPopup() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    if (_brushPopupOpen) {
      setState(() => _brushPopupOpen = false);
      return;
    }
    final rb =
        _brushBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final topLeft = rb.localToGlobal(Offset.zero);
    setState(() {
      _brushBtnCenter =
          Offset(topLeft.dx + rb.size.width / 2, topLeft.dy);
      _brushBtnTop = topLeft.dy;
      _brushPopupOpen = true;
    });
  }

  void _selectBrushSize(double s) {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    setState(() {
      _brushSize = s;
      _brushPopupOpen = false;
    });
  }

  void _toggleEraser() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    setState(() => _isEraser = !_isEraser);
  }

  void _undoTrace() => _traceKey.currentState?.undo();
  void _undoColor() => _colorKey.currentState?.undo();

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: BlocBuilder<TraceColorBloc, TraceColorState>(
          builder: (context, state) {
            return Stack(
              children: [
                Container(color: const Color(0xFFF7F7F7)),
                SafeArea(
                  child: Column(
                    children: [
                      _buildTopBar(state),
                      Expanded(child: _buildCanvas(state)),
                      _buildBottomBar(state),
                    ],
                  ),
                ),
                // Pen / crayon cursor (above everything except confetti)
                if (_penPos != null && state is TraceColorActive)
                  state.phase == GamePhase.coloring
                      ? _CrayonCursor(
                          position: _penPos!,
                          color: state.selectedColor,
                        )
                      : _PenCursor(position: _penPos!),
                // Reference image preview overlay (toggled by thumbnail tap)
                if (_showPreview && state is TraceColorActive)
                  _buildPreviewOverlay(state),
                // Brush-size popup (tap-outside to dismiss)
                if (_brushPopupOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => _brushPopupOpen = false),
                    ),
                  ),
                  _buildBrushPopup(),
                ],
                // Confetti
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
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

  // ────────────────────── Top bar ──────────────────────

  Widget _buildTopBar(TraceColorState state) {
    final active = state is TraceColorActive ? state : null;
    final isTracing = active?.phase == GamePhase.tracing;
    final isColoring = active?.phase == GamePhase.coloring;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Level badge
          if (active != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
              child: Text(
                'LEVEL ${active.level.level}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          const Spacer(),
          // Reference thumbnail button — tap to preview the filled image
          if (active != null)
            GestureDetector(
              onTap: _togglePreview,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _referenceImageWidget(
                    active.level.referenceImage,
                    active.level.isNetworkImage,
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Undo
          if (isTracing && (_traceKey.currentState?.hasStrokes ?? false))
            _IconBtn(icon: Icons.undo_rounded, onTap: _undoTrace),
          if (isColoring && _hasColorStrokes)
            _IconBtn(icon: Icons.undo_rounded, onTap: _undoColor),
          // Reset
          if (active != null && active.phase != GamePhase.celebration)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _IconBtn(icon: Icons.refresh_rounded, onTap: _reset),
            ),
        ],
      ),
    );
  }

  // ────────────────────── Canvas ──────────────────────

  Widget _buildCanvas(TraceColorState state) {
    if (state is TraceColorLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8D6E63)),
      );
    }
    if (state is TraceColorError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }
    if (state is TraceColorActive) {
      switch (state.phase) {
        case GamePhase.tracing:
          return _tracingCanvas(state);
        case GamePhase.coloring:
          return _coloringCanvas(state);
        case GamePhase.celebration:
          return _celebrationView(state);
      }
    }
    return const SizedBox.shrink();
  }

  // ── Tracing (auto-snap + dashed guide) ──

  Widget _tracingCanvas(TraceColorActive state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _canvasDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            AutoTraceCanvas(
              key: _traceKey,
              outlineAsset: state.level.outlineImage,
              onComplete: _onTracingComplete,
              onPenPositionChanged: (pos) => setState(() => _penPos = pos),
            ),
            // Animated pen hint — shown only when the kid hasn't started
            // drawing yet. Disappears as soon as the finger touches.
            if (_penPos == null &&
                !(_traceKey.currentState?.hasStrokes ?? false))
              Positioned.fill(
                child: IgnorePointer(
                  child: _PenHint(anchor: _traceKey.currentState?.startPoint),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Coloring (brush painting clipped inside outlines) ──

  Widget _coloringCanvas(TraceColorActive state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _canvasDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MaskedColoringCanvas(
          key: _colorKey,
          outlineAsset: state.level.outlineImage,
          brushColor: state.selectedColor,
          brushSize: _brushSize,
          isEraser: _isEraser,
          onStrokeAdded: () => setState(() => _hasColorStrokes = true),
          onPenPositionChanged: (pos) => setState(() => _penPos = pos),
        ),
      ),
    );
  }

  // ── Celebration ──

  Widget _celebrationView(TraceColorActive state) {
    final side = MediaQuery.of(context).size.width * 0.65;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // Show the kid's actual painted canvas if we captured it,
              // otherwise fall back to the raw outline.
              child: _coloredImage != null
                  ? RawImage(image: _coloredImage, fit: BoxFit.contain)
                  : Image.asset(
                      state.level.outlineImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Great job!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You colored the ${state.level.name}!',
            style: const TextStyle(fontSize: 16, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }

  // ────────────────────── Bottom bar ──────────────────────

  Widget _buildBottomBar(TraceColorState state) {
    if (state is! TraceColorActive) return const SizedBox(height: 12);
    switch (state.phase) {
      case GamePhase.tracing:
        return _tracingBottom();
      case GamePhase.coloring:
        return _coloringBottom(state);
      case GamePhase.celebration:
        return _celebrationBottom();
    }
  }

  /// Tracing bottom: a "Color Now" button (tracing also auto-completes).
  Widget _tracingBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: _BigBtn(
        label: 'Color Now',
        icon: Icons.palette_rounded,
        color: const Color(0xFF4CAF50),
        onTap: _skipToColoring,
      ),
    );
  }

  /// Shortcut-to-coloring handler. The coloring canvas builds its own
  /// outline image, so we just transition — no capture needed.
  void _skipToColoring() {
    _confetti.play();
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    context.read<TraceColorBloc>().add(const FinishTracing());
  }

  /// Coloring bottom: brush-size picker + eraser + palette + Done.
  Widget _coloringBottom(TraceColorActive state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            child: Row(
              children: [
                // Eraser toggle — pinned to the left so it's always visible
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4),
                  child: _EraserButton(active: _isEraser, onTap: _toggleEraser),
                ),
                // Brush size — single button that opens a popup with 3
                // options above it. Keeps the palette row roomy.
                _BrushSizeButton(
                  buttonKey: _brushBtnKey,
                  selectedSize: _brushSize,
                  maxSize: _brushSizes.last,
                  isOpen: _brushPopupOpen,
                  onTap: _toggleBrushPopup,
                ),
                // Small divider between controls and color palette
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: kidColorPalette.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = kidColorPalette[i];
                      final selected = state.selectedColor == c;
                      return GestureDetector(
                        onTap: () {
                          AudioPlayerService.instance.playUi(
                            key: UiAudioKey.button_press,
                          );
                          // Selecting a colour implicitly leaves eraser mode
                          setState(() => _isEraser = false);
                          context.read<TraceColorBloc>().add(PickColor(c));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 52 : 46,
                          height: selected ? 52 : 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF333333)
                                  : Colors.grey[300]!,
                              width: selected ? 3.5 : 1.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 26,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _BigBtn(
            label: 'Done!',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF4CAF50),
            onTap: _hasColorStrokes ? _finishColoring : null,
          ),
        ],
      ),
    );
  }

  Widget _celebrationBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: _BigBtn(
        label: 'Next Level',
        icon: Icons.arrow_forward_rounded,
        color: const Color(0xFF42A5F5),
        onTap: _nextLevel,
      ),
    );
  }

  // ── Shared decoration ──

  BoxDecoration _canvasDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget _referenceImageWidget(
    String path,
    bool isNetwork, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (isNetwork) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, size: 20, color: Colors.grey),
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image, size: 20, color: Colors.grey),
    );
  }

  // ── Preview overlay (tap thumbnail to see the filled reference) ──

  // ── Brush-size popup ──
  //
  // Positioned so it appears directly above the brush-size button.
  // Popup height ≈ 3×44 + padding ≈ 140; width ≈ 56.
  Widget _buildBrushPopup() {
    const popupW = 56.0;
    const popupH = 140.0;
    return Positioned(
      left: (_brushBtnCenter.dx - popupW / 2).clamp(
        8.0,
        MediaQuery.of(context).size.width - popupW - 8.0,
      ),
      top: (_brushBtnTop - popupH - 8).clamp(8.0, double.infinity),
      child: _BrushSizePopup(
        sizes: _brushSizes,
        selected: _brushSize,
        onSelect: _selectBrushSize,
      ),
    );
  }

  Widget _buildPreviewOverlay(TraceColorActive state) {
    return GestureDetector(
      onTap: _hidePreview,
      child: AnimatedBuilder(
        animation: _previewFade,
        builder: (context, child) {
          return Container(
            color: Colors.black.withValues(alpha: 0.55 * _previewFade.value),
            child: Opacity(opacity: _previewFade.value, child: child),
          );
        },
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFCC02), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _referenceImageWidget(
                  state.level.referenceImage,
                  state.level.isNetworkImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Small helper widgets
// ──────────────────────────────────────────────────────────────────

/// Pen cursor that floats above the canvas, following the kid's finger.
/// Animated pen hint shown before the kid starts tracing.
/// Bounces up and down at the outline's starting point to invite
/// interaction. Falls back to canvas-centre if [anchor] is null.
class _PenHint extends StatefulWidget {
  final Offset? anchor;
  const _PenHint({required this.anchor});

  @override
  State<_PenHint> createState() => _PenHintState();
}

class _PenHintState extends State<_PenHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchor =
            widget.anchor ??
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 3);

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            // Bounce offset 0 → 14 → 0
            final bounce = -14.0 * (1 - (_ctrl.value - 0.5).abs() * 2);

            return Stack(
              children: [
                // Pulsing ripple at the anchor point
                Positioned(
                  left: anchor.dx - 22,
                  top: anchor.dy - 22,
                  child: Opacity(
                    opacity: 0.35 + 0.35 * (1 - _ctrl.value),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF42A5F5),
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bouncing pen
                Positioned(
                  left: anchor.dx - 6,
                  top: anchor.dy - 58 + bounce,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        CustomPaint(
                          size: const Size(14, 12),
                          painter: _PenTipPainter(),
                        ),
                      ],
                    ),
                  ),
                ),
                // "Tap & drag" label below the pen
                Positioned(
                  left: anchor.dx - 60,
                  top: anchor.dy + 20,
                  child: Container(
                    width: 120,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF42A5F5,
                          ).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Start here!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Pen cursor shown during tracing phase.
class _PenCursor extends StatelessWidget {
  final Offset position;
  const _PenCursor({required this.position});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 6,
      top: position.dy - 58,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              CustomPaint(size: const Size(14, 12), painter: _PenTipPainter()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Crayon cursor shown during coloring phase — colored to match the
/// selected brush color.
class _CrayonCursor extends StatelessWidget {
  final Offset position;
  final Color color;
  const _CrayonCursor({required this.position, required this.color});

  @override
  Widget build(BuildContext context) {
    // Derive a slightly darker shade for the crayon body gradient
    final darker = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1))
        .toColor();

    return Positioned(
      left: position.dx - 8,
      top: position.dy - 62,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: 0.2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crayon wrapper / label band
              Container(
                width: 18,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: darker, width: 0.8),
                ),
              ),
              // Crayon body
              Container(
                width: 18,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [color, darker],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              // Crayon tip (triangle)
              CustomPaint(
                size: const Size(18, 14),
                painter: _CrayonTipPainter(color: darker),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrayonTipPainter extends CustomPainter {
  final Color color;
  const _CrayonTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CrayonTipPainter old) => old.color != color;
}

class _PenTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = const Color(0xFF333333),
    );
  }

  @override
  bool shouldRepaint(covariant _PenTipPainter oldDelegate) => false;
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF555555), size: 22),
      ),
    );
  }
}

/// Single brush-size button. Shows a dot whose size matches the
/// currently-selected brush size. Tapping opens a popup above it.
class _BrushSizeButton extends StatelessWidget {
  final Key buttonKey;
  final double selectedSize;
  final double maxSize;
  final bool isOpen;
  final VoidCallback onTap;

  const _BrushSizeButton({
    required this.buttonKey,
    required this.selectedSize,
    required this.maxSize,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Visual dot scaled by selected size relative to max.
    final dot = 6.0 + (selectedSize / maxSize) * 18.0;
    return GestureDetector(
      key: buttonKey,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isOpen ? 46 : 42,
        height: isOpen ? 46 : 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? const Color(0xFF42A5F5) : Colors.grey[300]!,
            width: isOpen ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Container(
          width: dot,
          height: dot,
          decoration: const BoxDecoration(
            color: Color(0xFF42A5F5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Popup shown above the brush-size button. Three vertically-stacked
/// options, each a tappable pill with a dot whose size matches that
/// brush width. The currently-selected option is highlighted.
class _BrushSizePopup extends StatelessWidget {
  final List<double> sizes;
  final double selected;
  final ValueChanged<double> onSelect;

  const _BrushSizePopup({
    required this.sizes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final maxSize = sizes.last;
    // Render largest at top, smallest at bottom
    final ordered = sizes.reversed.toList();
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ordered.map((s) {
          final isSelected = s == selected;
          final dot = 6.0 + (s / maxSize) * 18.0;
          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF42A5F5).withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF42A5F5)
                      : const Color(0xFF555555),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EraserButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _EraserButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: active ? 48 : 42,
        height: active ? 48 : 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
            width: active ? 2.5 : 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
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
        child: Icon(
          Icons.auto_fix_off_rounded,
          color: active ? const Color(0xFFFF6B6B) : const Color(0xFF555555),
          size: 22,
        ),
      ),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _BigBtn({
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
