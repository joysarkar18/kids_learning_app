import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/icons/banan.png');
  final image = img.decodePng(file.readAsBytesSync())!;

  print('Size: ${image.width} x ${image.height}');

  // Check corner pixels
  for (final pos in [
    [0, 0, 'top-left'],
    [image.width - 1, 0, 'top-right'],
    [0, image.height - 1, 'bottom-left'],
    [image.width - 1, image.height - 1, 'bottom-right'],
    [image.width ~/ 2, 0, 'top-center'],
    [0, image.height ~/ 2, 'left-center'],
  ]) {
    final p = image.getPixel(pos[0] as int, pos[1] as int);
    print('${pos[2]}: r=${p.r} g=${p.g} b=${p.b} a=${p.a}');
  }

  // Count pixels by alpha ranges
  int fullyTransparent = 0;
  int semiTransparent = 0;
  int fullyOpaque = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final a = image.getPixel(x, y).a;
      if (a == 0) {
        fullyTransparent++;
      } else if (a < 255) {
        semiTransparent++;
      } else {
        fullyOpaque++;
      }
    }
  }
  print('\nAlpha distribution:');
  print('  Fully transparent (a=0): $fullyTransparent');
  print('  Semi-transparent (0<a<255): $semiTransparent');
  print('  Fully opaque (a=255): $fullyOpaque');
}
