import 'package:equatable/equatable.dart';
import 'dart:ui';

sealed class TraceColorEvent extends Equatable {
  const TraceColorEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the game, load first level.
class StartGame extends TraceColorEvent {
  const StartGame();
}

/// Transition from tracing → coloring.
class FinishTracing extends TraceColorEvent {
  const FinishTracing();
}

/// Pick a color in the coloring phase.
class PickColor extends TraceColorEvent {
  final Color color;
  const PickColor(this.color);

  @override
  List<Object?> get props => [color];
}

/// Done coloring → celebration.
class FinishColoring extends TraceColorEvent {
  const FinishColoring();
}

/// Advance to the next level.
class NextLevel extends TraceColorEvent {
  const NextLevel();
}

/// Reset the current level from scratch.
class ResetLevel extends TraceColorEvent {
  const ResetLevel();
}
