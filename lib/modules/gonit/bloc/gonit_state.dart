import 'package:equatable/equatable.dart';
import '../data/models/gonit_problem_model.dart';

enum GanitAnswerStatus { none, correct, wrong }

sealed class GanitState extends Equatable {
  final List<GanitProblemModel> problems;
  final int currentIndex;
  final int? selectedOptionId;
  final GanitAnswerStatus answerStatus;
  final bool isListening;
  final bool isValidating;
  final bool isLoadingMore;
  final String? errorMessage;
  final String recognizedText;

  // Round tracking
  final int roundCorrect;
  final int roundAnswered;

  // Matching
  final int? selectedLeftId;
  final Map<int, int> matchedPairs;
  final Map<int, bool> matchResults;
  final List<int> shuffledRightIds;

  // Ordering
  final Map<int, int> placedItems; // slotPosition → itemId
  final List<int> shuffledOrderIds;

  const GanitState({
    this.problems = const [],
    this.currentIndex = 0,
    this.selectedOptionId,
    this.answerStatus = GanitAnswerStatus.none,
    this.isListening = false,
    this.isValidating = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.recognizedText = '',
    this.roundCorrect = 0,
    this.roundAnswered = 0,
    this.selectedLeftId,
    this.matchedPairs = const {},
    this.matchResults = const {},
    this.shuffledRightIds = const [],
    this.placedItems = const {},
    this.shuffledOrderIds = const [],
  });

  GanitProblemModel? get currentProblem =>
      problems.isNotEmpty && currentIndex < problems.length
          ? problems[currentIndex]
          : null;

  bool get isRoundComplete => roundAnswered >= 10;

  int get roundStars {
    if (roundAnswered == 0) return 0;
    final accuracy = roundCorrect / roundAnswered;
    if (accuracy >= 0.9) return 3;
    if (accuracy >= 0.7) return 2;
    if (accuracy >= 0.5) return 1;
    return 0;
  }

  bool get shouldLoadMore =>
      problems.isNotEmpty && currentIndex >= problems.length - 5;

  bool get allMatchesCorrect {
    final problem = currentProblem;
    if (problem == null || !problem.isMatchingType) return false;
    return matchResults.length == problem.matchPairs.length &&
        matchResults.values.every((v) => v == true);
  }

  bool get allOrderingSlotsCorrect {
    final problem = currentProblem;
    if (problem == null || !problem.isOrderingType) return false;
    if (placedItems.length != problem.orderItems.length) return false;
    return problem.orderItems
        .every((item) => placedItems[item.correctPosition] == item.id);
  }

  @override
  List<Object?> get props => [
        problems,
        currentIndex,
        selectedOptionId,
        answerStatus,
        isListening,
        isValidating,
        isLoadingMore,
        errorMessage,
        recognizedText,
        roundCorrect,
        roundAnswered,
        selectedLeftId,
        matchedPairs,
        matchResults,
        shuffledRightIds,
        placedItems,
        shuffledOrderIds,
      ];
}

final class GanitInitial extends GanitState {
  const GanitInitial();
}

final class GanitLoading extends GanitState {
  const GanitLoading();
}

final class GanitLoaded extends GanitState {
  const GanitLoaded({
    required super.problems,
    super.currentIndex,
    super.selectedOptionId,
    super.answerStatus,
    super.isListening,
    super.isValidating,
    super.isLoadingMore,
    super.errorMessage,
    super.recognizedText,
    super.roundCorrect,
    super.roundAnswered,
    super.selectedLeftId,
    super.matchedPairs,
    super.matchResults,
    super.shuffledRightIds,
    super.placedItems,
    super.shuffledOrderIds,
  });

  GanitLoaded copyWith({
    List<GanitProblemModel>? problems,
    int? currentIndex,
    int? selectedOptionId,
    GanitAnswerStatus? answerStatus,
    bool? isListening,
    bool? isValidating,
    bool? isLoadingMore,
    String? errorMessage,
    String? recognizedText,
    int? roundCorrect,
    int? roundAnswered,
    bool clearSelectedOption = false,
    int? selectedLeftId,
    bool clearSelectedLeft = false,
    Map<int, int>? matchedPairs,
    Map<int, bool>? matchResults,
    List<int>? shuffledRightIds,
    Map<int, int>? placedItems,
    List<int>? shuffledOrderIds,
  }) {
    return GanitLoaded(
      problems: problems ?? this.problems,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionId:
          clearSelectedOption ? null : (selectedOptionId ?? this.selectedOptionId),
      answerStatus: answerStatus ?? this.answerStatus,
      isListening: isListening ?? this.isListening,
      isValidating: isValidating ?? this.isValidating,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      recognizedText: recognizedText ?? this.recognizedText,
      roundCorrect: roundCorrect ?? this.roundCorrect,
      roundAnswered: roundAnswered ?? this.roundAnswered,
      selectedLeftId:
          clearSelectedLeft ? null : (selectedLeftId ?? this.selectedLeftId),
      matchedPairs: matchedPairs ?? this.matchedPairs,
      matchResults: matchResults ?? this.matchResults,
      shuffledRightIds: shuffledRightIds ?? this.shuffledRightIds,
      placedItems: placedItems ?? this.placedItems,
      shuffledOrderIds: shuffledOrderIds ?? this.shuffledOrderIds,
    );
  }
}

final class GanitError extends GanitState {
  const GanitError({required String errorMessage})
      : super(errorMessage: errorMessage);
}

final class GanitRoundCompleted extends GanitState {
  const GanitRoundCompleted({
    required super.problems,
    super.currentIndex,
    super.roundCorrect,
    super.roundAnswered,
  });
}
