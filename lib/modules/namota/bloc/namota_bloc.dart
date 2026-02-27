import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

import 'namota_event.dart';
import 'namota_state.dart';

class NamotaBloc extends Bloc<NamotaEvent, NamotaState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final String _apiUrl =
      "https://us-central1-rumora-c0d7b.cloudfunctions.net/checkNamotaText";

  Timer? _listenTimeoutTimer;
  bool _hasSpoken = false;
  bool _isListening = false;
  bool _isPlayingFeedbackAudio = false;
  bool _isPlayingAll = false;
  int _playAllIndex = 0;

  NamotaBloc() : super(const NamotaInitial()) {
    on<NamotaInit>(_onInit);
    on<NamotaStartListening>(_onListen);
    on<NamotaSpeechDetected>(_onSpeechDetected);
    on<NamotaRetry>(_onRetry);
    on<NamotaPlayAll>(_onPlayAll);
    on<NamotaStop>(_onStop);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_isPlayingAll) {
        _playAllIndex++;
        if (_playAllIndex < 10) {
          _playRowAudio(state.tableNumber, _playAllIndex);
        } else {
          _isPlayingAll = false;
          if (state is NamotaLoaded) {
            // Can't emit from listener directly, use add event pattern
            // After play-all finishes, start listening for current row
            add(NamotaRetry());
          }
        }
        return;
      }

      if (state.isValidating ||
          _isPlayingFeedbackAudio ||
          state.answerStatus == NamotaAnswerStatus.correct)
        return;

      add(NamotaStartListening());
    });
  }

  // ================= INIT =================
  Future<void> _onInit(NamotaInit event, Emitter<NamotaState> emit) async {
    debugPrint("[NamotaBloc] INIT: tableNumber=${event.tableNumber}");
    emit(NamotaLoaded(tableNumber: event.tableNumber, currentRowIndex: 0));
    await _playRowAudio(event.tableNumber, 0);
  }

  // ================= RETRY =================
  Future<void> _onRetry(NamotaRetry event, Emitter<NamotaState> emit) async {
    debugPrint("[NamotaBloc] RETRY: currentRow=${state.currentRowIndex}, table=${state.tableNumber}");
    _cleanupListening();
    _isPlayingAll = false;
    emit(
      state.copyWith(
        answerStatus: NamotaAnswerStatus.none,
        isPlayingAll: false,
      ),
    );
    await _playRowAudio(state.tableNumber, state.currentRowIndex);
  }

  // ================= PLAY ALL =================
  Future<void> _onPlayAll(
    NamotaPlayAll event,
    Emitter<NamotaState> emit,
  ) async {
    debugPrint("[NamotaBloc] PLAY ALL: table=${state.tableNumber}");
    _cleanupListening();
    _isPlayingAll = true;
    _playAllIndex = 0;
    emit(
      state.copyWith(isPlayingAll: true, answerStatus: NamotaAnswerStatus.none),
    );
    await _playRowAudio(state.tableNumber, 0);
  }

  // ================= LISTEN =================
  Future<void> _onListen(
    NamotaStartListening event,
    Emitter<NamotaState> emit,
  ) async {
    debugPrint("[NamotaBloc] START LISTENING: row=${state.currentRowIndex}, "
        "isValidating=${state.isValidating}, isPlayingFeedback=$_isPlayingFeedbackAudio, "
        "isPlayingAll=$_isPlayingAll");
    if (state.isValidating ||
        _isPlayingFeedbackAudio ||
        state.answerStatus == NamotaAnswerStatus.correct ||
        _isPlayingAll) {
      debugPrint("[NamotaBloc] LISTEN SKIPPED: guard condition met");
      return;
    }

    _cleanupListening();

    final available = await _speech.initialize(
      onError: (_) => _isListening = false,
      onStatus: (status) {},
    );

    if (!available) {
      debugPrint("[NamotaBloc] LISTEN: speech not available");
      return;
    }

    _isListening = true;
    if (state is NamotaLoaded) {
      emit(
        (state as NamotaLoaded).copyWith(
          isListening: true,
          answerStatus: NamotaAnswerStatus.none,
        ),
      );
    }

    await _speech.listen(
      localeId: 'bn_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      onResult: (result) {
        debugPrint("[NamotaBloc] SPEECH RESULT: final=${result.finalResult}, "
            "words='${result.recognizedWords}', confidence=${result.confidence}");
        if (_hasSpoken) return;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _hasSpoken = true;
          debugPrint("[NamotaBloc] SPEECH ACCEPTED: '${result.recognizedWords}'");
          add(NamotaSpeechDetected(result.recognizedWords));
        }
      },
    );

    _listenTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      debugPrint("[NamotaBloc] LISTEN TIMEOUT: hasSpoken=$_hasSpoken, isValidating=${state.isValidating}");
      if (_hasSpoken || state.isValidating) return;

      await _speech.stop();
      _isListening = false;
      debugPrint("[NamotaBloc] LISTEN TIMEOUT: replaying row audio");
      await _playRowAudio(state.tableNumber, state.currentRowIndex);
    });
  }

  // ================= SPEECH DETECTED =================
  Future<void> _onSpeechDetected(
    NamotaSpeechDetected event,
    Emitter<NamotaState> emit,
  ) async {
    final tableKey = '${state.tableNumber}x${state.currentMultiplier}';
    debugPrint("[NamotaBloc] SPEECH DETECTED: text='${event.text}', "
        "tableKey=$tableKey, expectedResult=${state.currentResult} (${state.currentResultBengali}), "
        "row=${state.currentRowIndex}");
    _listenTimeoutTimer?.cancel();
    await _speech.stop();
    await _audioPlayer.stop();
    _isListening = false;

    if (state is NamotaLoaded) {
      emit(
        (state as NamotaLoaded).copyWith(
          isListening: false,
          isValidating: true,
          recognizedText: event.text,
          answerStatus: NamotaAnswerStatus.none,
        ),
      );
    }

    bool isCorrect = false;
    try {
      isCorrect = await _checkWithApi(event.text, tableKey);
    } catch (e) {
      debugPrint("[NamotaBloc] API Error: $e");
    }

    debugPrint("[NamotaBloc] VALIDATION RESULT: isCorrect=$isCorrect, "
        "text='${event.text}', expected='${state.currentResultBengali}'");

    _isPlayingFeedbackAudio = true;

    if (isCorrect) {
      final newCompleted = {...state.completedRows, state.currentRowIndex};

      if (state is NamotaLoaded) {
        emit(
          (state as NamotaLoaded).copyWith(
            isValidating: false,
            answerStatus: NamotaAnswerStatus.correct,
            completedRows: newCompleted,
          ),
        );
      }

      await _playHurrayAudio();
      await Future.delayed(const Duration(milliseconds: 500));

      _isPlayingFeedbackAudio = false;
      DailyChallengeService.instance.reportProgress('namota');

      // Check if all rows are complete
      if (newCompleted.length >= 10) {
        debugPrint("[NamotaBloc] ALL ROWS COMPLETE! table=${state.tableNumber}");
        return;
      }

      // Advance to next incomplete row
      int nextRow = (state.currentRowIndex + 1) % 10;
      while (newCompleted.contains(nextRow)) {
        nextRow = (nextRow + 1) % 10;
      }

      if (state is NamotaLoaded) {
        emit(
          (state as NamotaLoaded).copyWith(
            currentRowIndex: nextRow,
            answerStatus: NamotaAnswerStatus.none,
          ),
        );
      }

      debugPrint("[NamotaBloc] ADVANCING to nextRow=$nextRow, completed=$newCompleted");
      await _playRowAudio(state.tableNumber, nextRow);
    } else {
      if (state is NamotaLoaded) {
        emit(
          (state as NamotaLoaded).copyWith(
            isValidating: false,
            answerStatus: NamotaAnswerStatus.wrong,
          ),
        );
      }

      await _playWrongAudio();
      await Future.delayed(const Duration(seconds: 1));

      if (state is NamotaLoaded) {
        emit(
          (state as NamotaLoaded).copyWith(
            answerStatus: NamotaAnswerStatus.none,
          ),
        );
      }

      _isPlayingFeedbackAudio = false;
      await _playRowAudio(state.tableNumber, state.currentRowIndex);
    }
  }

  // ================= API LOGIC =================
  Future<bool> _checkWithApi(String text, String tableKey) async {
    final requestBody = {"text": text, "tableKey": tableKey};
    debugPrint("[NamotaBloc] API Request: POST $_apiUrl");
    debugPrint("[NamotaBloc] Request Body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      debugPrint("[NamotaBloc] Response Status: ${response.statusCode}");
      debugPrint("[NamotaBloc] Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("[NamotaBloc] API Result: isCorrect=${data['isCorrect']}, matchedBy=${data['matchedBy']}");
        return data['isCorrect'] == true;
      }
      debugPrint("[NamotaBloc] API Error: non-200 status");
      return false;
    } catch (e) {
      debugPrint("[NamotaBloc] API Exception: $e");
      return false;
    }
  }

  // ================= AUDIO HELPERS =================
  Future<void> _playRowAudio(int tableNumber, int rowIndex) async {
    if (state.isValidating) return;

    _hasSpoken = false;
    if (!_isPlayingAll) {
      _isPlayingFeedbackAudio = false;
    }
    final multiplier = rowIndex + 1;
    final audioFile = '${tableNumber}x$multiplier';

    debugPrint("[NamotaBloc] PLAY AUDIO: $audioFile.wav (table=$tableNumber, row=$rowIndex)");
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audios/bengali_audio/$audioFile.wav'));
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

  void _onStop(NamotaStop event, Emitter<NamotaState> emit) {
    debugPrint("[NamotaBloc] STOP");
    _cleanupListening();
    _isPlayingAll = false;
    _audioPlayer.stop();
  }

  @override
  Future<void> close() {
    _cleanupListening();
    _audioPlayer.dispose();
    return super.close();
  }
}
