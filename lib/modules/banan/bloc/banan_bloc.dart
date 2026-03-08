import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_learning/modules/banan/data/models/banan_data_model.dart';
import 'package:kids_learning/modules/banan/data/repo/banan_repo.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

import 'banan_event.dart';
import 'banan_state.dart';

class BananBloc extends Bloc<BananEvent, BananState> {
  final AudioPlayer _audioPlayer = AudioPlayer(); // feedback sfx
  final AudioPlayer _questionAudioPlayer =
      AudioPlayer(); // question / word audio
  final BananRepository _repository;

  final Set<String> _answeredIds = {};
  bool _isLoadingMoreProblems = false;
  bool _isPlayingFeedbackAudio = false;
  bool _isPlayingQuestionAudio = false;

  int _roundCorrect = 0;
  int _roundAnswered = 0;

  BananBloc({BananRepository? repository})
    : _repository = repository ?? BananRepository(),
      super(const BananInitial()) {
    on<BananInit>(_onInit);
    on<BananTilePlaced>(_onTilePlaced);
    on<BananTileRemoved>(_onTileRemoved);
    on<BananNextProblem>(_onNextProblem);
    on<BananSkipProblem>(_onSkipProblem);
    on<BananRetry>(_onRetry);
    on<BananReadQuestion>(_onReadQuestion);
    on<BananStop>(_onStop);
    on<BananLoadMoreProblems>(_onLoadMore);
    on<BananPlayAgain>(_onPlayAgain);
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  /// Build a fresh slotMap (all empty) for a problem
  Map<int, String?> _emptySlots(BananProblemModel problem) => {
    for (int i = 0; i < problem.letters.length; i++) i: null,
  };

  /// Build a fresh shuffled tile list for a problem
  List<BananLetterTile> _freshTiles(BananProblemModel problem) =>
      problem.shuffledTiles;

  BananLoaded _buildLoadedState({
    required List<BananProblemModel> problems,
    required int index,
    int roundCorrect = 0,
    int roundAnswered = 0,
  }) {
    final problem = problems[index];
    return BananLoaded(
      problems: problems,
      currentIndex: index,
      slotMap: _emptySlots(problem),
      availableTiles: _freshTiles(problem),
      roundCorrect: roundCorrect,
      roundAnswered: roundAnswered,
    );
  }

  bool get _shouldLoadMore =>
      state is BananLoaded &&
      (state as BananLoaded).currentIndex >=
          (state as BananLoaded).problems.length - 10;

  // ═══════════════════════════════════════════════════════
  //  INIT
  // ═══════════════════════════════════════════════════════
  Future<void> _onInit(BananInit event, Emitter<BananState> emit) async {
    emit(const BananLoading());
    _roundCorrect = 0;
    _roundAnswered = 0;
    _answeredIds.clear();
    _repository.resetPagination();

    try {
      final problems = await _repository.fetchProblems(limit: 50);
      if (problems.isEmpty) {
        emit(const BananError(errorMessage: 'No problems available'));
        return;
      }

      final loaded = _buildLoadedState(problems: problems, index: 0);
      emit(loaded);
      await _playQuestionAudio(loaded.currentProblem!);
    } catch (e) {
      emit(BananError(errorMessage: e.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  TILE PLACED
  // ═══════════════════════════════════════════════════════
  Future<void> _onTilePlaced(
    BananTilePlaced event,
    Emitter<BananState> emit,
  ) async {
    if (state is! BananLoaded) return;
    final s = state as BananLoaded;

    // Guard: locked while answer is shown
    if (s.answerStatus != BananAnswerStatus.none) return;
    // Guard: slot already occupied
    if (s.slotMap[event.slotIndex] != null) return;
    // Guard: tile not in available pool
    if (!s.availableTiles.any((t) => t.id == event.tileId)) return;

    final newSlotMap = Map<int, String?>.from(s.slotMap)
      ..[event.slotIndex] = event.tileId;

    final updated = s.copyWith(slotMap: newSlotMap);

    // Auto-check when every slot is filled
    if (updated.allSlotsFilled) {
      final isCorrect = _checkAnswer(updated);
      _roundAnswered++;
      if (isCorrect) _roundCorrect++;

      emit(
        updated.copyWith(
          answerStatus: isCorrect
              ? BananAnswerStatus.correct
              : BananAnswerStatus.wrong,
          roundCorrect: _roundCorrect,
          roundAnswered: _roundAnswered,
        ),
      );

      if (isCorrect) {
        _isPlayingFeedbackAudio = true;
        await _playYayAudio();
        _isPlayingFeedbackAudio = false;
        DailyChallengeService.instance.reportProgress('banan');
      } else {
        _isPlayingFeedbackAudio = true;
        await _playWrongAudio();
        await Future.delayed(const Duration(milliseconds: 900));
        _isPlayingFeedbackAudio = false;

        // Reset slots so kid can try again
        if (state is BananLoaded) {
          final afterWrong = state as BananLoaded;
          emit(
            afterWrong.copyWith(
              slotMap: _emptySlots(afterWrong.currentProblem!),
              answerStatus: BananAnswerStatus.none,
            ),
          );
        }
      }
    } else {
      emit(updated);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  TILE REMOVED (tap filled slot to return tile)
  // ═══════════════════════════════════════════════════════
  void _onTileRemoved(BananTileRemoved event, Emitter<BananState> emit) {
    if (state is! BananLoaded) return;
    final s = state as BananLoaded;

    // Can only remove while answer is not locked
    if (s.answerStatus != BananAnswerStatus.none) return;
    if (s.slotMap[event.slotIndex] == null) return;

    final newSlotMap = Map<int, String?>.from(s.slotMap)
      ..[event.slotIndex] = null;
    emit(s.copyWith(slotMap: newSlotMap));
  }

  // ═══════════════════════════════════════════════════════
  //  NEXT PROBLEM
  // ═══════════════════════════════════════════════════════
  Future<void> _onNextProblem(
    BananNextProblem event,
    Emitter<BananState> emit,
  ) async {
    if (state is! BananLoaded) return;
    final s = state as BananLoaded;

    final nextIndex = s.currentIndex + 1;

    // Need more problems?
    if (nextIndex >= s.problems.length) {
      // No more problems in buffer, try to load more
      if (_repository.hasMoreData && !_isLoadingMoreProblems) {
        add(const BananLoadMoreProblems());
        // Wait for load to complete before proceeding
        return;
      } else if (!_repository.hasMoreData) {
        // No more problems in database - round complete
        emit(
          BananRoundCompleted(
            roundCorrect: _roundCorrect,
            roundAnswered: _roundAnswered,
            isAllQuestionsExhausted: true,
          ),
        );
        return;
      }
      return;
    }

    final nextProblem = s.problems[nextIndex];
    final nextState = s.copyWith(
      currentIndex: nextIndex,
      slotMap: _emptySlots(nextProblem),
      availableTiles: _freshTiles(nextProblem),
      answerStatus: BananAnswerStatus.none,
    );
    emit(nextState);
    await _playQuestionAudio(nextProblem);

    // Pre-fetch more if running low
    if (_shouldLoadMore && _repository.hasMoreData && !_isLoadingMoreProblems) {
      add(const BananLoadMoreProblems());
    }
  }

  Future<void> _onSkipProblem(
    BananSkipProblem event,
    Emitter<BananState> emit,
  ) async {
    if (state is! BananLoaded) return;
    final s = state as BananLoaded;
    final problem = s.currentProblem;
    if (problem == null) return;

    _answeredIds.add(problem.id);

    // 1. Play correct word audio
    emit(s.copyWith(isPlayingSkipAudio: true));
    if (problem.correctAudioUrl.isNotEmpty) {
      await _playCorrectAnswerAudio(problem.correctAudioUrl);
    }

    if (state is! BananLoaded) return;

    // 2. Map the correct letters to the actual Tile IDs present in the problem
    final correctSlotMap = <int, String?>{};
    final List<BananLetterTile> pool = List.from(problem.shuffledTiles);

    for (int i = 0; i < problem.letters.length; i++) {
      final targetLetter = problem.letters[i];
      // Find the first available tile in the pool that matches the letter
      final tileIndex = pool.indexWhere((t) => t.letter == targetLetter);

      if (tileIndex != -1) {
        correctSlotMap[i] = pool[tileIndex].id;
        pool.removeAt(
          tileIndex,
        ); // Remove so we don't reuse the same tile instance
      }
    }

    _roundAnswered++;

    // 3. Emit state with the filled slots and "correct" status to trigger green UI
    emit(
      (state as BananLoaded).copyWith(
        slotMap: correctSlotMap,
        answerStatus: BananAnswerStatus.correct, // Shows green slots
        isPlayingSkipAudio: false,
        roundAnswered: _roundAnswered,
        roundCorrect: _roundCorrect,
      ),
    );

    // 4. Wait for the kid to see the correct answer before moving
    await Future.delayed(const Duration(milliseconds: 2000));
    add(const BananNextProblem());
  }

  // ═══════════════════════════════════════════════════════
  //  RETRY (reset current problem)
  // ═══════════════════════════════════════════════════════
  Future<void> _onRetry(BananRetry event, Emitter<BananState> emit) async {
    if (state is! BananLoaded) return;
    final s = state as BananLoaded;
    final problem = s.currentProblem;
    if (problem == null) return;

    emit(
      s.copyWith(
        slotMap: _emptySlots(problem),
        availableTiles: _freshTiles(problem),
        answerStatus: BananAnswerStatus.none,
      ),
    );
    await _playQuestionAudio(problem);
  }

  // ═══════════════════════════════════════════════════════
  //  READ QUESTION
  // ═══════════════════════════════════════════════════════
  Future<void> _onReadQuestion(
    BananReadQuestion event,
    Emitter<BananState> emit,
  ) async {
    if (state is! BananLoaded) return;
    final problem = (state as BananLoaded).currentProblem;
    if (problem == null) return;

    emit((state as BananLoaded).copyWith(isPlayingAudio: true));
    await _playQuestionAudio(problem);
    if (state is BananLoaded) {
      emit((state as BananLoaded).copyWith(isPlayingAudio: false));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  LOAD MORE
  // ═══════════════════════════════════════════════════════
  Future<void> _onLoadMore(
    BananLoadMoreProblems event,
    Emitter<BananState> emit,
  ) async {
    if (_isLoadingMoreProblems || state is! BananLoaded) return;

    _isLoadingMoreProblems = true;
    final s = state as BananLoaded;
    emit(s.copyWith(isLoadingMore: true));

    try {
      final more = await _repository.fetchProblems(limit: 50);
      if (state is! BananLoaded) return;

      final filtered = more.where((p) => !_answeredIds.contains(p.id)).toList();
      
      // If no new filtered problems were added, we've exhausted all questions
      if (filtered.isEmpty) {
        _repository.markNoMoreData();
        if (state is! BananLoaded) return;
        
        // If we're at the end of current problems, show completion
        if (s.currentIndex >= s.problems.length - 1) {
          emit(
            (state as BananLoaded).copyWith(isLoadingMore: false),
          );
          emit(
            BananRoundCompleted(
              roundCorrect: _roundCorrect,
              roundAnswered: _roundAnswered,
              isAllQuestionsExhausted: true,
            ),
          );
          return;
        }
      }
      
      final updated = [...(state as BananLoaded).problems, ...filtered];

      emit(
        (state as BananLoaded).copyWith(
          problems: updated,
          isLoadingMore: false,
        ),
      );
      
      // If we were waiting for more problems to continue, auto-advance
      if (s.currentIndex >= s.problems.length - 1) {
        add(const BananNextProblem());
      }
    } catch (e) {
      debugPrint('[BananBloc] load more error: $e');
      if (state is BananLoaded) {
        emit((state as BananLoaded).copyWith(isLoadingMore: false));
      }
    } finally {
      _isLoadingMoreProblems = false;
    }
  }

  // ═══════════════════════════════════════════════════════
  //  STOP
  // ═══════════════════════════════════════════════════════
  void _onStop(BananStop event, Emitter<BananState> emit) {
    _audioPlayer.stop();
    _questionAudioPlayer.stop();
    _isPlayingFeedbackAudio = false;
    _isPlayingQuestionAudio = false;
  }

  // ═══════════════════════════════════════════════════════
  //  PLAY AGAIN
  // ═══════════════════════════════════════════════════════
  Future<void> _onPlayAgain(
    BananPlayAgain event,
    Emitter<BananState> emit,
  ) async {
    _audioPlayer.stop();
    _questionAudioPlayer.stop();
    _isPlayingFeedbackAudio = false;
    _isPlayingQuestionAudio = false;
    _repository.resetPagination();
    add(const BananInit());
  }

  // ═══════════════════════════════════════════════════════
  //  ANSWER CHECK
  // ═══════════════════════════════════════════════════════
  bool _checkAnswer(BananLoaded state) {
    final problem = state.currentProblem!;
    final letters = problem.letters;
    for (int i = 0; i < letters.length; i++) {
      final tileId = state.slotMap[i];
      if (tileId == null) return false;
      final tile = state.availableTiles.firstWhere(
        (t) => t.id == tileId,
        orElse: () => const BananLetterTile(id: '', letter: ''),
      );
      if (tile.letter != letters[i]) return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════
  //  AUDIO HELPERS
  // ═══════════════════════════════════════════════════════
  Future<void> _playQuestionAudio(BananProblemModel problem) async {
    if (problem.questionAudioUrl.isEmpty) return;
    _isPlayingQuestionAudio = true;
    try {
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(problem.questionAudioUrl));
    } catch (e) {
      debugPrint('[BananBloc] question audio error: $e');
    } finally {
      _isPlayingQuestionAudio = false;
    }
  }

  Future<void> _playCorrectAnswerAudio(String url) async {
    try {
      await _questionAudioPlayer.stop();
      await _questionAudioPlayer.play(UrlSource(url));
      await _questionAudioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('[BananBloc] answer audio error: $e');
    }
  }

  Future<void> _playYayAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audios/ui/yay_sound.wav'));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('[BananBloc] yay audio error: $e');
    }
  }

  Future<void> _playWrongAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audios/ui/no_sound.mp3'));
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('[BananBloc] wrong audio error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  //  DISPOSE
  // ═══════════════════════════════════════════════════════
  @override
  Future<void> close() {
    _audioPlayer.dispose();
    _questionAudioPlayer.dispose();
    return super.close();
  }
}
