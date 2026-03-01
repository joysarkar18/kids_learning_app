import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/logger_service.dart';

import 'bangla_sonkha_event.dart';
import 'bangla_sonkha_state.dart';

class BanglaSonkhaBloc extends Bloc<BanglaSonkhaEvent, BanglaSonkhaState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final String _apiUrl = "https://checkbengalinumber-argk2dorvq-uc.a.run.app";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;

  bool _isPlayingFeedbackAudio = false;

  BanglaSonkhaBloc() : super(const BanglaSonkhaInitial()) {
    on<BanglaSonkhaInit>(_onInit);
    on<BanglaSonkhaNext>(_onNext);
    on<BanglaSonkhaPrevious>(_onPrevious);
    on<BanglaSonkhaRetry>(_onRetry);
    on<BanglaSonkhaStartListening>(_onListen);
    on<BanglaSonkhaSpeechDetected>(_onSpeechDetected);
    on<BanglaSonkhaStop>(_onStop);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == SonkhaAnswerStatus.correct)
        return;

      add(BanglaSonkhaStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(
    BanglaSonkhaInit event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    LoggerService.logInfo('[BanglaSonkhaBloc] _onInit called → event.startingIndex=${event.startingIndex}');
    final index = event.startingIndex ?? 0;
    LoggerService.logInfo('[BanglaSonkhaBloc] Emitting BanglaSonkhaLoaded(index: $index)');
    emit(BanglaSonkhaLoaded(index: index));
    await _playNumberAudio(index);
  }

  // ================= NAV =================
  Future<void> _onNext(
    BanglaSonkhaNext event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    _cleanupListening();
    final next = (state.index + 1) % bengaliNumbers.length;
    emit(
      BanglaSonkhaLoaded(index: next, answerStatus: SonkhaAnswerStatus.none),
    );
    await _playNumberAudio(next);
  }

  Future<void> _onPrevious(
    BanglaSonkhaPrevious event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    _cleanupListening();
    final prev =
        (state.index - 1 + bengaliNumbers.length) % bengaliNumbers.length;
    emit(
      BanglaSonkhaLoaded(index: prev, answerStatus: SonkhaAnswerStatus.none),
    );
    await _playNumberAudio(prev);
  }

  Future<void> _onRetry(
    BanglaSonkhaRetry event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    _cleanupListening();
    emit(
      BanglaSonkhaLoaded(
        index: state.index,
        answerStatus: SonkhaAnswerStatus.none,
      ),
    );
    await _playNumberAudio(state.index);
  }

  // ================= LISTEN =================
  Future<void> _onListen(
    BanglaSonkhaStartListening event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == SonkhaAnswerStatus.correct)
      return;

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) => _isListening = false,
      onStatus: (status) {},
    );

    if (!available) return;

    _isListening = true;
    if (state is BanglaSonkhaLoaded) {
      emit(
        (state as BanglaSonkhaLoaded).copyWith(
          isListening: true,
          answerStatus: SonkhaAnswerStatus.none,
        ),
      );
    }

    await _speech.listen(
      localeId: 'bn_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) {
        if (_hasSpoken) return;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _hasSpoken = true;
          final raw = result.recognizedWords.trim();
          // Convert digits to Bengali words so we always work with text
          final words = _digitToWord[raw] ?? raw;
          add(BanglaSonkhaSpeechDetected(words));
        }
      },
    );

    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (_hasSpoken || state.isValidating) return;

      await _speech.stop();
      _isListening = false;
      await _playNumberAudio(state.index);
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    BanglaSonkhaSpeechDetected event,
    Emitter<BanglaSonkhaState> emit,
  ) async {
    _listenTimeoutTimer?.cancel();
    await _speech.stop();
    await _audioPlayer.stop();
    _isListening = false;

    if (state is BanglaSonkhaLoaded) {
      emit(
        (state as BanglaSonkhaLoaded).copyWith(
          isListening: false,
          isValidating: true,
          recognizedText: event.text,
          answerStatus: SonkhaAnswerStatus.none,
        ),
      );
    }

    bool isCorrect = false;
    try {
      isCorrect = await _checkWithApi(event.text, state.currentNumber);
    } catch (e) {
      debugPrint("API Error: $e");
    }

    _isPlayingFeedbackAudio = true;

    if (state is BanglaSonkhaLoaded) {
      emit(
        (state as BanglaSonkhaLoaded).copyWith(
          isValidating: false,
          answerStatus: isCorrect
              ? SonkhaAnswerStatus.correct
              : SonkhaAnswerStatus.wrong,
        ),
      );
    }

    if (isCorrect) {
      await _playHurrayAudio();
      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('bangla_sonkha');
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is BanglaSonkhaLoaded) {
        emit(
          (state as BanglaSonkhaLoaded).copyWith(
            answerStatus: SonkhaAnswerStatus.none,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playNumberAudio(state.index);
    }
  }

  // ================= NORMALIZATION =================
  static const _digitToWord = {
    '১': 'এক', '২': 'দুই', '৩': 'তিন', '৪': 'চার', '৫': 'পাঁচ',
    '৬': 'ছয়', '৭': 'সাত', '৮': 'আট', '৯': 'নয়', '১০': 'দশ',
    '১১': 'এগারো', '১২': 'বারো', '১৩': 'তেরো', '১৪': 'চৌদ্দ', '১৫': 'পনেরো',
    '১৬': 'ষোলো', '১৭': 'সতেরো', '১৮': 'আঠারো', '১৯': 'উনিশ', '২০': 'কুড়ি',
    '২১': 'একুশ', '২২': 'বাইশ', '২৩': 'তেইশ', '২৪': 'চব্বিশ', '২৫': 'পঁচিশ',
    '২৬': 'ছাব্বিশ', '২৭': 'সাতাশ', '২৮': 'আটাশ', '২৯': 'উনত্রিশ', '৩০': 'ত্রিশ',
    '৩১': 'একত্রিশ', '৩২': 'বত্রিশ', '৩৩': 'তেত্রিশ', '৩৪': 'চৌত্রিশ', '৩৫': 'পঁয়ত্রিশ',
    '৩৬': 'ছত্রিশ', '৩৭': 'সাতত্রিশ', '৩৮': 'আটত্রিশ', '৩৯': 'উনচল্লিশ', '৪০': 'চল্লিশ',
    '৪১': 'একচল্লিশ', '৪২': 'বিয়াল্লিশ', '৪৩': 'তেতাল্লিশ', '৪৪': 'চুয়াল্লিশ', '৪৫': 'পঁয়তাল্লিশ',
    '৪৬': 'ছেচল্লিশ', '৪৭': 'সাতচল্লিশ', '৪৮': 'আটচল্লিশ', '৪৯': 'উনপঞ্চাশ', '৫০': 'পঞ্চাশ',
    '৫১': 'একান্ন', '৫২': 'বায়ান্ন', '৫৩': 'তিপান্ন', '৫৪': 'চুয়ান্ন', '৫৫': 'পঞ্চান্ন',
    '৫৬': 'ছাপান্ন', '৫৭': 'সাতান্ন', '৫৮': 'আটান্ন', '৫৯': 'উনষাট', '৬০': 'ষাট',
    '৬১': 'একষট্টি', '৬২': 'বাষট্টি', '৬৩': 'তেষট্টি', '৬৪': 'চৌষট্টি', '৬৫': 'পঁয়ষট্টি',
    '৬৬': 'ছেষট্টি', '৬৭': 'সাতষট্টি', '৬৮': 'আটষট্টি', '৬৯': 'উনসত্তর', '৭০': 'সত্তর',
    '৭১': 'একাত্তর', '৭২': 'বাহাত্তর', '৭৩': 'তিয়াত্তর', '৭৪': 'চুয়াত্তর', '৭৫': 'পঁচাত্তর',
    '৭৬': 'ছিয়াত্তর', '৭৭': 'সাতাত্তর', '৭৮': 'আটাত্তর', '৭৯': 'উনআশি', '৮০': 'আশি',
    '৮১': 'একাশি', '৮২': 'বিরাশি', '৮৩': 'তিরাশি', '৮৪': 'চুরাশি', '৮৫': 'পঁচাশি',
    '৮৬': 'ছিয়াশি', '৮৭': 'সাতাশি', '৮৮': 'আটাশি', '৮৯': 'উননব্বই', '৯০': 'নব্বই',
    '৯১': 'একানব্বই', '৯২': 'বিরানব্বই', '৯৩': 'তিরানব্বই', '৯৪': 'চুরানব্বই', '৯৫': 'পঁচানব্বই',
    '৯৬': 'ছিয়ানব্বই', '৯৭': 'সাতানব্বই', '৯৮': 'আটানব্বই', '৯৯': 'নিরানব্বই', '১০০': 'একশো',
  };

  // ================= API LOGIC =================
  Future<bool> _checkWithApi(String text, String number) async {
    final requestBody = {"text": text, "number": number};
    debugPrint("[BanglaSonkhaBloc] API Request: POST $_apiUrl");
    debugPrint("[BanglaSonkhaBloc] Request Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      debugPrint("[BanglaSonkhaBloc] Response Status: ${response.statusCode}");
      debugPrint("[BanglaSonkhaBloc] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isCorrect = data['isCorrect'] == true;
        final matchedBy = data['matchedBy'] ?? 'unknown';
        debugPrint(
          "[BanglaSonkhaBloc] isCorrect: $isCorrect (matchedBy: $matchedBy)",
        );
        return isCorrect;
      }
      return false;
    } catch (e) {
      debugPrint("[BanglaSonkhaBloc] API Exception: $e");
      return false;
    }
  }

  // ================= AUDIO HELPERS =================
  Future<void> _playNumberAudio(int index) async {
    if (state.isValidating) return;

    _hasSpoken = false;
    _isPlayingFeedbackAudio = false;
    final number = bengaliNumbers[index];

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/bengali_audio/$number.wav'));
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

  void _onStop(BanglaSonkhaStop event, Emitter<BanglaSonkhaState> emit) {
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
