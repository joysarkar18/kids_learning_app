import 'ui_audio_key.dart';

class UiAudioMapper {
  static String path(UiAudioKey key) {
    return 'audios/ui/${key.name}.wav';
  }
}
