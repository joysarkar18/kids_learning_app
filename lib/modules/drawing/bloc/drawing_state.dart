import 'package:equatable/equatable.dart';

sealed class DrawingState extends Equatable {
  const DrawingState();

  @override
  List<Object> get props => [];
}

final class DrawingInitial extends DrawingState {}
