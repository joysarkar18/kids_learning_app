import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'image_loader.dart';

/// Smart tracing canvas for kids.
///
/// How it works:
///  1. Builds an "outline-only" mask from the PNG (dark pixels → opaque,
///     white background → transparent).
///  2. Shows the mask as a **faint dashed guide**.
///  3. As the kid draws, thick invisible strokes are intersected with the
///     mask using `BlendMode.srcIn`. This reveals the **perfect solid
///     outline** wherever the kid drew *near* it — the "auto-snap" effect.
///  4. A low-res grid tracks which outline cells have been traced.
///     When coverage ≥ 75 %, [onComplete] fires → auto-transition to
///     coloring.
class AutoTraceCanvas extends StatefulWidget {
  final String outlineAsset;

  /// Called once when the kid has traced enough of the outline.
  final VoidCallback onComplete;

  /// Fires on every pan event so the parent can draw a pen cursor.
  final ValueChanged<Offset?> onPenPositionChanged;

  const AutoTraceCanvas({
    super.key,
    required this.outlineAsset,
    required this.onComplete,
    required this.onPenPositionChanged,
  });

  @override
  State<AutoTraceCanvas> createState() => AutoTraceCanvasState();
}

class AutoTraceCanvasState extends State<AutoTraceCanvas> {
  // ── Images ──
  ui.Image? _outlineImg; // raw PNG
  ui.Image? _outlineMask; // dark pixels opaque, rest transparent
  Size? _preparedSize;

  // ── Strokes (local, smooth 60 fps) ──
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];

  bool get hasStrokes => _strokes.isNotEmpty;

  // ── Completion grid ──
  static const _gridRes = 35;
  List<bool> _outlineCells = [];
  List<bool> _tracedCells = [];
  int _totalOutlineCells = 0;
  bool _completed = false;
  double completionRatio = 0;

  /// Top-center point of the outline (for pen hint positioning).
  /// Null until the outline has been analysed.
  Offset? startPoint;

  // ── Public API ──

  /// Returns the FULL outline mask (dark outline pixels on a transparent
  /// background) for the coloring phase to draw on top of the painted
  /// canvas.
  ///
  /// We always hand back the full outline — regardless of how much the
  /// kid traced — so partial tracers still see a complete outline to
  /// colour inside of. The auto-snap during tracing visually looks
  /// identical to the full outline anyway, so this is seamless.
  Future<ui.Image?> captureTracedOutline() async {
    return _outlineMask;
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
      _rebuildTracedCells();
    }
  }

  void clearAll() {
    setState(() {
      _strokes.clear();
      _current = [];
      _tracedCells = List.filled(_gridRes * _gridRes, false);
      completionRatio = 0;
      _completed = false;
    });
    widget.onPenPositionChanged(null);
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  @override
  void didUpdateWidget(covariant AutoTraceCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outlineAsset != widget.outlineAsset) {
      _outlineImg = null;
      _outlineMask = null;
      _preparedSize = null;
      _strokes.clear();
      _current = [];
      _completed = false;
      completionRatio = 0;
      _loadOutline();
    }
  }

  // ── Image loading & mask creation ──

  Future<void> _loadOutline() async {
    final img = await loadImageFromPathOrUrl(widget.outlineAsset);
    if (mounted && img != null) setState(() => _outlineImg = img);
  }

  Future<void> _prepareAssets(Size canvasSize) async {
    if (_outlineImg == null) return;
    if (_preparedSize == canvasSize && _outlineMask != null) return;
    _preparedSize = canvasSize;

    final w = canvasSize.width.toInt();
    final h = canvasSize.height.toInt();

    // Render outline scaled to canvas size
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );
    final src = Rect.fromLTWH(
        0, 0, _outlineImg!.width.toDouble(), _outlineImg!.height.toDouble());
    final dst = _containRect(src, canvasSize);
    c.drawImageRect(
        _outlineImg!, src, dst, Paint()..filterQuality = FilterQuality.medium);
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(w, h);
    picture.dispose();

    final byteData =
        await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
    rendered.dispose();
    if (byteData == null) return;

    final pixels = Uint8List.fromList(byteData.buffer.asUint8List());

    // ── Build outline-only mask (dark → opaque black, light → transparent) ──
    for (int i = 0; i < pixels.length; i += 4) {
      final avg = (pixels[i] + pixels[i + 1] + pixels[i + 2]) ~/ 3;
      if (avg < 200) {
        pixels[i] = 0;
        pixels[i + 1] = 0;
        pixels[i + 2] = 0;
        pixels[i + 3] = 255; // opaque black
      } else {
        pixels[i] = 0;
        pixels[i + 1] = 0;
        pixels[i + 2] = 0;
        pixels[i + 3] = 0; // transparent
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        pixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final mask = await completer.future;

    // ── Build completion grid ──
    _buildCompletionGrid(byteData, w, h);

    if (mounted) setState(() => _outlineMask = mask);
  }

  void _buildCompletionGrid(ByteData bytes, int imgW, int imgH) {
    _outlineCells = List.filled(_gridRes * _gridRes, false);
    _tracedCells = List.filled(_gridRes * _gridRes, false);
    _totalOutlineCells = 0;

    final cellW = imgW / _gridRes;
    final cellH = imgH / _gridRes;

    int? topDarkY;
    int topDarkXSum = 0;
    int topDarkXCount = 0;

    for (int gy = 0; gy < _gridRes; gy++) {
      for (int gx = 0; gx < _gridRes; gx++) {
        // Sample center of each grid cell
        final px = (gx * cellW + cellW / 2).toInt().clamp(0, imgW - 1);
        final py = (gy * cellH + cellH / 2).toInt().clamp(0, imgH - 1);
        final idx = (py * imgW + px) * 4;
        final avg = (bytes.getUint8(idx) +
                bytes.getUint8(idx + 1) +
                bytes.getUint8(idx + 2)) ~/
            3;
        if (avg < 200) {
          _outlineCells[gy * _gridRes + gx] = true;
          _totalOutlineCells++;
          // Track topmost dark row and its X range for start-point hint
          if (topDarkY == null || gy < topDarkY) {
            topDarkY = gy;
            topDarkXSum = gx;
            topDarkXCount = 1;
          } else if (gy == topDarkY) {
            topDarkXSum += gx;
            topDarkXCount++;
          }
        }
      }
    }

    // Start point = centre of the topmost dark row, in pixel coordinates
    if (topDarkY != null && topDarkXCount > 0) {
      final startGx = topDarkXSum / topDarkXCount;
      startPoint = Offset(
        (startGx + 0.5) * cellW,
        (topDarkY + 0.5) * cellH,
      );
    }
  }

  // ── Completion tracking ──

  void _markTracedCells(List<Offset> points, Size canvasSize) {
    for (final pt in points) {
      final gx =
          (pt.dx / canvasSize.width * _gridRes).clamp(0, _gridRes - 1).toInt();
      final gy = (pt.dy / canvasSize.height * _gridRes)
          .clamp(0, _gridRes - 1)
          .toInt();
      // Mark only the exact cell — the 34px snap width already gives
      // tolerance, so no need to inflate with neighbours.
      _tracedCells[gy * _gridRes + gx] = true;
    }
    _checkCompletion();
  }

  void _rebuildTracedCells() {
    _tracedCells = List.filled(_gridRes * _gridRes, false);
    final size = _preparedSize;
    if (size == null) return;
    for (final stroke in _strokes) {
      _markTracedCells(stroke, size);
    }
  }

  void _checkCompletion() {
    if (_totalOutlineCells == 0 || _completed) return;
    int traced = 0;
    for (int i = 0; i < _outlineCells.length; i++) {
      if (_outlineCells[i] && _tracedCells[i]) traced++;
    }
    completionRatio = traced / _totalOutlineCells;

    if (completionRatio >= 0.95 && !_completed) {
      _completed = true;
      widget.onComplete();
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (_outlineImg != null &&
            (_preparedSize != size || _outlineMask == null)) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _prepareAssets(size));
        }

        if (_outlineImg == null) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8D6E63)));
        }

        return GestureDetector(
          onPanStart: (d) {
            setState(() => _current = [d.localPosition]);
            widget.onPenPositionChanged(d.localPosition);
          },
          onPanUpdate: (d) {
            setState(() => _current = [..._current, d.localPosition]);
            widget.onPenPositionChanged(d.localPosition);
          },
          onPanEnd: (_) {
            if (_current.length > 1) {
              _strokes.add(List.of(_current));
              _markTracedCells(_current, size);
            }
            setState(() => _current = []);
            widget.onPenPositionChanged(null);
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _AutoTracePainter(
                outlineImage: _outlineImg,
                outlineMask: _outlineMask,
                strokes: _strokes,
                currentStroke: _current,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Geometry ──

  static Rect _containRect(Rect src, Size canvas) {
    final imgAspect = src.width / src.height;
    final canvasAspect = canvas.width / canvas.height;
    double w, h;
    if (imgAspect > canvasAspect) {
      w = canvas.width;
      h = canvas.width / imgAspect;
    } else {
      h = canvas.height;
      w = canvas.height * imgAspect;
    }
    return Rect.fromLTWH(
        (canvas.width - w) / 2, (canvas.height - h) / 2, w, h);
  }
}

// ─────────────────────────────────────────────────────────────────
//  Painter
// ─────────────────────────────────────────────────────────────────

class _AutoTracePainter extends CustomPainter {
  final ui.Image? outlineImage;
  final ui.Image? outlineMask;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  /// How wide the "snap tolerance" is — kid can be this many px off.
  static const _snapWidth = 34.0;

  _AutoTracePainter({
    required this.outlineImage,
    required this.outlineMask,
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outlineImage == null) return;
    final rect = Offset.zero & size;

    // ── 1. Diagonal hatch background ──
    _drawHatch(canvas, size);

    if (outlineMask == null) return;

    final hasAny = strokes.isNotEmpty || currentStroke.length > 1;

    // ── 2. Faint continuous outline guide (always visible) ──
    // Serves as a clear "trace me" hint for the kid.
    canvas.saveLayer(
        rect, Paint()..color = const Color.fromARGB(70, 255, 255, 255));
    canvas.drawImage(outlineMask!, Offset.zero, Paint());
    canvas.restore();

    // ── 3. Solid outline where the kid traced (auto-snap reveal) ──
    if (!hasAny) return;

    canvas.saveLayer(rect, Paint());

    // Draw kid's thick strokes — opaque shape used only as a clip area.
    final snapPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _snapWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final pts in strokes) {
      canvas.drawPath(_buildPath(pts), snapPaint);
    }
    if (currentStroke.length > 1) {
      canvas.drawPath(_buildPath(currentStroke), snapPaint);
    }

    // srcIn: keep source (outline mask) where destination (strokes) exists.
    // Result: perfect solid outline visible only near where the kid drew.
    canvas.drawImage(
        outlineMask!, Offset.zero, Paint()..blendMode = BlendMode.srcIn);

    canvas.restore();
  }

  // ── Helpers ──

  Path _buildPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    if (pts.length > 1) path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  void _drawHatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const gap = 10.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawLine(
          Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AutoTracePainter old) {
    return old.strokes.length != strokes.length ||
        old.currentStroke.length != currentStroke.length ||
        old.outlineMask != outlineMask ||
        old.outlineImage != outlineImage;
  }
}
