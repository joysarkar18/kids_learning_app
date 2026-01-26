import 'package:cloud_firestore/cloud_firestore.dart';

class OptionModel {
  final int id;
  final String text;
  final String imageUrl;
  final bool isCorrect;

  const OptionModel({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.isCorrect,
  });

  factory OptionModel.fromMap(Map<String, dynamic> data) {
    return OptionModel(
      id: data['id'] ?? 0,
      text: data['text'] ?? '',
      imageUrl: data['image_url'] ?? '',
      isCorrect: data['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'image_url': imageUrl,
      'is_correct': isCorrect,
    };
  }
}

class QuestionModel {
  final String id;
  final String type;
  final String questionAudioUrl;
  final String hintImage;
  final String questionText;
  final String answerText;
  final String answerAudioText;
  final String correctAnswerAudioUrl;
  final List<OptionModel> options;

  const QuestionModel({
    required this.id,
    required this.type,
    required this.questionAudioUrl,
    required this.hintImage,
    required this.questionText,
    required this.answerText,
    required this.answerAudioText,
    required this.correctAnswerAudioUrl,
    required this.options,
  });

  bool get isMcqQuestion => type == 'mcq_image' || type == 'mcq_text';

  OptionModel? get correctOption => options.isNotEmpty
      ? options.firstWhere((o) => o.isCorrect, orElse: () => options.first)
      : null;

  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<OptionModel> optionsList = [];
    if (data['options'] != null) {
      optionsList = (data['options'] as List)
          .map((o) => OptionModel.fromMap(o as Map<String, dynamic>))
          .toList();
    }

    return QuestionModel(
      id: doc.id,
      type: data['type'] ?? 'audio_question',
      questionAudioUrl: data['question_audio_url'] ?? '',
      hintImage: data['hint_image'] ?? '',
      questionText: data['question_text'] ?? '',
      answerText: data['answer_text'] ?? '',
      answerAudioText: data['answer_audio_text'] ?? '',
      correctAnswerAudioUrl: data['correct_answer_audio_url'] ?? '',
      options: optionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question_audio_url': questionAudioUrl,
      'hint_image': hintImage,
      'question_text': questionText,
      'answer_text': answerText,
      'answer_audio_text': answerAudioText,
      'correct_answer_audio_url': correctAnswerAudioUrl,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}
