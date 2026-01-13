import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart'; // For debugPrint

import 'bornomala_event.dart';
import 'bornomala_state.dart';

class BornomalaBloc extends Bloc<BornomalaEvent, BornomalaState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final String _apiUrl = "https://checkalphabettext-argk2dorvq-uc.a.run.app";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;

  // Prevents mic from opening when feedback/validation is happening
  bool _isPlayingFeedbackAudio = false;

  BornomalaBloc() : super(const BornomalaInitial()) {
    on<BornomalaInit>(_onInit);
    on<BornomalaNext>(_onNext);
    on<BornomalaPrevious>(_onPrevious);
    on<BornomalaRetry>(_onRetry);
    on<BornomalaStartListening>(_onListen);
    on<BornomalaSpeechDetected>(_onSpeechDetected);
    on<BornomalaStop>(_onStop);

    _audioPlayer.onPlayerComplete.listen((_) {
      // STRICT GUARD:
      // 1. If we are waiting for API (isValidating) -> STOP.
      // 2. If we are playing "Yay/No" (Feedback) -> STOP.
      // 3. If the answer is Correct (Waiting for navigation) -> STOP.
      if (state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == AnswerStatus.correct)
        return;

      add(BornomalaStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(
    BornomalaInit event,
    Emitter<BornomalaState> emit,
  ) async {
    emit(const BornomalaLoaded(index: 0));
    await _playAlphabetAudio(0);
  }

  // ================= NAV =================
  Future<void> _onNext(
    BornomalaNext event,
    Emitter<BornomalaState> emit,
  ) async {
    _cleanupListening();
    final next = (state.index + 1) % bengaliAlphabet.length;
    emit(BornomalaLoaded(index: next, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(next);
  }

  Future<void> _onPrevious(
    BornomalaPrevious event,
    Emitter<BornomalaState> emit,
  ) async {
    _cleanupListening();
    final prev =
        (state.index - 1 + bengaliAlphabet.length) % bengaliAlphabet.length;
    emit(BornomalaLoaded(index: prev, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(prev);
  }

  Future<void> _onRetry(
    BornomalaRetry event,
    Emitter<BornomalaState> emit,
  ) async {
    _cleanupListening();
    emit(BornomalaLoaded(index: state.index, answerStatus: AnswerStatus.none));
    await _playAlphabetAudio(state.index);
  }

  // ================= LISTEN =================
  Future<void> _onListen(
    BornomalaStartListening event,
    Emitter<BornomalaState> emit,
  ) async {
    // 1. Guard against starting mic during validation or success state
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == AnswerStatus.correct)
      return;

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) => _isListening = false,
      onStatus: (status) {
        // Optional: Handle status changes if needed
      },
    );

    if (!available) return;

    _isListening = true;
    if (state is BornomalaLoaded) {
      emit(
        (state as BornomalaLoaded).copyWith(
          isListening: true,
          answerStatus: AnswerStatus.none,
        ),
      );
    }

    // 2. Start Listening
    await _speech.listen(
      localeId: 'bn_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) {
        if (_hasSpoken) return; // Ignore multiple results
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _hasSpoken = true;
          // Immediately add event to stop timer race conditions
          add(BornomalaSpeechDetected(result.recognizedWords));
        }
      },
    );

    // 3. Start Timeout Timer (6 Seconds)
    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      // SAFETY CHECK: If user spoke or we are validating, DO NOT REPLAY AUDIO
      if (_hasSpoken || state.isValidating) return;

      await _speech.stop();
      _isListening = false;
      await _playAlphabetAudio(
        state.index,
      ); // Will restart loop via onPlayerComplete
    });
  }

  // ================= SPEECH DETECTED (THE FIX) =================
  Future<void> _onSpeechDetected(
    BornomalaSpeechDetected event,
    Emitter<BornomalaState> emit,
  ) async {
    // 1. STOP EVERYTHING IMMEDIATELY
    _listenTimeoutTimer?.cancel(); // Kill the timer
    await _speech.stop(); // Kill the mic
    await _audioPlayer.stop(); // Kill any audio that might have just started
    _isListening = false;

    // 2. Set Validating State
    if (state is BornomalaLoaded) {
      emit(
        (state as BornomalaLoaded).copyWith(
          isListening: false,
          isValidating: true, // UI shows loading
          recognizedText: event.text,
          answerStatus: AnswerStatus.none,
        ),
      );
    }

    // 3. API Call
    bool isCorrect = false;
    try {
      isCorrect = await _checkRhymeWithApi(event.text, state.currentAlphabet);
    } catch (e) {
      debugPrint("API Error: $e");
    }

    // 4. Handle Result
    _isPlayingFeedbackAudio =
        true; // Lock mic so onPlayerComplete doesn't trigger

    if (state is BornomalaLoaded) {
      emit(
        (state as BornomalaLoaded).copyWith(
          isValidating: false, // Loading done
          answerStatus: isCorrect ? AnswerStatus.correct : AnswerStatus.wrong,
        ),
      );
    }

    if (isCorrect) {
      await _playHurrayAudio();
      // Logic: Wait for UI to push to writing screen.
      // Do NOT set _isPlayingFeedbackAudio to false here, let navigation handle it.
      _isPlayingFeedbackAudio = false;
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      // Clear Error Status
      if (state is BornomalaLoaded) {
        emit(
          (state as BornomalaLoaded).copyWith(answerStatus: AnswerStatus.none),
        );
      }

      _isPlayingFeedbackAudio = false; // Unlock
      await _playAlphabetAudio(
        state.index,
      ); // Replay alphabet (triggers mic loop)
    }
  }

  // ================= API LOGIC =================
  Future<bool> _checkRhymeWithApi(String text, String alphabet) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "alphabet": alphabet}),
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
    // CRITICAL FIX: Never play alphabet audio if we are in the middle of validating
    if (state.isValidating) return;

    _hasSpoken = false;
    _isPlayingFeedbackAudio = false;
    final letter = bengaliAlphabet[index];

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/bengali_audio/$letter.wav'));
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

  void _onStop(BornomalaStop event, Emitter<BornomalaState> emit) {
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
