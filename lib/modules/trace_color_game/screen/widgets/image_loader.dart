import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Loads an image from either an asset path or a network URL into a
/// decoded [ui.Image]. Returns null on failure.
///
/// Detects by prefix: values starting with `http://` or `https://` are
/// treated as network URLs; everything else is treated as an asset path.
Future<ui.Image?> loadImageFromPathOrUrl(String pathOrUrl) async {
  try {
    final isNetwork = pathOrUrl.startsWith('http');
    if (isNetwork) {
      return _loadFromProvider(NetworkImage(pathOrUrl));
    }
    final data = await rootBundle.load(pathOrUrl);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

Future<ui.Image?> _loadFromProvider(ImageProvider provider) async {
  final completer = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image);
      stream.removeListener(listener);
    },
    onError: (error, stack) {
      if (!completer.isCompleted) completer.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
