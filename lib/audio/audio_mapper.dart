import 'audio_key.dart';

class AudioMapper {
  static String localized({
    required String languageCode,
    required AudioKey key,
  }) {
    return 'audios/$languageCode/${key.name}.wav';
  }
}
