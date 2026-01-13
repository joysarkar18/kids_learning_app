import 'package:equatable/equatable.dart';

enum AnswerStatus { none, correct, wrong }

const List<String> englishAlphabet = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
];

sealed class AlphabetState extends Equatable {
  final int index;
  final bool isListening;
  final bool isValidating;
  final String recognizedText;
  final AnswerStatus answerStatus;

  const AlphabetState({
    required this.index,
    this.isListening = false,
    this.isValidating = false,
    this.recognizedText = "",
    this.answerStatus = AnswerStatus.none,
  });

  String get currentAlphabet => englishAlphabet[index];

  AlphabetLoaded copyWith({
    int? index,
    bool? isListening,
    bool? isValidating,
    String? recognizedText,
    AnswerStatus? answerStatus,
  }) {
    return AlphabetLoaded(
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

final class AlphabetInitial extends AlphabetState {
  const AlphabetInitial() : super(index: 0);
}

final class AlphabetLoaded extends AlphabetState {
  const AlphabetLoaded({
    required super.index,
    super.isListening,
    super.isValidating,
    super.recognizedText,
    super.answerStatus,
  });
}
