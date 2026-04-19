import 'dart:ui';
import 'package:kids_learning/modules/guided_drawing/data/models/drawing_template.dart';

/// A single trace-and-color level, backed by a [DrawingTemplate] from the
/// shared [GuidedDrawingService] so both modules stay in sync.
class GameLevel {
  final int level;
  final DrawingTemplate template;

  /// Colour used to fill the outline in the celebration screen.
  final Color correctColor;

  const GameLevel({
    required this.level,
    required this.template,
    required this.correctColor,
  });

  String get name => template.name;
  String get outlineImage => template.outlineImage;
  String get referenceImage => template.referenceImage;
  bool get isNetworkImage => template.isNetworkImage;
}

/// Big, kid-friendly colour palette shown in the coloring phase.
/// Full 64-crayon palette (same as the old drawing module) — every
/// level uses this same palette via horizontal scroll.
const kidColorPalette = <Color>[
  Color(0xFFED0A3F), // Red
  Color(0xFF0066FF), // Blue
  Color(0xFF1CAC78), // Green
  Color(0xFFFCE883), // Yellow
  Color(0xFFFF7538), // Orange
  Color(0xFF8359A3), // Purple
  Color(0xFFFFA6C9), // Pink
  Color(0xFFA52A2A), // Brown
  Color(0xFF000000), // Black
  Color(0xFF95918C), // Gray
  Color(0xFFFFFFFF), // White
  Color(0xFF76D7EA), // Sky
  Color(0xFFC40233), // Cherry
  Color(0xFFFD0E35), // Scarlet
  Color(0xFFC32148), // Rose
  Color(0xFFCA3435), // Brick
  Color(0xFFFF5349), // Tomato
  Color(0xFFE6335F), // Berry
  Color(0xFFFF43A4), // Hot pink
  Color(0xFFFC89AC), // Blush
  Color(0xFFF664AF), // Magenta
  Color(0xFFFB7EFD), // Orchid
  Color(0xFFFFBCD9), // Cotton
  Color(0xFFFDD7E4), // Petal
  Color(0xFFDA3287), // Fuchsia
  Color(0xFFF75394), // Flamingo
  Color(0xFFC54B8C), // Plum
  Color(0xFFFE4C40), // Coral
  Color(0xFFFF681F), // Tangerine
  Color(0xFFFF7F49), // Mango
  Color(0xFFFF9F80), // Peach
  Color(0xFFFFAE42), // Honey
  Color(0xFFFFB653), // Amber
  Color(0xFFFFCF48), // Gold
  Color(0xFFFCD975), // Butter
  Color(0xFFFFFF99), // Lemon
  Color(0xFFF8E473), // Sunny
  Color(0xFFE7C697), // Sand
  Color(0xFFC5E384), // Lime
  Color(0xFFADFF2F), // Neon
  Color(0xFF87A96B), // Sage
  Color(0xFFA8E4A0), // Mint
  Color(0xFF01786F), // Teal
  Color(0xFF2E8B57), // Forest
  Color(0xFF45CEA2), // Jade
  Color(0xFF006400), // Clover
  Color(0xFF17806D), // Pine
  Color(0xFF8B8680), // Stone
  Color(0xFF1DACD6), // Aqua
  Color(0xFF2EB4E6), // Ocean
  Color(0xFF1974D2), // Cobalt
  Color(0xFF2B6CC4), // Royal
  Color(0xFF000080), // Navy
  Color(0xFF93CCEA), // Cloud
  Color(0xFF1FCECB), // Turquoise
  Color(0xFF008080), // Deep sea
  Color(0xFF7442C8), // Violet
  Color(0xFF5D35D1), // Grape
  Color(0xFFA2A2D0), // Lilac
  Color(0xFFD6AEDD), // Lavender
  Color(0xFF9E5B40), // Cocoa
  Color(0xFF8A3324), // Rust
  Color(0xFFD68A59), // Caramel
  Color(0xFFCD9575), // Tan
];

/// Per-template "ideal" fill colour for the celebration screen.
/// Falls back to red if the template ID isn't mapped.
Color correctColorFor(String templateId) {
  const map = <String, Color>{
    'apple': Color(0xFFE53935),
    'cat': Color(0xFF8B5A2B),
    'fish': Color(0xFF2196F3),
    'banana': Color(0xFFFFEB3B),
    'leaf': Color(0xFF4CAF50),
  };
  return map[templateId] ?? const Color(0xFFE53935);
}
