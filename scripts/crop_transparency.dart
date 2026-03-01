import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconsDir = Directory('assets/icons');
  if (!iconsDir.existsSync()) {
    print('Directory assets/icons not found.');
    exit(1);
  }

  final files = iconsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.png'))
      .toList();

  print('Found ${files.length} PNG files in assets/icons/\n');

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    print('Processing: $name');

    final bytes = file.readAsBytesSync();
    final image = img.decodePng(bytes);
    if (image == null) {
      print('  Skipped (could not decode)\n');
      continue;
    }

    final originalW = image.width;
    final originalH = image.height;

    // Find bounding box of non-transparent pixels
    int minX = originalW;
    int minY = originalH;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < originalH; y++) {
      for (int x = 0; x < originalW; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < 0 || maxY < 0) {
      print('  Skipped (fully transparent)\n');
      continue;
    }

    final cropW = maxX - minX + 1;
    final cropH = maxY - minY + 1;

    if (cropW == originalW && cropH == originalH) {
      print('  No transparent border to crop ($originalW x $originalH)\n');
      continue;
    }

    final cropped = img.copyCrop(
      image,
      x: minX,
      y: minY,
      width: cropW,
      height: cropH,
    );

    file.writeAsBytesSync(img.encodePng(cropped));
    print('  Cropped: $originalW x $originalH -> $cropW x $cropH\n');
  }

  print('Done!');
}
