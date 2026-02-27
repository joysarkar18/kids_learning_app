import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

import 'english_sonkha_event.dart';
import 'english_sonkha_state.dart';

class EnglishSonkhaBloc extends Bloc<EnglishSonkhaEvent, EnglishSonkhaState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final String _apiUrl =
      "https://us-central1-rumora-c0d7b.cloudfunctions.net/checkEnglishNumber";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;

  bool _isPlayingFeedbackAudio = false;

  // Debounce timer for partial speech results
  Timer? _partialResultTimer;
  String _lastPartialResult = '';

  EnglishSonkhaBloc() : super(const EnglishSonkhaInitial()) {
    on<EnglishSonkhaInit>(_onInit);
    on<EnglishSonkhaNext>(_onNext);
    on<EnglishSonkhaPrevious>(_onPrevious);
    on<EnglishSonkhaRetry>(_onRetry);
    on<EnglishSonkhaStartListening>(_onListen);
    on<EnglishSonkhaSpeechDetected>(_onSpeechDetected);
    on<EnglishSonkhaStop>(_onStop);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == EnglishSonkhaAnswerStatus.correct)
        return;

      add(EnglishSonkhaStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(
    EnglishSonkhaInit event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    emit(const EnglishSonkhaLoaded(index: 0));
    await _playNumberAudio(0);
  }

  // ================= NAV =================
  Future<void> _onNext(
    EnglishSonkhaNext event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    _cleanupListening();
    final next = (state.index + 1) % englishNumbers.length;
    emit(
      EnglishSonkhaLoaded(
        index: next,
        answerStatus: EnglishSonkhaAnswerStatus.none,
      ),
    );
    await _playNumberAudio(next);
  }

  Future<void> _onPrevious(
    EnglishSonkhaPrevious event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    _cleanupListening();
    final prev =
        (state.index - 1 + englishNumbers.length) % englishNumbers.length;
    emit(
      EnglishSonkhaLoaded(
        index: prev,
        answerStatus: EnglishSonkhaAnswerStatus.none,
      ),
    );
    await _playNumberAudio(prev);
  }

  Future<void> _onRetry(
    EnglishSonkhaRetry event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    _cleanupListening();
    emit(
      EnglishSonkhaLoaded(
        index: state.index,
        answerStatus: EnglishSonkhaAnswerStatus.none,
      ),
    );
    await _playNumberAudio(state.index);
  }

  // ================= LISTEN =================
  Future<void> _onListen(
    EnglishSonkhaStartListening event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    // 1. Guard against starting mic during validation or success state
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == EnglishSonkhaAnswerStatus.correct)
      return;

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (error) {
        debugPrint("[EnglishSonkhaBloc] Speech error: ${error.errorMsg}");
        _isListening = false;
      },
      onStatus: (status) {
        debugPrint("[EnglishSonkhaBloc] Speech status: $status");
      },
    );

    debugPrint("[EnglishSonkhaBloc] Speech available: $available");
    if (!available) return;

    _isListening = true;
    if (state is EnglishSonkhaLoaded) {
      emit(
        (state as EnglishSonkhaLoaded).copyWith(
          isListening: true,
          answerStatus: EnglishSonkhaAnswerStatus.none,
        ),
      );
    }

    // 2. Start Listening with partialResults to catch short words like "one"
    debugPrint("[EnglishSonkhaBloc] Starting speech listen with locale: bn_IN");
    await _speech.listen(
      localeId: 'bn_IN',

      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        debugPrint(
          "[EnglishSonkhaBloc] onResult: final=${result.finalResult}, words='${result.recognizedWords}'",
        );
        if (_hasSpoken) return;

        final raw = result.recognizedWords.trim();
        if (raw.isEmpty) return;

        // Convert digits to words (e.g. "1" → "one") so we always work with text
        final words = _digitToWord[raw] ?? raw;

        if (result.finalResult) {
          // Final result — use immediately
          _partialResultTimer?.cancel();
          _hasSpoken = true;
          add(EnglishSonkhaSpeechDetected(words));
        } else {
          // Partial result — debounce 1.5s then use it
          // This catches short words like "one" that may never get a finalResult
          _lastPartialResult = words;
          _partialResultTimer?.cancel();

          // Reset the 6s timeout so it doesn't race with the debounce
          _listenTimeoutTimer?.cancel();
          _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
            if (_hasSpoken || state.isValidating) return;
            debugPrint("[EnglishSonkhaBloc] Listen timeout - replaying audio");
            _partialResultTimer?.cancel();
            await _speech.stop();
            _isListening = false;
            await _playNumberAudio(state.index);
          });

          _partialResultTimer = Timer(const Duration(milliseconds: 1500), () {
            if (_hasSpoken) return;
            debugPrint(
              "[EnglishSonkhaBloc] Using partial result: '$_lastPartialResult'",
            );
            _hasSpoken = true;
            add(EnglishSonkhaSpeechDetected(_lastPartialResult));
          });
        }
      },
    );

    // 3. Start Timeout Timer (6 Seconds)
    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (_hasSpoken || state.isValidating) return;

      debugPrint("[EnglishSonkhaBloc] Listen timeout - replaying audio");
      _partialResultTimer?.cancel();
      await _speech.stop();
      _isListening = false;
      await _playNumberAudio(state.index);
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    EnglishSonkhaSpeechDetected event,
    Emitter<EnglishSonkhaState> emit,
  ) async {
    _listenTimeoutTimer?.cancel();
    _partialResultTimer?.cancel();
    await _speech.stop();
    await _audioPlayer.stop();
    _isListening = false;

    if (state is EnglishSonkhaLoaded) {
      emit(
        (state as EnglishSonkhaLoaded).copyWith(
          isListening: false,
          isValidating: true,
          recognizedText: event.text,
          answerStatus: EnglishSonkhaAnswerStatus.none,
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

    if (state is EnglishSonkhaLoaded) {
      emit(
        (state as EnglishSonkhaLoaded).copyWith(
          isValidating: false,
          answerStatus: isCorrect
              ? EnglishSonkhaAnswerStatus.correct
              : EnglishSonkhaAnswerStatus.wrong,
        ),
      );
    }

    if (isCorrect) {
      await _playHurrayAudio();
      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('english_sonkha');
    } else {
      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is EnglishSonkhaLoaded) {
        emit(
          (state as EnglishSonkhaLoaded).copyWith(
            answerStatus: EnglishSonkhaAnswerStatus.none,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playNumberAudio(state.index);
    }
  }

  // ================= NORMALIZATION =================
  static const _digitToWord = {
    '1': 'one',
    '2': 'two',
    '3': 'three',
    '4': 'four',
    '5': 'five',
    '6': 'six',
    '7': 'seven',
    '8': 'eight',
    '9': 'nine',
    '10': 'ten',
    '11': 'eleven',
    '12': 'twelve',
    '13': 'thirteen',
    '14': 'fourteen',
    '15': 'fifteen',
    '16': 'sixteen',
    '17': 'seventeen',
    '18': 'eighteen',
    '19': 'nineteen',
    '20': 'twenty',
    '21': 'twenty one',
    '22': 'twenty two',
    '23': 'twenty three',
    '24': 'twenty four',
    '25': 'twenty five',
    '26': 'twenty six',
    '27': 'twenty seven',
    '28': 'twenty eight',
    '29': 'twenty nine',
    '30': 'thirty',
    '31': 'thirty one',
    '32': 'thirty two',
    '33': 'thirty three',
    '34': 'thirty four',
    '35': 'thirty five',
    '36': 'thirty six',
    '37': 'thirty seven',
    '38': 'thirty eight',
    '39': 'thirty nine',
    '40': 'forty',
    '41': 'forty one',
    '42': 'forty two',
    '43': 'forty three',
    '44': 'forty four',
    '45': 'forty five',
    '46': 'forty six',
    '47': 'forty seven',
    '48': 'forty eight',
    '49': 'forty nine',
    '50': 'fifty',
    '51': 'fifty one',
    '52': 'fifty two',
    '53': 'fifty three',
    '54': 'fifty four',
    '55': 'fifty five',
    '56': 'fifty six',
    '57': 'fifty seven',
    '58': 'fifty eight',
    '59': 'fifty nine',
    '60': 'sixty',
    '61': 'sixty one',
    '62': 'sixty two',
    '63': 'sixty three',
    '64': 'sixty four',
    '65': 'sixty five',
    '66': 'sixty six',
    '67': 'sixty seven',
    '68': 'sixty eight',
    '69': 'sixty nine',
    '70': 'seventy',
    '71': 'seventy one',
    '72': 'seventy two',
    '73': 'seventy three',
    '74': 'seventy four',
    '75': 'seventy five',
    '76': 'seventy six',
    '77': 'seventy seven',
    '78': 'seventy eight',
    '79': 'seventy nine',
    '80': 'eighty',
    '81': 'eighty one',
    '82': 'eighty two',
    '83': 'eighty three',
    '84': 'eighty four',
    '85': 'eighty five',
    '86': 'eighty six',
    '87': 'eighty seven',
    '88': 'eighty eight',
    '89': 'eighty nine',
    '90': 'ninety',
    '91': 'ninety one',
    '92': 'ninety two',
    '93': 'ninety three',
    '94': 'ninety four',
    '95': 'ninety five',
    '96': 'ninety six',
    '97': 'ninety seven',
    '98': 'ninety eight',
    '99': 'ninety nine',
    '100': 'one hundred',
  };

  /// Try local match first: if STT text matches the expected number
  /// (as digit or word form), return true immediately without calling the API.
  /// Returns null if inconclusive (needs API).
  bool? _localMatch(String text, String number) {
    final normalized = text.trim().toLowerCase();
    final expectedWord = _digitToWord[number]?.toLowerCase();

    // 1. Exact digit match: STT returned "1" and expected is "1"
    if (normalized == number) {
      debugPrint(
        "[EnglishSonkhaBloc] Local match: digit exact '$normalized' == '$number'",
      );
      return true;
    }

    // 2. Exact word match: STT returned "one" and expected word is "one"
    if (expectedWord != null && normalized == expectedWord) {
      debugPrint(
        "[EnglishSonkhaBloc] Local match: word exact '$normalized' == '$expectedWord'",
      );
      return true;
    }

    // 3. Text contains the expected word: STT returned "say one" and expected is "one"
    if (expectedWord != null && normalized.contains(expectedWord)) {
      debugPrint(
        "[EnglishSonkhaBloc] Local match: contains '$expectedWord' in '$normalized'",
      );
      return true;
    }

    // 4. STT returned a different digit — clearly wrong
    final digitRegex = RegExp(r'^\d+$');
    if (digitRegex.hasMatch(normalized) && normalized != number) {
      debugPrint(
        "[EnglishSonkhaBloc] Local match: wrong digit '$normalized' != '$number'",
      );
      return false;
    }

    // Inconclusive — needs API
    return null;
  }

  // ================= API LOGIC =================
  Future<bool> _checkWithApi(String text, String number) async {
    // Step 1: Try local matching (no API cost)
    final localResult = _localMatch(text, number);
    if (localResult != null) {
      debugPrint("[EnglishSonkhaBloc] Resolved locally: $localResult");
      return localResult;
    }

    // Step 2: Local match inconclusive — call API
    final normalizedText = _digitToWord[text.trim()] ?? text.trim();
    final requestBody = {"text": normalizedText, "number": number};
    debugPrint("[EnglishSonkhaBloc] API Request: POST $_apiUrl");
    debugPrint("[EnglishSonkhaBloc] Request Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      debugPrint("[EnglishSonkhaBloc] Response Status: ${response.statusCode}");
      debugPrint("[EnglishSonkhaBloc] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isCorrect = data['isCorrect'] == true;
        final matchedBy = data['matchedBy'] ?? 'unknown';
        debugPrint(
          "[EnglishSonkhaBloc] isCorrect: $isCorrect (matchedBy: $matchedBy)",
        );
        return isCorrect;
      }
      return false;
    } catch (e) {
      debugPrint("[EnglishSonkhaBloc] API Exception: $e");
      return false;
    }
  }

  // ================= AUDIO HELPERS =================
  Future<void> _playNumberAudio(int index) async {
    if (state.isValidating) return;

    _hasSpoken = false;
    _isPlayingFeedbackAudio = false;
    final number = englishNumbers[index];

    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/english_audio/$number.wav'));
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
    _partialResultTimer?.cancel();
    _lastPartialResult = '';
    _speech.stop();
    _hasSpoken = false;
    _isListening = false;
    _isPlayingFeedbackAudio = false;
  }

  void _onStop(EnglishSonkhaStop event, Emitter<EnglishSonkhaState> emit) {
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
