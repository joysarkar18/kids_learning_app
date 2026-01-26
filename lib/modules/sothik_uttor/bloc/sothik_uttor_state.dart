import 'package:equatable/equatable.dart';
import '../data/models/question_model.dart';

enum SothikUttorAnswerStatus { none, correct, wrong }

sealed class SothikUttorState extends Equatable {
  final List<QuestionModel> questions;
  final int currentIndex;
  final bool isListening;
  final bool isValidating;
  final bool isLoadingMore;
  final bool isPlayingSkipAudio;
  final String recognizedText;
  final SothikUttorAnswerStatus answerStatus;
  final String? errorMessage;
  final int? selectedOptionId;

  const SothikUttorState({
    this.questions = const [],
    this.currentIndex = 0,
    this.isListening = false,
    this.isValidating = false,
    this.isLoadingMore = false,
    this.isPlayingSkipAudio = false,
    this.recognizedText = "",
    this.answerStatus = SothikUttorAnswerStatus.none,
    this.errorMessage,
    this.selectedOptionId,
  });

  QuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  bool get shouldLoadMore =>
      questions.isNotEmpty && currentIndex >= questions.length - 10;

  int get totalQuestions => questions.length;

  @override
  List<Object?> get props => [
        questions,
        currentIndex,
        isListening,
        isValidating,
        isLoadingMore,
        isPlayingSkipAudio,
        recognizedText,
        answerStatus,
        errorMessage,
        selectedOptionId,
      ];
}

final class SothikUttorInitial extends SothikUttorState {
  const SothikUttorInitial();
}

final class SothikUttorLoading extends SothikUttorState {
  const SothikUttorLoading();
}

final class SothikUttorLoaded extends SothikUttorState {
  const SothikUttorLoaded({
    required super.questions,
    super.currentIndex,
    super.isListening,
    super.isValidating,
    super.isLoadingMore,
    super.isPlayingSkipAudio,
    super.recognizedText,
    super.answerStatus,
    super.errorMessage,
    super.selectedOptionId,
  });

  SothikUttorLoaded copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    bool? isListening,
    bool? isValidating,
    bool? isLoadingMore,
    bool? isPlayingSkipAudio,
    String? recognizedText,
    SothikUttorAnswerStatus? answerStatus,
    String? errorMessage,
    int? selectedOptionId,
    bool clearSelectedOption = false,
  }) {
    return SothikUttorLoaded(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isListening: isListening ?? this.isListening,
      isValidating: isValidating ?? this.isValidating,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isPlayingSkipAudio: isPlayingSkipAudio ?? this.isPlayingSkipAudio,
      recognizedText: recognizedText ?? this.recognizedText,
      answerStatus: answerStatus ?? this.answerStatus,
      errorMessage: errorMessage,
      selectedOptionId: clearSelectedOption ? null : (selectedOptionId ?? this.selectedOptionId),
    );
  }
}

final class SothikUttorError extends SothikUttorState {
  const SothikUttorError({required String errorMessage})
      : super(errorMessage: errorMessage);
}

final class SothikUttorCompleted extends SothikUttorState {
  const SothikUttorCompleted({required super.questions});
}
