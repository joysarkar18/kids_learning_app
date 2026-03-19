import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/app_lifecycle_service.dart';
import 'sothik_uttor_event.dart';
import 'sothik_uttor_state.dart';
import '../data/repo/question_repository.dart';

class SothikUttorBloc extends Bloc<SothikUttorEvent, SothikUttorState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final QuestionRepository _repository = QuestionRepository();

  static const String _validationApiUrl =
      "https://checkquestionanswer-argk2dorvq-uc.a.run.app";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;
  bool _isPlayingFeedbackAudio = false;
  bool _isLoadingMoreQuestions = false;
  bool _isAudioPlayerDisposed = false;

  SothikUttorBloc() : super(const SothikUttorInitial()) {
    // Register audio player and speech recognizer for lifecycle management
    AppLifecycleService().registerAudioPlayer(_audioPlayer);
    AppLifecycleService().registerSpeechRecognizer(_speech);

    on<SothikUttorInit>(_onInit);
    on<SothikUttorNextQuestion>(_onNextQuestion);
    on<SothikUttorSkipQuestion>(_onSkipQuestion);
    on<SothikUttorStartListening>(_onStartListening);
    on<SothikUttorSpeechDetected>(_onSpeechDetected);
    on<SothikUttorRetry>(_onRetry);
    on<SothikUttorStop>(_onStop);
    on<SothikUttorLoadMoreQuestions>(_onLoadMoreQuestions);
    on<SothikUttorOptionSelected>(_onOptionSelected);

    _audioPlayer.onPlayerComplete.listen((_) {
      final currentQuestion = state.currentQuestion;
      // Don't auto-start listening for MCQ questions
      if (currentQuestion != null && currentQuestion.isMcqQuestion) {
        return;
      }

      if (_isAudioPlayerDisposed ||
          state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == SothikUttorAnswerStatus.correct ||
          state.isPlayingSkipAudio) {
        return;
      }

      add(SothikUttorStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(
    SothikUttorInit event,
    Emitter<SothikUttorState> emit,
  ) async {
    emit(const SothikUttorLoading());

    try {
      final questions = await _repository.fetchQuestions(limit: 50);

      if (questions.isEmpty) {
        emit(const SothikUttorError(errorMessage: 'No questions available'));
        return;
      }

      emit(SothikUttorLoaded(questions: questions, currentIndex: 0));
      await _playQuestionAudio();
    } catch (e) {
      emit(SothikUttorError(errorMessage: e.toString()));
    }
  }

  // ================= NEXT QUESTION =================
  Future<void> _onNextQuestion(
    SothikUttorNextQuestion event,
    Emitter<SothikUttorState> emit,
  ) async {
    _cleanupListening();

    if (state is! SothikUttorLoaded) return;
    final currentState = state as SothikUttorLoaded;

    final nextIndex = currentState.currentIndex + 1;

    // Check if we've completed all questions
    if (nextIndex >= currentState.questions.length) {
      if (_repository.hasMoreData && !_isLoadingMoreQuestions) {
        // Load more questions
        add(SothikUttorLoadMoreQuestions());
      } else {
        emit(SothikUttorCompleted(questions: currentState.questions));
      }
      return;
    }

    emit(
      currentState.copyWith(
        currentIndex: nextIndex,
        answerStatus: SothikUttorAnswerStatus.none,
        recognizedText: '',
        clearSelectedOption: true,
      ),
    );

    // Check if we should load more questions (when 10 questions remaining)
    if (currentState.shouldLoadMore &&
        _repository.hasMoreData &&
        !_isLoadingMoreQuestions) {
      add(SothikUttorLoadMoreQuestions());
    }

    await _playQuestionAudio();
  }

  // ================= SKIP QUESTION =================
  Future<void> _onSkipQuestion(
    SothikUttorSkipQuestion event,
    Emitter<SothikUttorState> emit,
  ) async {
    _cleanupListening();

    if (state is! SothikUttorLoaded) return;
    final currentState = state as SothikUttorLoaded;

    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null) return;

    // Set skip audio playing state
    emit(currentState.copyWith(isPlayingSkipAudio: true));

    // Play the correct answer audio
    await _playCorrectAnswerAudio(currentQuestion.correctAnswerAudioUrl);

    // Wait for audio to finish (we'll use a completer for this)
    if (!_isAudioPlayerDisposed) {
      await _audioPlayer.onPlayerComplete.first;
    }

    if (state is! SothikUttorLoaded) return;

    // Reset skip audio state and move to next question
    emit((state as SothikUttorLoaded).copyWith(isPlayingSkipAudio: false));

    // Move to next question
    add(SothikUttorNextQuestion());
  }

  // ================= LOAD MORE QUESTIONS =================
  Future<void> _onLoadMoreQuestions(
    SothikUttorLoadMoreQuestions event,
    Emitter<SothikUttorState> emit,
  ) async {
    if (_isLoadingMoreQuestions) return;
    if (state is! SothikUttorLoaded) return;

    _isLoadingMoreQuestions = true;
    final currentState = state as SothikUttorLoaded;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final newQuestions = await _repository.fetchQuestions(limit: 50);

      if (state is! SothikUttorLoaded) return;

      final updatedQuestions = [...currentState.questions, ...newQuestions];

      emit(
        (state as SothikUttorLoaded).copyWith(
          questions: updatedQuestions,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint('Error loading more questions: $e');
      if (state is SothikUttorLoaded) {
        emit((state as SothikUttorLoaded).copyWith(isLoadingMore: false));
      }
    } finally {
      _isLoadingMoreQuestions = false;
    }
  }

  // ================= START LISTENING =================
  Future<void> _onStartListening(
    SothikUttorStartListening event,
    Emitter<SothikUttorState> emit,
  ) async {
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == SothikUttorAnswerStatus.correct ||
        state.isPlayingSkipAudio) {
      return;
    }

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) => _isListening = false,
      onStatus: (status) {},
    );

    if (!available) return;

    _isListening = true;
    if (state is SothikUttorLoaded) {
      emit(
        (state as SothikUttorLoaded).copyWith(
          isListening: true,
          answerStatus: SothikUttorAnswerStatus.none,
        ),
      );
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
          add(SothikUttorSpeechDetected(result.recognizedWords));
        }
      },
    );

    // Timeout after 6 seconds
    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (_hasSpoken || state.isValidating) return;

      await _speech.stop();
      _isListening = false;
      await _playQuestionAudio();
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    SothikUttorSpeechDetected event,
    Emitter<SothikUttorState> emit,
  ) async {
    _listenTimeoutTimer?.cancel();
    await _speech.stop();
    _isListening = false;

    if (!_isAudioPlayerDisposed) {
      await _audioPlayer.stop();
    }

    if (state is! SothikUttorLoaded) return;
    final currentState = state as SothikUttorLoaded;

    emit(
      currentState.copyWith(
        isListening: false,
        isValidating: true,
        recognizedText: event.text,
        answerStatus: SothikUttorAnswerStatus.none,
      ),
    );

    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null) return;

    // Validate answer via API
    bool isCorrect = false;
    try {
      isCorrect = await _validateAnswerWithApi(
        userAnswer: event.text,
        answerText: currentQuestion.answerText,
        questionText: currentQuestion.questionText,
        answerAudioText: currentQuestion.answerAudioText,
        language: 'bengali',
      );
    } catch (e) {
      debugPrint("API Error: $e");
    }

    _isPlayingFeedbackAudio = true;

    if (state is! SothikUttorLoaded) return;

    emit(
      (state as SothikUttorLoaded).copyWith(
        isValidating: false,
        answerStatus: isCorrect
            ? SothikUttorAnswerStatus.correct
            : SothikUttorAnswerStatus.wrong,
      ),
    );

    if (isCorrect) {
      await _playYayAudio();
      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('sothik_uttor');
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is SothikUttorLoaded) {
        emit(
          (state as SothikUttorLoaded).copyWith(
            answerStatus: SothikUttorAnswerStatus.none,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playQuestionAudio();
    }
  }

  // ================= MCQ OPTION SELECTED =================
  Future<void> _onOptionSelected(
    SothikUttorOptionSelected event,
    Emitter<SothikUttorState> emit,
  ) async {
    if (state is! SothikUttorLoaded) return;
    final currentState = state as SothikUttorLoaded;

    // Prevent multiple selections while processing
    if (currentState.answerStatus != SothikUttorAnswerStatus.none) return;

    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null || !currentQuestion.isMcqQuestion) return;

    // Find the selected option
    final selectedOption = currentQuestion.options.firstWhere(
      (o) => o.id == event.optionId,
      orElse: () => currentQuestion.options.first,
    );

    emit(currentState.copyWith(selectedOptionId: event.optionId));

    // Check if the answer is correct (no API call needed)
    final isCorrect = selectedOption.isCorrect;

    _isPlayingFeedbackAudio = true;

    emit(
      currentState.copyWith(
        selectedOptionId: event.optionId,
        answerStatus: isCorrect
            ? SothikUttorAnswerStatus.correct
            : SothikUttorAnswerStatus.wrong,
      ),
    );

    if (isCorrect) {
      await _playYayAudio();
      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('sothik_uttor');
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is SothikUttorLoaded) {
        emit(
          (state as SothikUttorLoaded).copyWith(
            answerStatus: SothikUttorAnswerStatus.none,
            clearSelectedOption: true,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playQuestionAudio();
    }
  }

  // ================= RETRY =================
  Future<void> _onRetry(
    SothikUttorRetry event,
    Emitter<SothikUttorState> emit,
  ) async {
    _cleanupListening();

    if (state is SothikUttorLoaded) {
      emit(
        (state as SothikUttorLoaded).copyWith(
          answerStatus: SothikUttorAnswerStatus.none,
          recognizedText: '',
          clearSelectedOption: true,
        ),
      );
    }

    await _playQuestionAudio();
  }

  // ================= STOP =================
  void _onStop(SothikUttorStop event, Emitter<SothikUttorState> emit) {
    _cleanupListening();
    if (!_isAudioPlayerDisposed) {
      _audioPlayer.stop();
    }
  }

  // ================= API VALIDATION =================
  Future<bool> _validateAnswerWithApi({
    required String userAnswer,
    required String answerText,
    String? questionText,
    String? answerAudioText,
    String language = 'bengali',
  }) async {
    final requestBody = {
      "userAnswer": userAnswer,
      "answerText": answerText,
      if (questionText != null && questionText.isNotEmpty)
        "questionText": questionText,
      if (answerAudioText != null && answerAudioText.isNotEmpty)
        "answerAudioText": answerAudioText,
      "language": language,
    };

    // Log request
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔵 API REQUEST: $_validationApiUrl');
    debugPrint('📤 Request Body:');
    debugPrint('   userAnswer: "$userAnswer"');
    debugPrint('   answerText: "$answerText"');
    debugPrint('   questionText: "$questionText"');
    debugPrint('   answerAudioText: "$answerAudioText"');
    debugPrint('   language: "$language"');
    debugPrint('───────────────────────────────────────────────────────');

    try {
      final response = await http.post(
        Uri.parse(_validationApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      // Log response
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Parsed Response:');
        debugPrint('   success: ${data['success']}');
        debugPrint('   isCorrect: ${data['isCorrect']}');
        debugPrint('   matchedBy: ${data['matchedBy']}');
        debugPrint('═══════════════════════════════════════════════════════');

        if (data['success'] == true) {
          return data['isCorrect'] == true;
        }
        return false;
      }

      debugPrint('❌ API returned non-200 status code: ${response.statusCode}');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    } catch (e) {
      debugPrint('❌ Validation API error: $e');
      debugPrint('⚠️ Falling back to simple text comparison');
      debugPrint('═══════════════════════════════════════════════════════');
      // Fallback: simple text comparison
      return userAnswer.trim().toLowerCase() == answerText.trim().toLowerCase();
    }
  }

  // ================= AUDIO HELPERS =================
  Future<void> _playQuestionAudio() async {
    if (state.isValidating || _isAudioPlayerDisposed) return;

    _hasSpoken = false;
    _isPlayingFeedbackAudio = false;

    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    try {
      await _audioPlayer.stop();

      final audioUrl = currentQuestion.questionAudioUrl;
      if (audioUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(audioUrl));
      } else {
        // No audio URL, start listening directly
        add(SothikUttorStartListening());
      }
    } catch (e) {
      debugPrint('Error playing question audio: $e');
      // If audio fails, still start listening
      add(SothikUttorStartListening());
    }
  }

  Future<void> _playCorrectAnswerAudio(String audioUrl) async {
    if (_isAudioPlayerDisposed) return;
    try {
      await _audioPlayer.stop();

      if (audioUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint('Error playing correct answer audio: $e');
    }
  }

  Future<void> _playYayAudio() async {
    if (_isAudioPlayerDisposed) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audios/ui/yay_sound.wav'));
    } catch (e) {
      debugPrint('Error playing yay audio: $e');
    }
  }

  Future<void> _playWrongAudio() async {
    if (_isAudioPlayerDisposed) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audios/ui/no_sound.mp3'));
    } catch (e) {
      debugPrint('Error playing wrong audio: $e');
    }
  }

  // ================= CLEANUP =================
  void _cleanupListening() {
    _listenTimeoutTimer?.cancel();
    _speech.stop();
    _hasSpoken = false;
    _isListening = false;
    _isPlayingFeedbackAudio = false;
  }

  @override
  Future<void> close() {
    _cleanupListening();
    _isAudioPlayerDisposed = true;
    // Unregister from lifecycle service
    AppLifecycleService().unregisterAudioPlayer(_audioPlayer);
    AppLifecycleService().unregisterSpeechRecognizer(_speech);
    _audioPlayer.dispose();
    return super.close();
  }
}
