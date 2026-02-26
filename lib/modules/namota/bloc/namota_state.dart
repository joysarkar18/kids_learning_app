import 'package:equatable/equatable.dart';

enum NamotaAnswerStatus { none, correct, wrong }

/// Converts an integer to its Bengali numeral string.
/// e.g. 4 → "৪", 12 → "১২", 100 → "১০০"
String toBengali(int n) {
  const bengaliDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return n.toString().split('').map((d) => bengaliDigits[int.parse(d)]).join();
}

sealed class NamotaState extends Equatable {
  final int tableNumber;
  final int currentRowIndex;
  final Set<int> completedRows;
  final bool isListening;
  final bool isValidating;
  final bool isPlayingAll;
  final String recognizedText;
  final NamotaAnswerStatus answerStatus;

  const NamotaState({
    required this.tableNumber,
    this.currentRowIndex = 0,
    this.completedRows = const {},
    this.isListening = false,
    this.isValidating = false,
    this.isPlayingAll = false,
    this.recognizedText = "",
    this.answerStatus = NamotaAnswerStatus.none,
  });

  /// The multiplier for the current row (1-10).
  int get currentMultiplier => currentRowIndex + 1;

  /// The result of tableNumber × currentMultiplier.
  int get currentResult => tableNumber * currentMultiplier;

  /// The result as a Bengali numeral string.
  String get currentResultBengali => toBengali(currentResult);

  /// Audio file name for the current row (e.g. "4x1").
  String get currentAudioFile => '${tableNumber}x$currentMultiplier';

  /// Whether all 10 rows are completed.
  bool get isAllCompleted => completedRows.length >= 10;

  NamotaLoaded copyWith({
    int? tableNumber,
    int? currentRowIndex,
    Set<int>? completedRows,
    bool? isListening,
    bool? isValidating,
    bool? isPlayingAll,
    String? recognizedText,
    NamotaAnswerStatus? answerStatus,
  }) {
    return NamotaLoaded(
      tableNumber: tableNumber ?? this.tableNumber,
      currentRowIndex: currentRowIndex ?? this.currentRowIndex,
      completedRows: completedRows ?? this.completedRows,
      isListening: isListening ?? this.isListening,
      isValidating: isValidating ?? this.isValidating,
      isPlayingAll: isPlayingAll ?? this.isPlayingAll,
      recognizedText: recognizedText ?? this.recognizedText,
      answerStatus: answerStatus ?? this.answerStatus,
    );
  }

  @override
  List<Object?> get props => [
    tableNumber,
    currentRowIndex,
    completedRows,
    isListening,
    isValidating,
    isPlayingAll,
    recognizedText,
    answerStatus,
  ];
}

final class NamotaInitial extends NamotaState {
  const NamotaInitial() : super(tableNumber: 1);
}

final class NamotaLoaded extends NamotaState {
  const NamotaLoaded({
    required super.tableNumber,
    super.currentRowIndex,
    super.completedRows,
    super.isListening,
    super.isValidating,
    super.isPlayingAll,
    super.recognizedText,
    super.answerStatus,
  });
}
