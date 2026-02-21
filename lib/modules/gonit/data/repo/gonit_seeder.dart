import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GanitSeeder {
  static Future<void> seed() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('gonit_problems');

    // Check if data already exists
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final problems = [
      // 1 per type — 6 total (arithmetic, counting, comparison,
      // missing_number, word_problem, matching)

      // ── Arithmetic ──
      _p(
        type: 'arithmetic',
        difficulty: 1,
        questionText: '২ + ১ = ?',
        answerText: '3',
        explanationText: '২ আর ১ যোগ করলে ৩ হয়।',
        options: _opts(['3', '2', '4', '1']),
      ),

      // ── Counting ──
      _p(
        type: 'counting',
        difficulty: 1,
        questionText: 'ছবিতে কতগুলো আপেল আছে?',
        answerText: '3',
        explanationText: 'ছবিতে ৩টি আপেল আছে।',
        questionImageUrl:
            'https://firebasestorage.googleapis.com/v0/b/REPLACE_WITH_YOUR_BUCKET/o/gonit%2Fapples_3.png?alt=media',
        options: _opts(['3', '2', '4', '5']),
      ),

      // ── Comparison ──
      _p(
        type: 'comparison',
        difficulty: 1,
        questionText: '৫ আর ৩ — কোনটি বড়?',
        answerText: '5',
        explanationText: '৫ সংখ্যাটি ৩ থেকে বড়।',
        options: _opts2(['5', '3']),
      ),

      // ── Missing Number ──
      _p(
        type: 'missing_number',
        difficulty: 1,
        questionText: '১, ২, ?, ৪, ৫ — ? = কত?',
        answerText: '3',
        explanationText: '১ থেকে ৫ পর্যন্ত ক্রমানুসারে ৩ বসবে।',
        options: _opts(['3', '2', '4', '6']),
      ),

      // ── Word Problem ──
      _p(
        type: 'word_problem',
        difficulty: 1,
        questionText: 'তোমার কাছে ৩টি আপেল আছে। বন্ধু আরও ২টি দিল। এখন কয়টি?',
        answerText: '5',
        explanationText: '৩ + ২ = ৫। তোমার কাছে এখন ৫টি আপেল।',
        options: _opts(['5', '4', '6', '3']),
      ),

      // ── Matching ──
      _matchingP(
        difficulty: 1,
        questionText: 'সঠিক উত্তরের সাথে মিলাও',
        explanationText: 'যোগফল মিলিয়ে দেখো!',
        matchPairs: [
          {'id': 0, 'left': '২ + ১', 'right': '৩'},
          {'id': 1, 'left': '৩ + ২', 'right': '৫'},
          {'id': 2, 'left': '৪ + ৪', 'right': '৮'},
        ],
      ),

      // ── Ordering ──
      _orderingP(
        difficulty: 1,
        questionText: 'সংখ্যাগুলো ছোট থেকে বড় সাজাও',
        explanationText: '১ থেকে ৪ পর্যন্ত ক্রমানুসারে সাজাতে হবে।',
        orderItems: [
          {'id': 0, 'text': '১', 'correct_position': 0},
          {'id': 1, 'text': '২', 'correct_position': 1},
          {'id': 2, 'text': '৩', 'correct_position': 2},
          {'id': 3, 'text': '৪', 'correct_position': 3},
        ],
      ),
    ];

    // Firestore batch limit is 500, so this is fine
    final batch = firestore.batch();
    for (final problem in problems) {
      batch.set(collection.doc(), problem);
    }
    await batch.commit();
    debugPrint('GanitSeeder: Seeded ${problems.length} gonit problems');
  }

  // ── Helper: build a problem document map ──
  static Map<String, dynamic> _p({
    required String type,
    required int difficulty,
    required String questionText,
    required String answerText,
    String explanationText = '',
    String questionImageUrl = '',
    String questionAudioUrl = '',
    required List<Map<String, dynamic>> options,
  }) {
    final indexedOptions = options.asMap().entries.map((e) {
      return {
        'id': e.key,
        'text': e.value['text'],
        'image_url': e.value['image_url'] ?? '',
        'is_correct': e.value['is_correct'] ?? false,
      };
    }).toList();

    return {
      'type': type,
      'difficulty': difficulty,
      'question_text': questionText,
      'question_image_url': questionImageUrl,
      'question_audio_url': questionAudioUrl,
      'explanation_text': explanationText,
      'answer_text': answerText,
      'options': indexedOptions,
    };
  }

  // ── Helper: build 4 MCQ options (first is correct) ──
  static List<Map<String, dynamic>> _opts(List<String> texts) {
    return [
      {'text': texts[0], 'is_correct': true},
      {'text': texts[1], 'is_correct': false},
      {'text': texts[2], 'is_correct': false},
      {'text': texts[3], 'is_correct': false},
    ];
  }

  // ── Helper: build 2 comparison options (first is correct) ──
  static List<Map<String, dynamic>> _opts2(List<String> texts) {
    return [
      {'text': texts[0], 'is_correct': true},
      {'text': texts[1], 'is_correct': false},
    ];
  }

  // ── Helper: build an ordering problem document map ──
  static Map<String, dynamic> _orderingP({
    required int difficulty,
    required String questionText,
    String explanationText = '',
    required List<Map<String, dynamic>> orderItems,
  }) {
    return {
      'type': 'ordering',
      'difficulty': difficulty,
      'question_text': questionText,
      'question_image_url': '',
      'question_audio_url': '',
      'explanation_text': explanationText,
      'answer_text': '',
      'options': <Map<String, dynamic>>[],
      'order_items': orderItems,
    };
  }

  // ── Helper: build a matching problem document map ──
  static Map<String, dynamic> _matchingP({
    required int difficulty,
    required String questionText,
    String explanationText = '',
    required List<Map<String, dynamic>> matchPairs,
  }) {
    return {
      'type': 'matching',
      'difficulty': difficulty,
      'question_text': questionText,
      'question_image_url': '',
      'question_audio_url': '',
      'explanation_text': explanationText,
      'answer_text': '',
      'options': <Map<String, dynamic>>[],
      'match_pairs': matchPairs,
    };
  }
}
