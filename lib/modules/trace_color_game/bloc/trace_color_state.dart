import 'package:equatable/equatable.dart';
import 'dart:ui';
import '../data/game_level.dart';

enum GamePhase { tracing, coloring, celebration }

sealed class TraceColorState extends Equatable {
  const TraceColorState();

  @override
  List<Object?> get props => [];
}

class TraceColorInitial extends TraceColorState {}

class TraceColorLoading extends TraceColorState {}

class TraceColorActive extends TraceColorState {
  final GameLevel level;
  final GamePhase phase;
  final Color selectedColor; // current brush color

  const TraceColorActive({
    required this.level,
    this.phase = GamePhase.tracing,
    this.selectedColor = const Color(0xFFE53935), // default red
  });

  TraceColorActive copyWith({
    GameLevel? level,
    GamePhase? phase,
    Color? selectedColor,
  }) {
    return TraceColorActive(
      level: level ?? this.level,
      phase: phase ?? this.phase,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  @override
  List<Object?> get props => [level.level, phase, selectedColor];
}

class TraceColorError extends TraceColorState {
  final String message;
  const TraceColorError(this.message);

  @override
  List<Object?> get props => [message];
}
