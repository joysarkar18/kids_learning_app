import 'dart:ui';

class GameLevel {
  final int level;
  final String name;
  final String outlineImage;
  final String referenceImage;
  final Color correctColor;
  final List<Color> allColors; // 3 colors: 1 correct + 2 decoys (shuffled)

  const GameLevel({
    required this.level,
    required this.name,
    required this.outlineImage,
    required this.referenceImage,
    required this.correctColor,
    required this.allColors,
  });
}

/// All game levels. Add new levels by adding outline + reference PNGs to
/// assets/guided_drawing/<name>/ and registering them here.
const gameLevels = <GameLevel>[
  GameLevel(
    level: 1,
    name: 'Apple',
    outlineImage: 'assets/guided_drawing/apple/outline.png',
    referenceImage: 'assets/guided_drawing/apple/reference.png',
    correctColor: Color(0xFFE53935), // Red
    allColors: [
      Color(0xFFE53935), // Red  (correct)
      Color(0xFFFFB300), // Amber (wrong)
      Color(0xFF2196F3), // Blue  (wrong)
    ],
  ),
  // ── Add more levels below ──
  // GameLevel(
  //   level: 2,
  //   name: 'Fish',
  //   outlineImage: 'assets/guided_drawing/fish/outline.png',
  //   referenceImage: 'assets/guided_drawing/fish/reference.png',
  //   correctColor: Color(0xFF2196F3),
  //   allColors: [Color(0xFFE53935), Color(0xFF2196F3), Color(0xFF4CAF50)],
  // ),
];
