import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
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
    _isPlaying = false;
  }
}
