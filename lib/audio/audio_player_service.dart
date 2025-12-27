import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/audio/ui_audio_mapper.dart';

import 'audio_key.dart';
import 'audio_mapper.dart';

class AudioPlayerService {
  static final instance = AudioPlayerService._();

  AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  Future<void> playLocalized({
    required BuildContext context,
    required AudioKey key,
  }) async {
    final lang = Localizations.localeOf(context).languageCode;

    try {
      await _player.stop();
      await _player.play(
        AssetSource(AudioMapper.localized(languageCode: lang, key: key)),
      );
    } catch (_) {
      await _player.play(
        AssetSource(AudioMapper.localized(languageCode: 'en', key: key)),
      );
    }
  }

  Future<void> playUi({required UiAudioKey key}) async {
    await _player.stop();
    await _player.play(AssetSource(UiAudioMapper.path(key)));
  }
}
