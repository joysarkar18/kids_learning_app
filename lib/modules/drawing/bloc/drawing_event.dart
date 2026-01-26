import 'package:equatable/equatable.dart';

sealed class DrawingEvent extends Equatable {
  const DrawingEvent();

  @override
  List<Object> get props => [];
}

/// Load initial random image
class LoadRandomImage extends DrawingEvent {
  const LoadRandomImage();
}

/// Load next random image
class LoadNextImage extends DrawingEvent {
  const LoadNextImage();
}
