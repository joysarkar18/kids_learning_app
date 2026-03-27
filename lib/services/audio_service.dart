import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_learning/services/app_lifecycle_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _narrationPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Whether the home screen is active and music should be playing
  bool _shouldPlay = false;

  /// List of background audio files to choose from randomly
  static const List<String> _bgAudioFiles = [
    'audios/ui/bg_audio.mp3',
    'audios/ui/bg_audio2.mp3',
    'audios/ui/bg_audio3.mp3',
    'audios/ui/bg_audio4.mp3',
  ];

  /// Initialize audio service without starting playback
  Future<void> init() async {
    if (_isPlaying) return;

    // Only register narration player with lifecycle service
    // Background music player is managed by AudioService itself via
    // onEnterBackground/onEnterForeground
    AppLifecycleService().registerAudioPlayer(_narrationPlayer);

    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    await AudioPlayer.global.setAudioContext(audioContext);
    await _player.setVolume(0.05);
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  /// Start playing background music (call this on home page)
  Future<void> playBackgroundMusic() async {
    _shouldPlay = true;
    if (_isPlaying) return;

    // Randomly select a background audio file
    final random = Random();
    final selectedAudio = _bgAudioFiles[random.nextInt(_bgAudioFiles.length)];

    try {
      await _player.play(AssetSource(selectedAudio));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  /// Stop playing background music (call this when leaving home page)
  Future<void> stopBackgroundMusic() async {
    _shouldPlay = false;
    if (!_isPlaying) return;

    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  /// Whether background music should be playing (home screen is active)
  bool get shouldPlay => _shouldPlay;

  /// Pause background music when app goes to background
  Future<void> onEnterBackground() async {
    if (_isPlaying && _player.state == PlayerState.playing) {
      try {
        await _player.pause();
      } catch (e) {
        debugPrint('Error pausing background music: $e');
      }
    }
  }

  /// Resume background music when app comes back to foreground
  Future<void> onEnterForeground() async {
    if (_shouldPlay && _isPlaying) {
      try {
        await _player.resume();
      } catch (e) {
        debugPrint('Error resuming background music: $e');
      }
    }
  }

  /// Play a specific audio file (for narration)
  Future<void> play(String assetPath) async {
    await _narrationPlayer.stop();
    await _narrationPlayer.setVolume(1.0);
    await _narrationPlayer.play(AssetSource(assetPath));
  }

  /// Play audio from URL or path
  Future<void> playFromPath(String path) async {
    await _narrationPlayer.stop();
    await _narrationPlayer.setVolume(1.0);
    await _narrationPlayer.play(AssetSource(path));
  }

  Future<void> pause() async {
    if (_isPlaying) {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    if (_isPlaying) {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _narrationPlayer.stop();
    _isPlaying = false;
  }

  /// Stop only narration audio
  Future<void> stopNarration() async {
    await _narrationPlayer.stop();
  }

  /// Check if narration is playing
  bool get isNarrationPlaying => _narrationPlayer.state == PlayerState.playing;

  /// Get narration player state
  AudioPlayer get narrationPlayer => _narrationPlayer;

  /// Set background music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
  }

  /// Set narration volume (0.0 to 1.0)
  Future<void> setNarrationVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _narrationPlayer.setVolume(clampedVolume);
  }

  /// Get current music volume
  double get musicVolume => _player.volume;

  /// Get current narration volume
  double get narrationVolume => _narrationPlayer.volume;
}
