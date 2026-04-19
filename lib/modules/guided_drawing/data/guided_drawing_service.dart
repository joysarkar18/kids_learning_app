import 'package:kids_learning/services/remote_config_service.dart';
import 'models/drawing_template.dart';

/// Loads drawing templates.
///
/// For now, templates are registered here as asset paths.
/// To add a new drawing:
///   1. Put outline.png + reference.png in assets/guided_drawing/<name>/
///   2. Register the folder in pubspec.yaml assets
///   3. Add an entry to [_assetTemplates] below
///
/// To switch to Firestore later, just call fetchFromFirestore()
/// and the rest of the app works as-is.
class GuidedDrawingService {
  static final GuidedDrawingService _instance =
      GuidedDrawingService._internal();
  factory GuidedDrawingService() => _instance;
  GuidedDrawingService._internal();
  static GuidedDrawingService get instance => _instance;

  List<DrawingTemplate> _templates = [];
  bool _loaded = false;

  List<DrawingTemplate> get templates => _templates;
  bool get isLoaded => _loaded;

  // ─────── Asset-based templates ───────
  // Add new entries here when you add image folders.
  static const List<DrawingTemplate> _assetTemplates = [
    DrawingTemplate(
      id: 'apple',
      name: 'Apple',
      category: 'fruit',
      outlineImage: 'assets/guided_drawing/apple/outline.png',
      referenceImage: 'assets/guided_drawing/apple/reference.png',
    ),
    // ── Add more templates below ──
    // DrawingTemplate(
    //   id: 'cat',
    //   name: 'Cat',
    //   category: 'animal',
    //   outlineImage: 'assets/guided_drawing/cat/outline.png',
    //   referenceImage: 'assets/guided_drawing/cat/reference.png',
    // ),
  ];

  /// Load from hardcoded asset list.
  void loadFromAssets() {
    if (_loaded) return;
    _templates = List.from(_assetTemplates);
    _loaded = true;
  }

  /// Load from Firebase Remote Config (preferred source).
  /// Reads parallel lists `drawing_images` (outlines) and `filled_images`
  /// (references) from [RemoteConfigService] and pairs them by index.
  /// Returns true if at least one valid pair was loaded.
  bool loadFromConfig() {
    final outlines = RemoteConfigService().drawingImages;
    final filled = RemoteConfigService().filledImages;

    final pairs = outlines.length < filled.length
        ? outlines.length
        : filled.length;
    if (pairs == 0) return false;

    _templates = List.generate(pairs, (i) {
      return DrawingTemplate(
        id: 'remote_$i',
        name: 'Drawing ${i + 1}',
        category: 'remote',
        outlineImage: outlines[i],
        referenceImage: filled[i],
      );
    });
    _loaded = true;
    return true;
  }

  /// Filter by category
  List<DrawingTemplate> byCategory(String category) =>
      _templates.where((t) => t.category == category).toList();

  // ─────── Future: Firestore ───────
  // Future<void> fetchFromFirestore() async {
  //   final snapshot = await FirebaseFirestore.instance
  //       .collection('guided_drawings')
  //       .get();
  //   _templates = snapshot.docs
  //       .map((doc) => DrawingTemplate.fromJson(doc.data()))
  //       .toList();
  //   _loaded = true;
  // }
}
