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

class _GameContentState extends State<_GameContent> {
  late final ConfettiController _confetti;

  // Keys for child canvas widgets
  final _traceKey = GlobalKey<AutoTraceCanvasState>();
  final _colorKey = GlobalKey<MaskedColoringCanvasState>();

  // Pen cursor position (null = finger up)
  Offset? _penPos;
  bool _hasColorStrokes = false;

  // Captured traced outline image (passed to coloring phase)
  ui.Image? _tracedOutline;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  // ── Actions ──

  /// Called automatically by AutoTraceCanvas when ≥ 75 % traced.
  void _onTracingComplete() async {
    _confetti.play();
    AudioPlayerService.instance.playUi(key: UiAudioKey.image_fill);

    // Capture the kid's traced outline so coloring shows THEIR drawing
    final captured = await _traceKey.currentState?.captureTracedOutline();
    if (mounted) {
      setState(() => _tracedOutline = captured);
    }

    // Brief pause so the kid sees the completed outline before transition
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      context.read<TraceColorBloc>().add(const FinishTracing());
    }
  }

  void _finishColoring() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _confetti.play();
    context.read<TraceColorBloc>().add(const FinishColoring());
  }

  void _nextLevel() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    DailyChallengeService.instance.reportProgress('guided_drawing');
    _hasColorStrokes = false;
    _penPos = null;
    _tracedOutline = null;
    context.read<TraceColorBloc>().add(const NextLevel());
  }

  void _reset() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _traceKey.currentState?.clearAll();
    _colorKey.currentState?.clearAll();
    _hasColorStrokes = false;
    _penPos = null;
    _tracedOutline = null;
    context.read<TraceColorBloc>().add(const ResetLevel());
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
                          position: _penPos!, color: state.selectedColor)
                      : _PenCursor(position: _penPos!),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          // Name + thumbnail
          if (active != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                    active.level.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      active.level.referenceImage,
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          // Undo
          if (isTracing &&
              (_traceKey.currentState?.hasStrokes ?? false))
            _IconBtn(icon: Icons.undo_rounded, onTap: _undoTrace),
          if (isColoring && _hasColorStrokes)
            _IconBtn(icon: Icons.undo_rounded, onTap: _undoColor),
          // Reset
          if (active != null && active.phase != GamePhase.celebration)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child:
                  _IconBtn(icon: Icons.refresh_rounded, onTap: _reset),
            ),
        ],
      ),
    );
  }

  // ────────────────────── Canvas ──────────────────────

  Widget _buildCanvas(TraceColorState state) {
    if (state is TraceColorLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8D6E63)));
    }
    if (state is TraceColorError) {
      return Center(
        child: Text(state.message,
            style: const TextStyle(color: Colors.red, fontSize: 16)),
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
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _canvasDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AutoTraceCanvas(
          key: _traceKey,
          outlineAsset: state.level.outlineImage,
          onComplete: _onTracingComplete,
          onPenPositionChanged: (pos) => setState(() => _penPos = pos),
        ),
      ),
    );
  }

  // ── Coloring (brush painting clipped inside outlines) ──

  Widget _coloringCanvas(TraceColorActive state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _canvasDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MaskedColoringCanvas(
          key: _colorKey,
          outlineAsset: state.level.outlineImage,
          tracedOutlineOverlay: _tracedOutline,
          brushColor: state.selectedColor,
          brushSize: 28,
          onStrokeAdded: () => setState(() => _hasColorStrokes = true),
          onPenPositionChanged: (pos) => setState(() => _penPos = pos),
        ),
      ),
    );
  }

  // ── Celebration ──

  Widget _celebrationView(TraceColorActive state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              color: state.level.correctColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color:
                      state.level.correctColor.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
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
            style:
                const TextStyle(fontSize: 16, color: Color(0xFF777777)),
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

  /// Tracing bottom: just a Skip button (tracing auto-completes).
  Widget _tracingBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: _BigBtn(
        label: 'Skip',
        icon: Icons.skip_next_rounded,
        color: const Color(0xFF90A4AE),
        onTap: () {
          _confetti.play();
          AudioPlayerService.instance
              .playUi(key: UiAudioKey.button_press);
          context.read<TraceColorBloc>().add(const FinishTracing());
        },
      ),
    );
  }

  /// Coloring bottom: 3 color swatches + Done.
  Widget _coloringBottom(TraceColorActive state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color swatches
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: state.level.allColors.map((c) {
              final selected = state.selectedColor == c;
              return GestureDetector(
                onTap: () {
                  AudioPlayerService.instance
                      .playUi(key: UiAudioKey.button_press);
                  context.read<TraceColorBloc>().add(PickColor(c));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: selected ? 72 : 64,
                  height: selected ? 72 : 64,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF333333)
                          : Colors.grey[300]!,
                      width: selected ? 4 : 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.5),
                              blurRadius: 12,
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
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 30)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
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
}

// ──────────────────────────────────────────────────────────────────
//  Small helper widgets
// ──────────────────────────────────────────────────────────────────

/// Pen cursor that floats above the canvas, following the kid's finger.
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
              CustomPaint(
                size: const Size(14, 12),
                painter: _PenTipPainter(),
              ),
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
        .withLightness(
            (HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1))
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
