import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'gonit_event.dart';
import 'gonit_state.dart';
import '../data/models/gonit_problem_model.dart';
import '../data/repo/gonit_repository.dart';

class GanitBloc extends Bloc<GanitEvent, GanitState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _questionAudioPlayer = AudioPlayer();
  final GanitRepository _repository = GanitRepository();
  final Set<String> _answeredIds = {};

  String? _typeFilter;
  bool _isLoadingMoreProblems = false;
  bool _isPlayingFeedbackAudio = false;
  bool _isPlayingQuestionAudio = false;

  GanitBloc() : super(const GanitInitial()) {
    on<GanitInit>(_onInit);
    on<GanitOptionSelected>(_onOptionSelected);
    on<GanitNextProblem>(_onNextProblem);
    on<GanitSkipProblem>(_onSkipProblem);
    on<GanitRetry>(_onRetry);
    on<GanitStop>(_onStop);
    on<GanitLoadMoreProblems>(_onLoadMore);
    on<GanitPlayAgain>(_onPlayAgain);
    on<GanitReadQuestion>(_onReadQuestion);
    on<GanitMatchLeftSelected>(_onMatchLeftSelected);
    on<GanitMatchRightSelected>(_onMatchRightSelected);
    on<GanitOrderItemPlaced>(_onOrderItemPlaced);
    on<GanitOrderItemRemoved>(_onOrderItemRemoved);

    // Update audio state when question finishes
    _questionAudioPlayer.onPlayerComplete.listen((_) {
      _isPlayingQuestionAudio = false;
    });
  }

  // ================= HELPERS =================
  List<int> _shuffleRightIds(GanitProblemModel problem) {
    if (!problem.isMatchingType) return [];
    final ids = problem.matchPairs.map((p) => p.id).toList();
    ids.shuffle();
    return ids;
  }

  List<int> _shuffleOrderIds(GanitProblemModel problem) {
    if (!problem.isOrderingType) return [];
    final ids = problem.orderItems.map((item) => item.id).toList();
    ids.shuffle();
    return ids;
  }

  // ================= INIT =================
  Future<void> _onInit(GanitInit event, Emitter<GanitState> emit) async {
    _typeFilter = event.type;
    emit(const GanitLoading());

    try {
      final problems = await _repository.fetchProblems(
        type: _typeFilter,
        limit: 20,
      );

      if (problems.isEmpty) {
        emit(const GanitError(errorMessage: 'No math problems available'));
        return;
      }

      emit(
        GanitLoaded(
          problems: problems,
          currentIndex: 0,
          shuffledRightIds: _shuffleRightIds(problems[0]),
          shuffledOrderIds: _shuffleOrderIds(problems[0]),
        ),
      );
      _playQuestionAudio();
    } catch (e) {
      emit(GanitError(errorMessage: e.toString()));
    }
  }

  // ================= OPTION SELECTED =================
  Future<void> _onOptionSelected(
    GanitOptionSelected event,
    Emitter<GanitState> emit,
  ) async {
    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    if (currentState.answerStatus != GanitAnswerStatus.none) return;

    final currentProblem = currentState.currentProblem;
    if (currentProblem == null) return;

    final selectedOption = currentProblem.options.firstWhere(
      (o) => o.id == event.optionId,
      orElse: () => currentProblem.options.first,
    );

    final isCorrect = selectedOption.isCorrect;
    _stopAudio();
    await _handleAnswer(
      isCorrect,
      emit,
      currentState,
      selectedOptionId: event.optionId,
    );
  }

  // ================= MATCH LEFT SELECTED =================
  Future<void> _onMatchLeftSelected(
    GanitMatchLeftSelected event,
    Emitter<GanitState> emit,
  ) async {
    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    // If already correctly matched, ignore
    if (currentState.matchResults[event.pairId] == true) return;

    // Toggle selection
    final newSelectedId = currentState.selectedLeftId == event.pairId
        ? null
        : event.pairId;

    emit(
      currentState.copyWith(
        selectedLeftId: newSelectedId,
        clearSelectedLeft: newSelectedId == null,
      ),
    );
  }

  // ================= MATCH RIGHT SELECTED =================
  Future<void> _onMatchRightSelected(
    GanitMatchRightSelected event,
    Emitter<GanitState> emit,
  ) async {
    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    // Use leftPairId from drag if provided, else fall back to selectedLeftId
    final selectedLeft = event.leftPairId ?? currentState.selectedLeftId;
    if (selectedLeft == null) return;

    // If this right item is already correctly matched, ignore
    final alreadyCorrectlyMatched = currentState.matchedPairs.entries.any(
      (e) =>
          e.value == event.pairId && currentState.matchResults[e.key] == true,
    );
    if (alreadyCorrectlyMatched) return;

    // Same pair ID = correct match
    final isCorrect = selectedLeft == event.pairId;

    final newMatched = Map<int, int>.from(currentState.matchedPairs);
    final newResults = Map<int, bool>.from(currentState.matchResults);
    newMatched[selectedLeft] = event.pairId;
    newResults[selectedLeft] = isCorrect;

    emit(
      currentState.copyWith(
        matchedPairs: newMatched,
        matchResults: newResults,
        clearSelectedLeft: true,
      ),
    );

    if (isCorrect) {
      // Check if ALL pairs are now correctly matched
      final problem = currentState.currentProblem;
      if (problem != null &&
          newResults.length == problem.matchPairs.length &&
          newResults.values.every((v) => v == true)) {
        // All matched — treat as correct answer
        _stopAudio();
        if (state is GanitLoaded) {
          await _handleAnswer(true, emit, state as GanitLoaded);
        }
      }
    } else {
      // Wrong match: flash red briefly, then clear
      await _playWrongAudio();
      await Future.delayed(const Duration(milliseconds: 800));

      if (state is GanitLoaded) {
        final afterState = state as GanitLoaded;
        final clearedMatched = Map<int, int>.from(afterState.matchedPairs);
        final clearedResults = Map<int, bool>.from(afterState.matchResults);
        clearedMatched.remove(selectedLeft);
        clearedResults.remove(selectedLeft);

        emit(
          afterState.copyWith(
            matchedPairs: clearedMatched,
            matchResults: clearedResults,
          ),
        );
      }
    }
  }

  // ================= SHARED ANSWER HANDLER =================
  Future<void> _handleAnswer(
    bool isCorrect,
    Emitter<GanitState> emit,
    GanitLoaded currentState, {
    int? selectedOptionId,
  }) async {
    final currentProblem = currentState.currentProblem;
    if (currentProblem != null) {
      _answeredIds.add(currentProblem.id);
    }

    int newRoundCorrect = currentState.roundCorrect;
    int newRoundAnswered = currentState.roundAnswered + 1;

    if (isCorrect) {
      newRoundCorrect++;
    }

    _isPlayingFeedbackAudio = true;

    emit(
      currentState.copyWith(
        selectedOptionId: selectedOptionId,
        answerStatus: isCorrect
            ? GanitAnswerStatus.correct
            : GanitAnswerStatus.wrong,
        roundCorrect: newRoundCorrect,
        roundAnswered: newRoundAnswered,
      ),
    );

    if (isCorrect) {
      await _playYayAudio();
      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('gonit');
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is GanitLoaded) {
        emit(
          (state as GanitLoaded).copyWith(
            answerStatus: GanitAnswerStatus.none,
            clearSelectedOption: true,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
    }
  }

  // ================= NEXT PROBLEM =================
  Future<void> _onNextProblem(
    GanitNextProblem event,
    Emitter<GanitState> emit,
  ) async {
    _stopAudio();

    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    if (currentState.roundAnswered >= 10) {
      emit(
        GanitRoundCompleted(
          problems: currentState.problems,
          currentIndex: currentState.currentIndex,
          roundCorrect: currentState.roundCorrect,
          roundAnswered: currentState.roundAnswered,
        ),
      );
      return;
    }

    final nextIndex = currentState.currentIndex + 1;

    if (nextIndex >= currentState.problems.length) {
      if (_repository.hasMoreData && !_isLoadingMoreProblems) {
        add(GanitLoadMoreProblems());
      }
      return;
    }

    final nextProblem = currentState.problems[nextIndex];

    emit(
      currentState.copyWith(
        currentIndex: nextIndex,
        answerStatus: GanitAnswerStatus.none,
        clearSelectedOption: true,
        clearSelectedLeft: true,
        matchedPairs: const {},
        matchResults: const {},
        shuffledRightIds: _shuffleRightIds(nextProblem),
        placedItems: const {},
        shuffledOrderIds: _shuffleOrderIds(nextProblem),
      ),
    );

    _playQuestionAudio();

    if (currentState.shouldLoadMore &&
        _repository.hasMoreData &&
        !_isLoadingMoreProblems) {
      add(GanitLoadMoreProblems());
    }
  }

  // ================= SKIP PROBLEM =================
  Future<void> _onSkipProblem(
    GanitSkipProblem event,
    Emitter<GanitState> emit,
  ) async {
    _stopAudio();

    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    final currentProblem = currentState.currentProblem;
    if (currentProblem == null) return;

    _answeredIds.add(currentProblem.id);

    // Set skip audio playing state
    emit(currentState.copyWith(isPlayingSkipAudio: true));

    // Play the correct answer audio if available
    final hasAnswerAudio = currentProblem.answerAudioUrl.isNotEmpty;
    if (hasAnswerAudio) {
      await _playCorrectAnswerAudio(currentProblem.answerAudioUrl);
      await _questionAudioPlayer.onPlayerComplete.first;
    }

    if (state is! GanitLoaded) return;
    final afterAudioState = state as GanitLoaded;

    // Reset skip audio state
    emit(afterAudioState.copyWith(isPlayingSkipAudio: false));

    if (state is! GanitLoaded) return;
    final latestState = state as GanitLoaded;

    // For ordering: show correct order before skipping
    if (currentProblem.isOrderingType) {
      final allPlaced = {
        for (var item in currentProblem.orderItems)
          item.correctPosition: item.id,
      };
      emit(
        latestState.copyWith(
          placedItems: allPlaced,
          answerStatus: GanitAnswerStatus.correct,
          roundAnswered: latestState.roundAnswered + 1,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      add(GanitNextProblem());
      return;
    }

    // For matching: show all correct matches before skipping
    if (currentProblem.isMatchingType) {
      final allMatched = {for (var p in currentProblem.matchPairs) p.id: p.id};
      final allResults = {for (var p in currentProblem.matchPairs) p.id: true};
      emit(
        latestState.copyWith(
          matchedPairs: allMatched,
          matchResults: allResults,
          answerStatus: GanitAnswerStatus.correct,
          roundAnswered: latestState.roundAnswered + 1,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      add(GanitNextProblem());
      return;
    }

    final correctOption = currentProblem.correctOption;
    if (correctOption != null) {
      emit(
        latestState.copyWith(
          selectedOptionId: correctOption.id,
          answerStatus: GanitAnswerStatus.correct,
          roundAnswered: latestState.roundAnswered + 1,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    add(GanitNextProblem());
  }

  // ================= LOAD MORE =================
  Future<void> _onLoadMore(
    GanitLoadMoreProblems event,
    Emitter<GanitState> emit,
  ) async {
    if (_isLoadingMoreProblems) return;
    if (state is! GanitLoaded) return;

    _isLoadingMoreProblems = true;
    final currentState = state as GanitLoaded;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final newProblems = await _repository.fetchProblems(
        type: _typeFilter,
        limit: 20,
      );

      if (state is! GanitLoaded) return;

      final filtered = newProblems
          .where((p) => !_answeredIds.contains(p.id))
          .toList();
      final updatedProblems = [...(state as GanitLoaded).problems, ...filtered];

      emit(
        (state as GanitLoaded).copyWith(
          problems: updatedProblems,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint('Error loading more problems: $e');
      if (state is GanitLoaded) {
        emit((state as GanitLoaded).copyWith(isLoadingMore: false));
      }
    } finally {
      _isLoadingMoreProblems = false;
    }
  }

  // ================= RETRY =================
  Future<void> _onRetry(GanitRetry event, Emitter<GanitState> emit) async {
    _stopAudio();

    if (state is GanitLoaded) {
      final currentState = state as GanitLoaded;
      final problem = currentState.currentProblem;

      emit(
        currentState.copyWith(
          answerStatus: GanitAnswerStatus.none,
          clearSelectedOption: true,
          clearSelectedLeft: true,
          matchedPairs: const {},
          matchResults: const {},
          shuffledRightIds: problem != null
              ? _shuffleRightIds(problem)
              : const [],
          placedItems: const {},
          shuffledOrderIds: problem != null
              ? _shuffleOrderIds(problem)
              : const [],
        ),
      );
      _playQuestionAudio();
    }
  }

  // ================= PLAY AGAIN =================
  Future<void> _onPlayAgain(
    GanitPlayAgain event,
    Emitter<GanitState> emit,
  ) async {
    _stopAudio();
    _repository.resetPagination();

    emit(const GanitLoading());

    try {
      final problems = await _repository.fetchProblems(
        type: _typeFilter,
        limit: 20,
      );

      if (problems.isEmpty) {
        emit(const GanitError(errorMessage: 'No math problems available'));
        return;
      }

      _answeredIds.clear();

      emit(
        GanitLoaded(
          problems: problems,
          currentIndex: 0,
          shuffledRightIds: _shuffleRightIds(problems[0]),
          shuffledOrderIds: _shuffleOrderIds(problems[0]),
        ),
      );
      _playQuestionAudio();
    } catch (e) {
      emit(GanitError(errorMessage: e.toString()));
    }
  }

  // ================= STOP =================
  void _onStop(GanitStop event, Emitter<GanitState> emit) {
    _stopAudio();
    _audioPlayer.stop();
  }

  // ================= READ QUESTION =================
  Future<void> _onReadQuestion(
    GanitReadQuestion event,
    Emitter<GanitState> emit,
  ) async {
    _playQuestionAudio();
  }

  // ================= QUESTION AUDIO =================
  Future<void> _playQuestionAudio() async {
    if (state is! GanitLoaded) return;
    final currentProblem = (state as GanitLoaded).currentProblem;
    if (currentProblem == null) return;

    final audioUrl = currentProblem.questionAudioUrl;
    if (audioUrl.isNotEmpty) {
      _isPlayingQuestionAudio = true;
      try {
        await _questionAudioPlayer.stop();
        await _questionAudioPlayer.play(UrlSource(audioUrl));
      } catch (e) {
        debugPrint('Error playing question audio: $e');
        _isPlayingQuestionAudio = false;
      }
    }
  }

  // ================= CORRECT ANSWER AUDIO =================
  Future<void> _playCorrectAnswerAudio(String audioUrl) async {
    await _questionAudioPlayer.stop();

    if (audioUrl.isNotEmpty) {
      try {
        await _questionAudioPlayer.play(UrlSource(audioUrl));
      } catch (e) {
        debugPrint('Error playing correct answer audio: $e');
      }
    }
  }

  // ================= AUDIO =================
  Future<void> _playYayAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/ui/yay_sound.wav'));
  }

  Future<void> _playWrongAudio() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/ui/no_sound.mp3'));
  }

  // ================= CLEANUP =================
  void _stopAudio() {
    _questionAudioPlayer.stop();
    _isPlayingFeedbackAudio = false;
    _isPlayingQuestionAudio = false;
  }

  // ================= ORDER ITEM PLACED =================
  Future<void> _onOrderItemPlaced(
    GanitOrderItemPlaced event,
    Emitter<GanitState> emit,
  ) async {
    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;
    final problem = currentState.currentProblem;
    if (problem == null || !problem.isOrderingType) return;

    final newPlaced = Map<int, int>.from(currentState.placedItems);

    // Remove item from any existing slot first
    newPlaced.removeWhere((_, itemId) => itemId == event.itemId);

    // Place in new slot (remove any existing item in that slot)
    newPlaced[event.slotPosition] = event.itemId;

    emit(currentState.copyWith(placedItems: newPlaced));

    // Check if all slots are filled
    if (newPlaced.length == problem.orderItems.length) {
      final allCorrect = problem.orderItems.every(
        (item) => newPlaced[item.correctPosition] == item.id,
      );

      if (allCorrect) {
        _stopAudio();
        if (state is GanitLoaded) {
          await _handleAnswer(true, emit, state as GanitLoaded);
        }
      } else {
        await _playWrongAudio();
        await Future.delayed(const Duration(milliseconds: 1000));
        // Clear all placements so kid can retry
        if (state is GanitLoaded) {
          emit((state as GanitLoaded).copyWith(placedItems: const {}));
        }
      }
    }
  }

  // ================= ORDER ITEM REMOVED =================
  Future<void> _onOrderItemRemoved(
    GanitOrderItemRemoved event,
    Emitter<GanitState> emit,
  ) async {
    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    final newPlaced = Map<int, int>.from(currentState.placedItems);
    newPlaced.remove(event.slotPosition);

    emit(currentState.copyWith(placedItems: newPlaced));
  }

  @override
  Future<void> close() {
    _stopAudio();
    _audioPlayer.dispose();
    _questionAudioPlayer.dispose();
    return super.close();
  }
}
