import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_event.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_state.dart';
import 'package:kids_learning/services/remote_config_service.dart';
import 'dart:math';

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  final RemoteConfigService _configService = RemoteConfigService();
  final Random _random = Random();
  int _currentIndex = -1;

  DrawingBloc() : super(DrawingInitial()) {
    on<LoadRandomImage>(_onLoadRandomImage);
    on<LoadNextImage>(_onLoadNextImage);
  }

  Future<void> _onLoadRandomImage(
    LoadRandomImage event,
    Emitter<DrawingState> emit,
  ) async {
    emit(DrawingLoading());

    try {
      final drawingImages = _configService.drawingImages;
      final filledImages = _configService.filledImages;

      if (drawingImages.isEmpty || filledImages.isEmpty) {
        emit(const DrawingError('No images available'));
        return;
      }

      if (drawingImages.length != filledImages.length) {
        emit(const DrawingError('Image lists mismatch'));
        return;
      }

      // Get random index
      _currentIndex = _random.nextInt(drawingImages.length);

      emit(
        DrawingLoaded(
          drawingImageUrl: drawingImages[_currentIndex],
          filledImageUrl: filledImages[_currentIndex],
          currentIndex: _currentIndex,
        ),
      );
    } catch (e) {
      emit(DrawingError('Failed to load image: $e'));
    }
  }

  Future<void> _onLoadNextImage(
    LoadNextImage event,
    Emitter<DrawingState> emit,
  ) async {
    emit(DrawingLoading());

    try {
      final drawingImages = _configService.drawingImages;
      final filledImages = _configService.filledImages;

      if (drawingImages.isEmpty || filledImages.isEmpty) {
        emit(const DrawingError('No images available'));
        return;
      }

      // Get a different random index
      int newIndex;
      if (drawingImages.length == 1) {
        newIndex = 0;
      } else {
        do {
          newIndex = _random.nextInt(drawingImages.length);
        } while (newIndex == _currentIndex);
      }

      _currentIndex = newIndex;

      emit(
        DrawingLoaded(
          drawingImageUrl: drawingImages[_currentIndex],
          filledImageUrl: filledImages[_currentIndex],
          currentIndex: _currentIndex,
        ),
      );
    } catch (e) {
      emit(DrawingError('Failed to load next image: $e'));
    }
  }
}
