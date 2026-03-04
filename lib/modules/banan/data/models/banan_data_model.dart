import 'package:characters/characters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BananLanguage { english, bengali }

// ─────────────────────────────────────────────────────────────────
//  Letter tile (each draggable piece)
// ─────────────────────────────────────────────────────────────────
class BananLetterTile {
  final String id; // unique: "letter_index" e.g. "বি_0", "ড়া_1"
  final String letter; // the grapheme cluster shown on the tile

  const BananLetterTile({required this.id, required this.letter});
}

// ─────────────────────────────────────────────────────────────────
//  Problem model
// ─────────────────────────────────────────────────────────────────
class BananProblemModel {
  final String id;
  final String word;
  final BananLanguage language;
  final int difficulty;
  final String questionText;
  final String questionImageUrl;
  final String questionAudioUrl;
  final String correctAudioUrl;

  const BananProblemModel({
    required this.id,
    required this.word,
    required this.language,
    required this.difficulty,
    required this.questionText,
    required this.questionImageUrl,
    this.questionAudioUrl = '',
    this.correctAudioUrl = '',
  });

  // ── CORE FIX: use the `characters` package for proper Unicode grapheme
  // cluster splitting. This keeps Bengali vowel signs (matras) attached:
  //   "বিড়াল" → ["বি", "ড়া", "ল"]   ✅
  // instead of splitting on raw code units:
  //   "বিড়াল" → ["ব","ি","ড","়","া","ল"]  ❌
  List<String> get letters => word.characters.toList();

  /// Shuffled tiles with unique ids so duplicate letters are handled correctly.
  List<BananLetterTile> get shuffledTiles {
    final tiles = letters.asMap().entries.map((e) {
      return BananLetterTile(id: '${e.value}_${e.key}', letter: e.value);
    }).toList()..shuffle();
    return tiles;
  }

  factory BananProblemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BananProblemModel(
      id: doc.id,
      word: data['word'] ?? '',
      language: data['language'] == 'bengali'
          ? BananLanguage.bengali
          : BananLanguage.english,
      difficulty: data['difficulty'] ?? 1,
      questionText: data['question_text'] ?? '',
      questionImageUrl: data['question_image_url'] ?? '',
      questionAudioUrl: data['question_audio_url'] ?? '',
      correctAudioUrl: data['correct_audio_url'] ?? '',
    );
  }
}
