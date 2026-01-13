import 'package:equatable/equatable.dart';

enum AnswerStatus { none, correct, wrong }

const List<String> bengaliAlphabet = [
  "অ",
  "আ",
  "ই",
  "ঈ",
  "উ",
  "ঊ",
  "ঋ",
  "ঌ",
  "এ",
  "ঐ",
  "ও",
  "ঔ",
  "ক",
  "খ",
  "গ",
  "ঘ",
  "ঙ",
  "চ",
  "ছ",
  "জ",
  "ঝ",
  "ঞ",
  "ট",
  "ঠ",
  "ড",
  "ঢ",
  "ণ",
  "ত",
  "থ",
  "দ",
  "ধ",
  "ন",
  "প",
  "ফ",
  "ব",
  "ভ",
  "ম",
  "য",
  "র",
  "ল",
  "শ",
  "ষ",
  "স",
  "হ",
  "ড়",
  "ঢ়",
  "ৎ",
  "ং",
  "ঃ",
  "ঁ",
];

sealed class BornomalaState extends Equatable {
  final int index;
  final bool isListening;
  final bool isValidating;
  final String recognizedText;
  final AnswerStatus answerStatus;

  const BornomalaState({
    required this.index,
    this.isListening = false,
    this.isValidating = false,
    this.recognizedText = "",
    this.answerStatus = AnswerStatus.none,
  });

  String get currentAlphabet => bengaliAlphabet[index];

  BornomalaLoaded copyWith({
    int? index,
    bool? isListening,
    bool? isValidating,
    String? recognizedText,
    AnswerStatus? answerStatus,
  }) {
    return BornomalaLoaded(
      index: index ?? this.index,
      isListening: isListening ?? this.isListening,
      isValidating: isValidating ?? this.isValidating,
      recognizedText: recognizedText ?? this.recognizedText,
      answerStatus: answerStatus ?? this.answerStatus,
    );
  }

  @override
  List<Object?> get props => [
    index,
    isListening,
    isValidating,
    recognizedText,
    answerStatus,
  ];
}

final class BornomalaInitial extends BornomalaState {
  const BornomalaInitial() : super(index: 0);
}

final class BornomalaLoaded extends BornomalaState {
  const BornomalaLoaded({
    required super.index,
    super.isListening,
    super.isValidating,
    super.recognizedText,
    super.answerStatus,
  });
}
