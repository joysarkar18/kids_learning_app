import 'package:equatable/equatable.dart';

enum EnglishSonkhaAnswerStatus { none, correct, wrong }

const List<String> englishNumbers = [
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "10",
  "11",
  "12",
  "13",
  "14",
  "15",
  "16",
  "17",
  "18",
  "19",
  "20",
  "21",
  "22",
  "23",
  "24",
  "25",
  "26",
  "27",
  "28",
  "29",
  "30",
  "31",
  "32",
  "33",
  "34",
  "35",
  "36",
  "37",
  "38",
  "39",
  "40",
  "41",
  "42",
  "43",
  "44",
  "45",
  "46",
  "47",
  "48",
  "49",
  "50",
  "51",
  "52",
  "53",
  "54",
  "55",
  "56",
  "57",
  "58",
  "59",
  "60",
  "61",
  "62",
  "63",
  "64",
  "65",
  "66",
  "67",
  "68",
  "69",
  "70",
  "71",
  "72",
  "73",
  "74",
  "75",
  "76",
  "77",
  "78",
  "79",
  "80",
  "81",
  "82",
  "83",
  "84",
  "85",
  "86",
  "87",
  "88",
  "89",
  "90",
  "91",
  "92",
  "93",
  "94",
  "95",
  "96",
  "97",
  "98",
  "99",
  "100",
];

sealed class EnglishSonkhaState extends Equatable {
  final int index;
  final bool isListening;
  final bool isValidating;
  final String recognizedText;
  final EnglishSonkhaAnswerStatus answerStatus;

  const EnglishSonkhaState({
    required this.index,
    this.isListening = false,
    this.isValidating = false,
    this.recognizedText = "",
    this.answerStatus = EnglishSonkhaAnswerStatus.none,
  });

  String get currentNumber => englishNumbers[index];

  EnglishSonkhaLoaded copyWith({
    int? index,
    bool? isListening,
    bool? isValidating,
    String? recognizedText,
    EnglishSonkhaAnswerStatus? answerStatus,
  }) {
    return EnglishSonkhaLoaded(
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

final class EnglishSonkhaInitial extends EnglishSonkhaState {
  const EnglishSonkhaInitial() : super(index: 0);
}

final class EnglishSonkhaLoaded extends EnglishSonkhaState {
  const EnglishSonkhaLoaded({
    required super.index,
    super.isListening,
    super.isValidating,
    super.recognizedText,
    super.answerStatus,
  });
}
