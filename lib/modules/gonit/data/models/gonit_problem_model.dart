import 'package:cloud_firestore/cloud_firestore.dart';

class GanitOptionModel {
  final int id;
  final String text;
  final String imageUrl;
  final bool isCorrect;

  const GanitOptionModel({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.isCorrect,
  });

  factory GanitOptionModel.fromMap(Map<String, dynamic> data) {
    return GanitOptionModel(
      id: data['id'] ?? 0,
      text: data['text'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isCorrect: data['is_correct'] ?? false,
    );
  }
}

class GanitMatchPairModel {
  final int id;
  final String left;
  final String right;

  const GanitMatchPairModel({
    required this.id,
    required this.left,
    required this.right,
  });

  factory GanitMatchPairModel.fromMap(Map<String, dynamic> data) {
    return GanitMatchPairModel(
      id: data['id'] ?? 0,
      left: data['left'] ?? '',
      right: data['right'] ?? '',
    );
  }
}

class GanitOrderItemModel {
  final int id;
  final String text;
  final int correctPosition;

  const GanitOrderItemModel({
    required this.id,
    required this.text,
    required this.correctPosition,
  });

  factory GanitOrderItemModel.fromMap(Map<String, dynamic> data) {
    return GanitOrderItemModel(
      id: data['id'] ?? 0,
      text: data['text'] ?? '',
      correctPosition: data['correct_position'] ?? 0,
    );
  }
}

class GanitProblemModel {
  final String id;
  final String type;
  final int difficulty;
  final String questionText;
  final String questionImageUrl;
  final String questionAudioUrl;
  final String answerAudioUrl;
  final String explanationText;
  final String answerText;
  final List<GanitOptionModel> options;
  final List<GanitMatchPairModel> matchPairs;
  final List<GanitOrderItemModel> orderItems;

  const GanitProblemModel({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.questionText,
    required this.questionImageUrl,
    this.questionAudioUrl = '',
    this.answerAudioUrl = '',
    required this.explanationText,
    required this.answerText,
    required this.options,
    this.matchPairs = const [],
    this.orderItems = const [],
  });

  bool get isMatchingType => type == 'matching';
  bool get isOrderingType => type == 'ordering';

  GanitOptionModel? get correctOption => options.isNotEmpty
      ? options.firstWhere((o) => o.isCorrect, orElse: () => options.first)
      : null;

  factory GanitProblemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<GanitOptionModel> optionsList = [];
    if (data['options'] != null) {
      optionsList = (data['options'] as List)
          .map((o) => GanitOptionModel.fromMap(o as Map<String, dynamic>))
          .toList();
    }

    List<GanitMatchPairModel> matchPairsList = [];
    if (data['match_pairs'] != null) {
      matchPairsList = (data['match_pairs'] as List)
          .map((p) => GanitMatchPairModel.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    List<GanitOrderItemModel> orderItemsList = [];
    if (data['order_items'] != null) {
      orderItemsList = (data['order_items'] as List)
          .map((o) => GanitOrderItemModel.fromMap(o as Map<String, dynamic>))
          .toList();
    }

    return GanitProblemModel(
      id: doc.id,
      type: data['type'] ?? 'arithmetic',
      difficulty: data['difficulty'] ?? 1,
      questionText: data['question_text'] ?? '',
      questionImageUrl: data['question_image_url'] ?? '',
      questionAudioUrl: data['question_audio_url'] ?? '',
      answerAudioUrl: data['answer_audio_url'] ?? '',
      explanationText: data['explanation_text'] ?? '',
      answerText: data['answer_text'] ?? '',
      options: optionsList,
      matchPairs: matchPairsList,
      orderItems: orderItemsList,
    );
  }
}
