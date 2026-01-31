import 'package:equatable/equatable.dart';

enum SonkhaAnswerStatus { none, correct, wrong }

const List<String> bengaliNumbers = [
  "১",
  "২",
  "৩",
  "৪",
  "৫",
  "৬",
  "৭",
  "৮",
  "৯",
  "১০",
  "১১",
  "১২",
  "১৩",
  "১৪",
  "১৫",
  "১৬",
  "১৭",
  "১৮",
  "১৯",
  "২০",
  "২১",
  "২২",
  "২৩",
  "২৪",
  "২৫",
  "২৬",
  "২৭",
  "২৮",
  "২৯",
  "৩০",
  "৩১",
  "৩২",
  "৩৩",
  "৩৪",
  "৩৫",
  "৩৬",
  "৩৭",
  "৩৮",
  "৩৯",
  "৪০",
  "৪১",
  "৪২",
  "৪৩",
  "৪৪",
  "৪৫",
  "৪৬",
  "৪৭",
  "৪৮",
  "৪৯",
  "৫০",
  "৫১",
  "৫২",
  "৫৩",
  "৫৪",
  "৫৫",
  "৫৬",
  "৫৭",
  "৫৮",
  "৫৯",
  "৬০",
  "৬১",
  "৬২",
  "৬৩",
  "৬৪",
  "৬৫",
  "৬৬",
  "৬৭",
  "৬৮",
  "৬৯",
  "৭০",
  "৭১",
  "৭২",
  "৭৩",
  "৭৪",
  "৭৫",
  "৭৬",
  "৭৭",
  "৭৮",
  "৭৯",
  "৮০",
  "৮১",
  "৮২",
  "৮৩",
  "৮৪",
  "৮৫",
  "৮৬",
  "৮৭",
  "৮৮",
  "৮৯",
  "৯০",
  "৯১",
  "৯২",
  "৯৩",
  "৯৪",
  "৯৫",
  "৯৬",
  "৯৭",
  "৯৮",
  "৯৯",
  "১০০",
];

sealed class BanglaSonkhaState extends Equatable {
  final int index;
  final bool isListening;
  final bool isValidating;
  final String recognizedText;
  final SonkhaAnswerStatus answerStatus;

  const BanglaSonkhaState({
    required this.index,
    this.isListening = false,
    this.isValidating = false,
    this.recognizedText = "",
    this.answerStatus = SonkhaAnswerStatus.none,
  });

  String get currentNumber => bengaliNumbers[index];

  BanglaSonkhaLoaded copyWith({
    int? index,
    bool? isListening,
    bool? isValidating,
    String? recognizedText,
    SonkhaAnswerStatus? answerStatus,
  }) {
    return BanglaSonkhaLoaded(
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

final class BanglaSonkhaInitial extends BanglaSonkhaState {
  const BanglaSonkhaInitial() : super(index: 0);
}

final class BanglaSonkhaLoaded extends BanglaSonkhaState {
  const BanglaSonkhaLoaded({
    required super.index,
    super.isListening,
    super.isValidating,
    super.recognizedText,
    super.answerStatus,
  });
}
