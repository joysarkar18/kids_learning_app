import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'image_loader.dart';

/// Coloring canvas that only lets brush strokes appear **inside** the
/// closed outline regions.
///
/// Mask algorithm:
///  1. Render outline PNG at canvas resolution.
///  2. **Dilate** dark pixels by a radius so thin gaps in the outline
///     (stem↔body, leaf↔body) get sealed shut.
///  3. Flood-fill from every edge pixel — anything reachable = "outside".
///  4. Pixels NOT reached and NOT dark (original) = **inside** → paintable.
class MaskedColoringCanvas extends StatefulWidget {
  final String outlineAsset;
  final Color brushColor;
  final double brushSize;
  final bool isEraser;
  final VoidCallback? onStrokeAdded;

  /// Fires on every pan so the parent can draw a brush cursor.
  final ValueChanged<Offset?> onPenPositionChanged;

  const MaskedColoringCanvas({
    super.key,
    required this.outlineAsset,
    required this.brushColor,
    this.brushSize = 28.0,
    this.isEraser = false,
    this.onStrokeAdded,
    this.onPenPositionChanged = _noOp,
  });

  static void _noOp(Offset? _) {}

  @override
  State<MaskedColoringCanvas> createState() => MaskedColoringCanvasState();
}

class MaskedColoringCanvasState extends State<MaskedColoringCanvas> {
  ui.Image? _outlineImg;
  ui.Image? _mask;
  /// Outline-only image — dark outline pixels on a transparent background,
  /// rendered at canvas size with the same `_containRect` positioning as
  /// the fill mask. Drawn on top of paint so outline is visible without
  /// the white PNG background covering the colour.
  ui.Image? _outlineOnly;
  Size? _preparedSize;

  final List<_BrushStroke> _strokes = [];
  List<Offset> _currentPoints = [];

  bool get hasStrokes => _strokes.isNotEmpty;

  void undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void clearAll() {
    setState(() {
      _strokes.clear();
      _currentPoints = [];
    });
  }

  /// Renders the current painted canvas (white background + masked
  /// colour strokes + outline on top) to a [ui.Image] so the
  /// celebration screen can show what the kid actually coloured.
  Future<ui.Image?> captureColoredImage() async {
    if (_preparedSize == null || _outlineImg == null) return null;
    final size = _preparedSize!;
    final w = size.width.toInt();
    final h = size.height.toInt();
    final rect = Offset.zero & size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background (for a clean celebration look)
    canvas.drawRect(rect, Paint()..color = Colors.white);

    // Masked brush strokes — reuse the same painter logic
    if (_mask != null && _strokes.isNotEmpty) {
      canvas.saveLayer(rect, Paint());
      for (final s in _strokes) {
        _paintStrokeStatic(canvas, s.points, s.color, s.width,
            erase: s.isEraser);
      }
      canvas.drawImage(
          _mask!, Offset.zero, Paint()..blendMode = BlendMode.dstIn);
      canvas.restore();
    }

    // Outline on top — prefer the outline-only image (aspect-preserving,
    // transparent background). Fall back to raw PNG on first frame.
    if (_outlineOnly != null) {
      canvas.drawImage(_outlineOnly!, Offset.zero, Paint());
    } else {
      final src = Rect.fromLTWH(0, 0, _outlineImg!.width.toDouble(),
          _outlineImg!.height.toDouble());
      final dst = _containRect(src, size);
      canvas.drawImageRect(_outlineImg!, src, dst,
          Paint()..filterQuality = FilterQuality.medium);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    picture.dispose();
    return img;
  }

  static void _paintStrokeStatic(
    Canvas canvas,
    List<Offset> pts,
    Color color,
    double width, {
    bool erase = false,
  }) {
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (erase) paint.blendMode = BlendMode.clear;
    canvas.drawPath(path, paint);
  }

  // ── Image loading ──

  @override
  void initState() {
    super.initState();
    _loadOutline();
  }

  @override
  void didUpdateWidget(covariant MaskedColoringCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outlineAsset != widget.outlineAsset) {
      _outlineImg = null;
      _mask = null;
      _preparedSize = null;
      _strokes.clear();
      _currentPoints = [];
      _loadOutline();
    }
  }

  Future<void> _loadOutline() async {
    final img = await loadImageFromPathOrUrl(widget.outlineAsset);
    if (mounted && img != null) setState(() => _outlineImg = img);
  }

  // ── Mask with dilation + edge flood-fill ──

  Future<void> _prepareMask(Size canvasSize) async {
    if (_outlineImg == null) return;
    if (_preparedSize == canvasSize && _mask != null) return;
    _preparedSize = canvasSize;

    final w = canvasSize.width.toInt();
    final h = canvasSize.height.toInt();
    final totalPixels = w * h;

    // Render outline at canvas size
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white);
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

    final pixels = byteData.buffer.asUint8List();

    // Step 1: classify dark / light (threshold 200 catches anti-aliased
    // gray edge pixels that are part of the outline but not fully black)
    final isDark = Uint8List(totalPixels);
    for (int i = 0; i < totalPixels; i++) {
      final off = i * 4;
      final avg = (pixels[off] + pixels[off + 1] + pixels[off + 2]) ~/ 3;
      if (avg < 200) isDark[i] = 1;
    }

    // Step 2: dilate isDark by R to seal tiny gaps in the outline
    // (stem↔body, leaf↔body joints, anti-aliased thin spots).
    const dilateR = 4;
    final dilated = _dilate(isDark, w, h, dilateR);

    // Step 3: flood-fill from all 4 edges through NOT-dilated pixels.
    // This finds everything that is *clearly* outside the shape.
    // Multiple enclosed regions (apple body, leaf interior, stem interior)
    // are ALL correctly left un-filled because the flood can't reach them.
    final isOutsideLoose = Uint8List(totalPixels);
    final queue = Queue<int>();

    void seed(int idx) {
      if (dilated[idx] == 0 && isOutsideLoose[idx] == 0) {
        isOutsideLoose[idx] = 1;
        queue.add(idx);
      }
    }

    for (int x = 0; x < w; x++) {
      seed(x);
      seed((h - 1) * w + x);
    }
    for (int y = 1; y < h - 1; y++) {
      seed(y * w);
      seed(y * w + w - 1);
    }

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final x = idx % w;
      final y = idx ~/ w;
      if (x > 0) seed(idx - 1);
      if (x < w - 1) seed(idx + 1);
      if (y > 0) seed(idx - w);
      if (y < h - 1) seed(idx + w);
    }

    // Step 4: dilate isOutsideLoose by the SAME radius so that the
    // "outside" region grows back up to the real outline. This undoes
    // the outward expansion that the step-2 dilation caused, without
    // leaking into the interior (because isDark still blocks).
    final isOutside = _dilate(isOutsideLoose, w, h, dilateR);

    // Step 5: paintable = (NOT outside) OR on the outline itself.
    // Including dark outline pixels means color can touch the outline
    // with no visible gap (the outline drawn on top hides it).
    final maskPixels = Uint8List(totalPixels * 4);
    for (int i = 0; i < totalPixels; i++) {
      final off = i * 4;
      if (isOutside[i] == 0 || isDark[i] == 1) {
        maskPixels[off] = 255;
        maskPixels[off + 1] = 255;
        maskPixels[off + 2] = 255;
        maskPixels[off + 3] = 255;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        maskPixels, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final mask = await completer.future;

    // Build outline-only image (dark pixels black+opaque, rest transparent).
    // Same dimensions and contain positioning as the fill mask → can be
    // drawn at Offset.zero without stretching.
    final outlinePixels = Uint8List(totalPixels * 4);
    for (int i = 0; i < totalPixels; i++) {
      if (isDark[i] == 1) {
        final off = i * 4;
        outlinePixels[off + 3] = 255; // opaque black (RGB stays 0)
      }
    }
    final outlineCompleter = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      outlinePixels,
      w,
      h,
      ui.PixelFormat.rgba8888,
      outlineCompleter.complete,
    );
    final outlineOnly = await outlineCompleter.future;

    if (mounted) {
      setState(() {
        _mask = mask;
        _outlineOnly = outlineOnly;
      });
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (_outlineImg != null &&
            (_preparedSize != size || _mask == null)) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _prepareMask(size));
        }

        if (_outlineImg == null) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8D6E63)));
        }

        return GestureDetector(
          onPanStart: (d) {
            setState(() => _currentPoints = [d.localPosition]);
            widget.onPenPositionChanged(d.localPosition);
          },
          onPanUpdate: (d) {
            setState(
                () => _currentPoints = [..._currentPoints, d.localPosition]);
            widget.onPenPositionChanged(d.localPosition);
          },
          onPanEnd: (_) {
            setState(() {
              if (_currentPoints.length > 1) {
                _strokes.add(_BrushStroke(
                  List.of(_currentPoints),
                  widget.brushColor,
                  widget.brushSize,
                  isEraser: widget.isEraser,
                ));
                widget.onStrokeAdded?.call();
              }
              _currentPoints = [];
            });
            widget.onPenPositionChanged(null);
          },
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _MaskedBrushPainter(
                outlineImage: _outlineImg,
                outlineOnly: _outlineOnly,
                mask: _mask,
                // Pass COPIES so the painter's shouldRepaint can detect
                // length changes (undo/clear). Without this, both `old`
                // and `new` reference the same mutated list.
                strokes: List.of(_strokes),
                currentStroke: List.of(_currentPoints),
                currentColor: widget.brushColor,
                brushSize: widget.brushSize,
                isEraserActive: widget.isEraser,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dilates a binary mask by [r] pixels using a circular kernel.
  /// Returns a new mask where pixel p is 1 if any pixel within radius r
  /// of p was 1 in the input.
  static Uint8List _dilate(Uint8List src, int w, int h, int r) {
    final out = Uint8List(w * h);
    final r2 = r * r;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (src[y * w + x] == 1) {
          final yMin = (y - r).clamp(0, h - 1);
          final yMax = (y + r).clamp(0, h - 1);
          final xMin = (x - r).clamp(0, w - 1);
          final xMax = (x + r).clamp(0, w - 1);
          for (int ny = yMin; ny <= yMax; ny++) {
            final dy = ny - y;
            for (int nx = xMin; nx <= xMax; nx++) {
              final dx = nx - x;
              if (dx * dx + dy * dy <= r2) {
                out[ny * w + nx] = 1;
              }
            }
          }
        }
      }
    }
    return out;
  }

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

class _BrushStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
  const _BrushStroke(
    this.points,
    this.color,
    this.width, {
    this.isEraser = false,
  });
}

// ─────────────────────────────────────────────────────────────────

class _MaskedBrushPainter extends CustomPainter {
  final ui.Image? outlineImage;
  /// Pre-built outline-only image (dark pixels opaque, rest transparent).
  /// Shares the fill mask's dimensions and contain positioning so it
  /// aligns perfectly and preserves the outline's aspect ratio.
  final ui.Image? outlineOnly;
  final ui.Image? mask;
  final List<_BrushStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double brushSize;
  final bool isEraserActive;

  _MaskedBrushPainter({
    required this.outlineImage,
    required this.outlineOnly,
    required this.mask,
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.brushSize,
    required this.isEraserActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outlineImage == null) return;

    final rect = Offset.zero & size;
    final src = Rect.fromLTWH(
        0, 0, outlineImage!.width.toDouble(), outlineImage!.height.toDouble());
    final dst = MaskedColoringCanvasState._containRect(src, size);

    // 1. Hatching background
    _drawHatch(canvas, size);

    // 2. Masked brush strokes (only inside)
    if (mask != null && (strokes.isNotEmpty || currentStroke.length > 1)) {
      canvas.saveLayer(rect, Paint());

      for (final s in strokes) {
        _drawStroke(canvas, s.points, s.color, s.width, erase: s.isEraser);
      }
      if (currentStroke.length > 1) {
        _drawStroke(canvas, currentStroke, currentColor, brushSize,
            erase: isEraserActive);
      }

      canvas.drawImage(mask!, Offset.zero, Paint()..blendMode = BlendMode.dstIn);
      canvas.restore();
    }

    // 3. Outline on top — the outline-only image preserves aspect ratio
    // and has a transparent background so painted colour stays visible.
    if (outlineOnly != null) {
      canvas.drawImage(outlineOnly!, Offset.zero, Paint());
    } else {
      // First-frame fallback while outlineOnly is being prepared.
      canvas.drawImageRect(
          outlineImage!, src, dst, Paint()..filterQuality = FilterQuality.medium);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> pts,
    Color color,
    double width, {
    bool erase = false,
  }) {
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

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (erase) {
      // Inside the saveLayer, BlendMode.clear wipes the painted pixels
      // back to transparent — the hatching shows through again.
      paint.blendMode = BlendMode.clear;
    }
    canvas.drawPath(path, paint);
  }

  void _drawHatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    const gap = 10.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MaskedBrushPainter old) {
    return old.strokes.length != strokes.length ||
        old.currentStroke.length != currentStroke.length ||
        old.mask != mask ||
        old.outlineImage != outlineImage ||
        old.outlineOnly != outlineOnly ||
        old.currentColor != currentColor ||
        old.isEraserActive != isEraserActive;
  }
}
