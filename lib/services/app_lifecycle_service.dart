import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:kids_learning/services/audio_service.dart';

/// Service to manage app lifecycle events and coordinate audio/STT cleanup
class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final List<AudioPlayer> _registeredPlayers = [];
  final List<stt.SpeechToText> _registeredSpeechRecognizers = [];
  final List<AudioPlayer> _pausedPlayers = [];
  bool _isInBackground = false;

  /// Register an AudioPlayer instance for lifecycle management
  void registerAudioPlayer(AudioPlayer player) {
    if (!_registeredPlayers.contains(player)) {
      _registeredPlayers.add(player);
    }
  }

  /// Unregister an AudioPlayer instance
  void unregisterAudioPlayer(AudioPlayer player) {
    _registeredPlayers.remove(player);
  }

  /// Register a SpeechToText instance for lifecycle management
  void registerSpeechRecognizer(stt.SpeechToText speech) {
    if (!_registeredSpeechRecognizers.contains(speech)) {
      _registeredSpeechRecognizers.add(speech);
    }
  }

  /// Unregister a SpeechToText instance
  void unregisterSpeechRecognizer(stt.SpeechToText speech) {
    _registeredSpeechRecognizers.remove(speech);
  }

  /// Called when app enters background - pauses audio and stops STT
  Future<void> onEnterBackground() async {
    _isInBackground = true;
    _pausedPlayers.clear();
    debugPrint('[AppLifecycleService] App entered background - pausing audio and stopping STT');

    // Let AudioService handle its own background music pause/resume
    await AudioService().onEnterBackground();

    // Pause all other registered audio players (e.g., narration)
    for (final player in _registeredPlayers) {
      try {
        if (player.state == PlayerState.playing) {
          await player.pause();
          _pausedPlayers.add(player);
        }
      } catch (e) {
        debugPrint('[AppLifecycleService] Error pausing audio player: $e');
      }
    }

    // Stop all speech recognizers
    for (final speech in _registeredSpeechRecognizers) {
      try {
        await speech.stop();
      } catch (e) {
        debugPrint('[AppLifecycleService] Error stopping speech recognizer: $e');
      }
    }
  }

  /// Called when app enters foreground - resumes audio if appropriate
  Future<void> onEnterForeground() async {
    _isInBackground = false;
    debugPrint('[AppLifecycleService] App entered foreground');

    // Let AudioService handle its own background music resume
    await AudioService().onEnterForeground();

    // Resume other paused players (e.g., narration)
    for (final player in _pausedPlayers) {
      try {
        await player.resume();
      } catch (e) {
        debugPrint('[AppLifecycleService] Error resuming audio player: $e');
      }
    }
    _pausedPlayers.clear();
  }

  /// Check if app is currently in background
  bool get isInBackground => _isInBackground;

  /// Stop a specific audio player (convenience method)
  Future<void> stopAudioPlayer(AudioPlayer player) async {
    try {
      await player.stop();
    } catch (e) {
      debugPrint('[AppLifecycleService] Error stopping audio player: $e');
    }
  }

  /// Stop a specific speech recognizer (convenience method)
  Future<void> stopSpeechRecognizer(stt.SpeechToText speech) async {
    try {
      await speech.stop();
    } catch (e) {
      debugPrint('[AppLifecycleService] Error stopping speech recognizer: $e');
    }
  }
}
