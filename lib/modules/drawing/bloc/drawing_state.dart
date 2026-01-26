import 'package:equatable/equatable.dart';

sealed class DrawingState extends Equatable {
  const DrawingState();

  @override
  List<Object> get props => [];
}

class DrawingInitial extends DrawingState {}

class DrawingLoading extends DrawingState {}

class DrawingLoaded extends DrawingState {
  final String drawingImageUrl;
  final String filledImageUrl;
  final int currentIndex;

  const DrawingLoaded({
    required this.drawingImageUrl,
    required this.filledImageUrl,
    required this.currentIndex,
  });

  @override
  List<Object> get props => [drawingImageUrl, filledImageUrl, currentIndex];
}

class DrawingError extends DrawingState {
  final String message;

  const DrawingError(this.message);

  @override
  List<Object> get props => [message];
}
