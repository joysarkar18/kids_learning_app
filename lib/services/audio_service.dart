import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // 1. Singleton pattern setup
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // 2. The player instance
  final AudioPlayer _player = AudioPlayer();

  // 3. Status tracker
  bool _isPlaying = false;

  Future<void> init() async {
    if (_isPlaying) return;

    final AudioContext audioContext = AudioContext(
      iOS: AudioContextIOS(
        // Category 'playback' is correct for music
        category: AVAudioSessionCategory.playback,
        options: {
          // REMOVED: AVAudioSessionOptions.defaultToSpeaker (Not allowed with playback)

          // KEEP: This allows your background music to mix with the card sound
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    // Apply configuration
    await AudioPlayer.global.setAudioContext(audioContext);

    // Standard setup
    await _player.setVolume(0.1);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audios/ui/bg_audio2.mp3'));

    _isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}
