import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_event.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_state.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class AlphabetBloc extends Bloc<AlphabetEvent, AlphabetState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final String _apiUrl = "https://checkalphabettext-argk2dorvq-uc.a.run.app";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;
  bool _isPlayingFeedbackAudio = false;

  AlphabetBloc() : super(const AlphabetInitial()) {
    on<AlphabetInit>(_onInit);
    on<AlphabetNext>(_onNext);
    on<AlphabetPrevious>(_onPrevious);
    on<AlphabetRetry>(_onRetry);
    on<AlphabetStartListening>(_onListen);
    on<AlphabetSpeechDetected>(_onSpeechDetected);
    on<AlphabetStop>(_onStop);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == AnswerStatus.correct)
        return;

      add(AlphabetStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(AlphabetInit event, Emitter<AlphabetState> emit) async {
    emit(const AlphabetLoaded(index: 0));
    await _playAlphabetAudio(0);
  }

  // ================= NAV =================
  Future<void> _onNext(AlphabetNext event, Emitter<AlphabetState> emit) async {
    _cleanupListening();
    final next = (state.index + 1) % englishAlphabet.length;
    emit(AlphabetLoaded(index: next, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(next);
  }

  Future<void> _onPrevious(
    AlphabetPrevious event,
    Emitter<AlphabetState> emit,
  ) async {
    _cleanupListening();
    final prev =
        (state.index - 1 + englishAlphabet.length) % englishAlphabet.length;
    emit(AlphabetLoaded(index: prev, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(prev);
  }

  Future<void> _onRetry(
    AlphabetRetry event,
    Emitter<AlphabetState> emit,
  ) async {
    _cleanupListening();
    emit(AlphabetLoaded(index: state.index, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(state.index);
  }

  // ================= LISTEN =================
  Future<void> _onListen(
    AlphabetStartListening event,
    Emitter<AlphabetState> emit,
  ) async {
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == AnswerStatus.correct)
      return;

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) => _isListening = false,
      onStatus: (status) {},
    );

    if (!available) return;

    _isListening = true;
    if (state is AlphabetLoaded) {
      emit(
        (state as AlphabetLoaded).copyWith(
          isListening: true,
          answerStatus: AnswerStatus.none,
        ),
      );
    }

    // Changed locale to 'en_US' for English
    await _speech.listen(
      localeId: 'en_US',
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) {
        if (_hasSpoken) return;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _hasSpoken = true;
          add(AlphabetSpeechDetected(result.recognizedWords));
        }
      },
    );

    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (_hasSpoken || state.isValidating) return;

      await _speech.stop();
      _isListening = false;
      await _playAlphabetAudio(state.index);
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    AlphabetSpeechDetected event,
    Emitter<AlphabetState> emit,
  ) async {
    _listenTimeoutTimer?.cancel();
    await _speech.stop();
    await _audioPlayer.stop();
    _isListening = false;

    if (state is AlphabetLoaded) {
      emit(
        (state as AlphabetLoaded).copyWith(
          isListening: false,
          isValidating: true,
          recognizedText: event.text,
          answerStatus: AnswerStatus.none,
        ),
      );
    }

    bool isCorrect = false;
    try {
      isCorrect = await _checkRhymeWithApi(event.text, state.currentAlphabet);
    } catch (e) {
      debugPrint("API Error: $e");
    }

    _isPlayingFeedbackAudio = true;

    if (state is AlphabetLoaded) {
      emit(
        (state as AlphabetLoaded).copyWith(
          isValidating: false,
          answerStatus: isCorrect ? AnswerStatus.correct : AnswerStatus.wrong,
        ),
      );
    }

    if (isCorrect) {
      await _playHurrayAudio();
      _isPlayingFeedbackAudio = false;
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is AlphabetLoaded) {
        emit(
          (state as AlphabetLoaded).copyWith(answerStatus: AnswerStatus.none),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playAlphabetAudio(state.index);
    }
  }

  // ================= API LOGIC =================
  Future<bool> _checkRhymeWithApi(String text, String alphabet) async {
    try {
      LoggerService.logInfo("Text : $text");
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "alphabet": alphabet,
          "language": "english",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isCorrect'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ================= AUDIO HELPERS =================
  Future<void> _playAlphabetAudio(int index) async {
    if (state.isValidating) return;

    _hasSpoken = false;
    _isPlayingFeedbackAudio = false;
    final letter = englishAlphabet[index];

    await _audioPlayer.stop();
    // Assuming you have English audio assets here
    await _audioPlayer.play(AssetSource('audios/english_audio/$letter.wav'));
  }

  Future<void> _playHurrayAudio() async {
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
    _hasSpoken = false;
    _isListening = false;
    _isPlayingFeedbackAudio = false;
  }

  void _onStop(AlphabetStop event, Emitter<AlphabetState> emit) {
    _cleanupListening();
    _audioPlayer.stop();
  }

  @override
  Future<void> close() {
    _cleanupListening();
    _audioPlayer.dispose();
    return super.close();
  }
}
