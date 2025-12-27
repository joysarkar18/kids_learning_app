import 'dart:io';

void main() {
  const audioRoot = 'assets/audios';

  final localizedKeys = <String>{};
  final uiKeys = <String>{};

  final rootDir = Directory(audioRoot);

  if (!rootDir.existsSync()) {
    // ignore: avoid_print
    print('❌ assets/audios not found');
    exit(1);
  }

  for (final entity in rootDir.listSync()) {
    if (entity is! Directory) continue;

    final folderName = entity.path.split('/').last;

    // UI AUDIO (NON-LOCALIZED)
    if (folderName == 'ui') {
      for (final file in entity.listSync()) {
        if (file is File) {
          uiKeys.add(_fileName(file));
        }
      }
      continue;
    }

    // LOCALIZED AUDIO
    for (final file in entity.listSync()) {
      if (file is File) {
        localizedKeys.add(_fileName(file));
      }
    }
  }

  _generateAudioKey(localizedKeys);
  _generateUiAudioKey(uiKeys);
  _generateMappers();

  // ignore: avoid_print
  print('✅ Audio assets generated successfully');
}

String _fileName(File file) => file.uri.pathSegments.last.split('.').first;

// --------------------------------------------------------

void _generateAudioKey(Set<String> keys) {
  final buffer = StringBuffer('enum AudioKey {\n');
  for (final k in keys) {
    buffer.writeln('  $k,');
  }
  buffer.writeln('}');

  _write('lib/audio/audio_key.dart', buffer.toString());
}

void _generateUiAudioKey(Set<String> keys) {
  final buffer = StringBuffer('enum UiAudioKey {\n');
  for (final k in keys) {
    buffer.writeln('  $k,');
  }
  buffer.writeln('}');

  _write('lib/audio/ui_audio_key.dart', buffer.toString());
}

void _generateMappers() {
  _write('lib/audio/audio_mapper.dart', '''
import 'audio_key.dart';

class AudioMapper {
  static String localized({
    required String languageCode,
    required AudioKey key,
  }) {
    return 'audios/\$languageCode/\${key.name}.wav';
  }
}
''');

  _write('lib/audio/ui_audio_mapper.dart', '''
import 'ui_audio_key.dart';

class UiAudioMapper {
  static String path(UiAudioKey key) {
    return 'audios/ui/\${key.name}.wav';
  }
}
''');
}

void _write(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
