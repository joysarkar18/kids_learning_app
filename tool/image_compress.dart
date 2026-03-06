import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:args/args.dart';
// Ensure your LoggerService path is correct
import 'package:kids_learning/services/logger_service.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'path',
      abbr: 'p',
      help: 'Path to folder or image file',
      mandatory: true,
    )
    ..addOption('quality', abbr: 'q', defaultsTo: '80', help: 'Quality (1-100)')
    ..addOption('width', abbr: 'w', help: 'Target width')
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format (png, jpg, webp, svg)',
    )
    ..addFlag(
      'remove-bg',
      abbr: 'b',
      defaultsTo: false,
      help: 'Remove background',
    )
    ..addFlag(
      'replace',
      abbr: 'r',
      defaultsTo: false,
      help: 'Overwrite original file',
    );

  try {
    final argResults = parser.parse(arguments);
    final String targetPath = argResults['path'];
    final bool replace = argResults['replace'];
    final bool removeBg = argResults['remove-bg'];
    final String? format = argResults['format']?.toLowerCase();

    // --- Pre-flight Dependency Checks ---
    if (removeBg && (await Process.run('which', ['rembg'])).exitCode != 0) {
      LoggerService.logInfo(
        '❌ Error: "rembg" not found. Run: pip install rembg',
      );
      return;
    }
    if (format == 'svg' &&
        (await Process.run('which', ['potrace'])).exitCode != 0) {
      LoggerService.logInfo(
        '❌ Error: "potrace" not found. Run: brew install potrace',
      );
      return;
    }

    final entity = FileSystemEntity.typeSync(targetPath);
    if (entity == FileSystemEntityType.notFound) {
      LoggerService.logInfo(
        '❌ Path not found: ${Directory(targetPath).absolute.path}',
      );
      return;
    }

    if (entity == FileSystemEntityType.file) {
      await processFile(File(targetPath), argResults, replace);
    } else {
      final dir = Directory(targetPath);
      final files = dir.listSync().whereType<File>().toList();
      for (var file in files) {
        await processFile(file, argResults, replace);
      }
    }
  } catch (e) {
    LoggerService.logInfo('Error: $e');
  }
}

Future<void> processFile(File file, ArgResults args, bool replace) async {
  final originalExt = p.extension(file.path).toLowerCase();
  if (!['.jpg', '.jpeg', '.png', '.webp'].contains(originalExt)) return;

  final quality = int.parse(args['quality']);
  final int? targetWidth = args['width'] != null
      ? int.parse(args['width'])
      : null;
  final String? targetFormat = args['format']?.toLowerCase();
  final bool removeBg = args['remove-bg'];

  File currentFile = file;
  final dir = p.dirname(file.path);
  final baseName = p.basenameWithoutExtension(file.path);

  LoggerService.logInfo('\nProcessing: ${p.basename(file.path)}');

  // 1. Background Removal
  if (removeBg) {
    final bgRemovedPath = p.join(dir, '${baseName}_temp_bg.png');
    await Process.run('rembg', ['i', currentFile.path, bgRemovedPath]);
    currentFile = File(bgRemovedPath);
  }

  // 2. Decode & Resize
  final bytes = await currentFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return;

  if (targetWidth != null && image.width > targetWidth) {
    image = img.copyResize(image, width: targetWidth);
  }

  // 3. Determine Final Path
  String finalExt = targetFormat != null ? '.$targetFormat' : originalExt;
  if (removeBg && targetFormat == null) finalExt = '.png';

  // If replace is true, use original name; otherwise use suffix
  final String outputName = replace
      ? '$baseName$finalExt'
      : '${baseName}_processed$finalExt';
  final finalPath = p.join(dir, outputName);

  // 4. Save
  if (finalExt == '.svg') {
    final bmpPath = p.join(dir, '${baseName}_temp.bmp');
    await File(bmpPath).writeAsBytes(img.encodeBmp(image));
    await Process.run('potrace', ['-s', '-o', finalPath, bmpPath]);
    if (File(bmpPath).existsSync()) File(bmpPath).deleteSync();
  } else {
    List<int> out;
    if (finalExt == '.png') {
      out = img.encodePng(image, level: (quality / 10).round().clamp(0, 9));
    } else {
      out = img.encodeJpg(image, quality: quality);
    }
    await File(finalPath).writeAsBytes(out);
  }

  // Cleanup temp background file if it exists
  if (removeBg && currentFile.path.contains('_temp_bg')) {
    currentFile.deleteSync();
  }

  LoggerService.logInfo('   ✅ Done: ${p.basename(finalPath)}');
}
