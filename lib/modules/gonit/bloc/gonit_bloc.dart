import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'gonit_event.dart';
import 'gonit_state.dart';
import '../data/models/gonit_problem_model.dart';
import '../data/repo/gonit_repository.dart';

class GanitBloc extends Bloc<GanitEvent, GanitState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _questionAudioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GanitRepository _repository = GanitRepository();
  final Set<String> _answeredIds = {};
  String? _typeFilter;
  bool _isLoadingMoreProblems = false;
  bool _isPlayingFeedbackAudio = false;
  bool _isPlayingQuestionAudio = false;
  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;

  GanitBloc() : super(const GanitInitial()) {
    on<GanitInit>(_onInit);
    on<GanitOptionSelected>(_onOptionSelected);
    on<GanitNextProblem>(_onNextProblem);
    on<GanitSkipProblem>(_onSkipProblem);
    on<GanitRetry>(_onRetry);
    on<GanitStop>(_onStop);
    on<GanitLoadMoreProblems>(_onLoadMore);
    on<GanitPlayAgain>(_onPlayAgain);
    on<GanitStartListening>(_onStartListening);
    on<GanitSpeechDetected>(_onSpeechDetected);
    on<GanitReadQuestion>(_onReadQuestion);
    on<GanitMatchLeftSelected>(_onMatchLeftSelected);
    on<GanitMatchRightSelected>(_onMatchRightSelected);
    on<GanitOrderItemPlaced>(_onOrderItemPlaced);
    on<GanitOrderItemRemoved>(_onOrderItemRemoved);

    // Auto-start listening after question audio finishes
    _questionAudioPlayer.onPlayerComplete.listen((_) {
      _isPlayingQuestionAudio = false;
      if (state is GanitLoaded) {
        final currentState = state as GanitLoaded;
        // Don't auto-listen for matching/ordering questions
        if (currentState.currentProblem?.isMatchingType == true) return;
        if (currentState.currentProblem?.isOrderingType == true) return;
        if (!currentState.isValidating &&
            !_isPlayingFeedbackAudio &&
            currentState.answerStatus == GanitAnswerStatus.none) {
          add(GanitStartListening());
        }
      }
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
  Future<void> _onInit(
    GanitInit event,
    Emitter<GanitState> emit,
  ) async {
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

      emit(GanitLoaded(
        problems: problems,
        currentIndex: 0,
        shuffledRightIds: _shuffleRightIds(problems[0]),
        shuffledOrderIds: _shuffleOrderIds(problems[0]),
      ));
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
    _cleanupListening();
    await _handleAnswer(isCorrect, emit, currentState,
        selectedOptionId: event.optionId);
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
    final newSelectedId =
        currentState.selectedLeftId == event.pairId ? null : event.pairId;

    emit(currentState.copyWith(
      selectedLeftId: newSelectedId,
      clearSelectedLeft: newSelectedId == null,
    ));
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
          e.value == event.pairId &&
          currentState.matchResults[e.key] == true,
    );
    if (alreadyCorrectlyMatched) return;

    // Same pair ID = correct match
    final isCorrect = selectedLeft == event.pairId;

    final newMatched = Map<int, int>.from(currentState.matchedPairs);
    final newResults = Map<int, bool>.from(currentState.matchResults);
    newMatched[selectedLeft] = event.pairId;
    newResults[selectedLeft] = isCorrect;

    emit(currentState.copyWith(
      matchedPairs: newMatched,
      matchResults: newResults,
      clearSelectedLeft: true,
    ));

    if (isCorrect) {
      // Check if ALL pairs are now correctly matched
      final problem = currentState.currentProblem;
      if (problem != null &&
          newResults.length == problem.matchPairs.length &&
          newResults.values.every((v) => v == true)) {
        // All matched — treat as correct answer
        _cleanupListening();
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

        emit(afterState.copyWith(
          matchedPairs: clearedMatched,
          matchResults: clearedResults,
        ));
      }
    }
  }

  // ================= START LISTENING =================
  Future<void> _onStartListening(
    GanitStartListening event,
    Emitter<GanitState> emit,
  ) async {
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        _isPlayingQuestionAudio ||
        state.answerStatus == GanitAnswerStatus.correct) {
      return;
    }

    // Don't start listening for matching/ordering questions
    if (state.currentProblem?.isMatchingType == true) return;
    if (state.currentProblem?.isOrderingType == true) return;

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) {},
      onStatus: (status) {},
    );

    if (!available) return;

    if (state is GanitLoaded) {
      emit((state as GanitLoaded).copyWith(
        isListening: true,
        answerStatus: GanitAnswerStatus.none,
      ));
    }

    await _speech.listen(
      localeId: 'bn_IN',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: false,
      ),
      onResult: (result) {
        if (_hasSpoken) return;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _hasSpoken = true;
          add(GanitSpeechDetected(result.recognizedWords));
        }
      },
    );

    // Timeout after 6 seconds
    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (_hasSpoken || state.isValidating) return;
      await _speech.stop();
      if (state is GanitLoaded) {
        emit((state as GanitLoaded).copyWith(isListening: false));
      }
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    GanitSpeechDetected event,
    Emitter<GanitState> emit,
  ) async {
    _listenTimeoutTimer?.cancel();
    await _speech.stop();

    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    emit(currentState.copyWith(
      isListening: false,
      isValidating: true,
      recognizedText: event.text,
      answerStatus: GanitAnswerStatus.none,
    ));

    final currentProblem = currentState.currentProblem;
    if (currentProblem == null) return;

    // Validate: match spoken text against the correct answer
    final isCorrect = _validateSpeechAnswer(
      spokenText: event.text,
      correctAnswer: currentProblem.answerText,
    );

    if (state is! GanitLoaded) return;
    final afterState = state as GanitLoaded;

    emit(afterState.copyWith(isValidating: false));

    // Find the correct option to highlight
    int? matchedOptionId;
    if (isCorrect) {
      matchedOptionId = currentProblem.correctOption?.id;
    }

    await _handleAnswer(isCorrect, emit, afterState,
        selectedOptionId: matchedOptionId);
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

    emit(currentState.copyWith(
      selectedOptionId: selectedOptionId,
      answerStatus:
          isCorrect ? GanitAnswerStatus.correct : GanitAnswerStatus.wrong,
      roundCorrect: newRoundCorrect,
      roundAnswered: newRoundAnswered,
    ));

    if (isCorrect) {
      await _playYayAudio();
      _isPlayingFeedbackAudio = false;
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is GanitLoaded) {
        emit((state as GanitLoaded).copyWith(
          answerStatus: GanitAnswerStatus.none,
          clearSelectedOption: true,
        ));
      }

      _isPlayingFeedbackAudio = false;
    }
  }

  // ================= SPEECH VALIDATION =================
  bool _validateSpeechAnswer({
    required String spokenText,
    required String correctAnswer,
  }) {
    final spoken = _normalizeNumber(spokenText.trim().toLowerCase());
    final correct = _normalizeNumber(correctAnswer.trim().toLowerCase());

    if (spoken == correct) return true;

    // Try parsing both as numbers for comparison
    final spokenNum = int.tryParse(spoken);
    final correctNum = int.tryParse(correct);
    if (spokenNum != null && correctNum != null) {
      return spokenNum == correctNum;
    }

    return false;
  }

  String _normalizeNumber(String text) {
    // Bengali to ASCII digit conversion
    const bengaliDigits = '০১২৩৪৫৬৭৮৯';
    const asciiDigits = '0123456789';

    var result = text;
    for (int i = 0; i < bengaliDigits.length; i++) {
      result = result.replaceAll(bengaliDigits[i], asciiDigits[i]);
    }

    // Common Bengali number words
    const wordMap = {
      'এক': '1', 'দুই': '2', 'তিন': '3', 'চার': '4', 'পাঁচ': '5',
      'ছয়': '6', 'সাত': '7', 'আট': '8', 'নয়': '9', 'দশ': '10',
      'এগারো': '11', 'বারো': '12', 'তেরো': '13', 'চৌদ্দ': '14', 'পনেরো': '15',
      'ষোলো': '16', 'সতেরো': '17', 'আঠারো': '18', 'উনিশ': '19', 'বিশ': '20',
      'শূন্য': '0',
      // English words
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9', 'ten': '10',
      'eleven': '11', 'twelve': '12', 'zero': '0',
    };

    for (final entry in wordMap.entries) {
      if (result.contains(entry.key)) {
        result = entry.value;
        break;
      }
    }

    // Strip non-digit characters for final comparison
    final digitsOnly = result.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isNotEmpty) return digitsOnly;

    return result;
  }

  // ================= NEXT PROBLEM =================
  Future<void> _onNextProblem(
    GanitNextProblem event,
    Emitter<GanitState> emit,
  ) async {
    _cleanupListening();

    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    if (currentState.roundAnswered >= 10) {
      emit(GanitRoundCompleted(
        problems: currentState.problems,
        currentIndex: currentState.currentIndex,
        roundCorrect: currentState.roundCorrect,
        roundAnswered: currentState.roundAnswered,
      ));
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

    emit(currentState.copyWith(
      currentIndex: nextIndex,
      answerStatus: GanitAnswerStatus.none,
      recognizedText: '',
      clearSelectedOption: true,
      clearSelectedLeft: true,
      matchedPairs: const {},
      matchResults: const {},
      shuffledRightIds: _shuffleRightIds(nextProblem),
      placedItems: const {},
      shuffledOrderIds: _shuffleOrderIds(nextProblem),
    ));

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
    _cleanupListening();

    if (state is! GanitLoaded) return;
    final currentState = state as GanitLoaded;

    final currentProblem = currentState.currentProblem;
    if (currentProblem == null) return;

    _answeredIds.add(currentProblem.id);

    // For ordering: show correct order before skipping
    if (currentProblem.isOrderingType) {
      final allPlaced = {
        for (var item in currentProblem.orderItems)
          item.correctPosition: item.id,
      };
      emit(currentState.copyWith(
        placedItems: allPlaced,
        answerStatus: GanitAnswerStatus.correct,
        roundAnswered: currentState.roundAnswered + 1,
      ));
      await Future.delayed(const Duration(milliseconds: 1500));
      add(GanitNextProblem());
      return;
    }

    // For matching: show all correct matches before skipping
    if (currentProblem.isMatchingType) {
      final allMatched = {
        for (var p in currentProblem.matchPairs) p.id: p.id,
      };
      final allResults = {
        for (var p in currentProblem.matchPairs) p.id: true,
      };
      emit(currentState.copyWith(
        matchedPairs: allMatched,
        matchResults: allResults,
        answerStatus: GanitAnswerStatus.correct,
        roundAnswered: currentState.roundAnswered + 1,
      ));
      await Future.delayed(const Duration(milliseconds: 1500));
      add(GanitNextProblem());
      return;
    }

    final correctOption = currentProblem.correctOption;
    if (correctOption != null) {
      emit(currentState.copyWith(
        selectedOptionId: correctOption.id,
        answerStatus: GanitAnswerStatus.correct,
        roundAnswered: currentState.roundAnswered + 1,
      ));
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

      final filtered =
          newProblems.where((p) => !_answeredIds.contains(p.id)).toList();
      final updatedProblems = [
        ...(state as GanitLoaded).problems,
        ...filtered,
      ];

      emit((state as GanitLoaded).copyWith(
        problems: updatedProblems,
        isLoadingMore: false,
      ));
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
  Future<void> _onRetry(
    GanitRetry event,
    Emitter<GanitState> emit,
  ) async {
    _cleanupListening();

    if (state is GanitLoaded) {
      final currentState = state as GanitLoaded;
      final problem = currentState.currentProblem;

      emit(currentState.copyWith(
        answerStatus: GanitAnswerStatus.none,
        recognizedText: '',
        clearSelectedOption: true,
        clearSelectedLeft: true,
        matchedPairs: const {},
        matchResults: const {},
        shuffledRightIds:
            problem != null ? _shuffleRightIds(problem) : const [],
        placedItems: const {},
        shuffledOrderIds:
            problem != null ? _shuffleOrderIds(problem) : const [],
      ));
      _playQuestionAudio();
    }
  }

  // ================= PLAY AGAIN =================
  Future<void> _onPlayAgain(
    GanitPlayAgain event,
    Emitter<GanitState> emit,
  ) async {
    _cleanupListening();
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

      emit(GanitLoaded(
        problems: problems,
        currentIndex: 0,
        shuffledRightIds: _shuffleRightIds(problems[0]),
        shuffledOrderIds: _shuffleOrderIds(problems[0]),
      ));
      _playQuestionAudio();
    } catch (e) {
      emit(GanitError(errorMessage: e.toString()));
    }
  }

  // ================= STOP =================
  void _onStop(GanitStop event, Emitter<GanitState> emit) {
    _cleanupListening();
    _audioPlayer.stop();
    _questionAudioPlayer.stop();
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
      _hasSpoken = false;
      try {
        await _questionAudioPlayer.stop();
        await _questionAudioPlayer.play(UrlSource(audioUrl));
      } catch (e) {
        debugPrint('Error playing question audio: $e');
        _isPlayingQuestionAudio = false;
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
  void _cleanupListening() {
    _listenTimeoutTimer?.cancel();
    _speech.stop();
    _questionAudioPlayer.stop();
    _hasSpoken = false;
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
      final allCorrect = problem.orderItems
          .every((item) => newPlaced[item.correctPosition] == item.id);

      if (allCorrect) {
        _cleanupListening();
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
    _cleanupListening();
    _audioPlayer.dispose();
    _questionAudioPlayer.dispose();
    return super.close();
  }
}
