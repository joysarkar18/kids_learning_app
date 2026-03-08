import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _narrationPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> init() async {
    if (_isPlaying) return;

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
    await _player.play(AssetSource('audios/ui/bg_audio2.mp3'));

    _isPlaying = true;
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
