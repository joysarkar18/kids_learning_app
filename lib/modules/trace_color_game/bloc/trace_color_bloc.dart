import 'package:bloc/bloc.dart';
import 'trace_color_event.dart';
import 'trace_color_state.dart';
import '../data/game_level.dart';

class TraceColorBloc extends Bloc<TraceColorEvent, TraceColorState> {
  int _currentIndex = 0;

  TraceColorBloc() : super(TraceColorInitial()) {
    on<StartGame>(_onStart);
    on<FinishTracing>(_onFinishTracing);
    on<PickColor>(_onPickColor);
    on<FinishColoring>(_onFinishColoring);
    on<NextLevel>(_onNextLevel);
    on<ResetLevel>(_onResetLevel);
  }

  void _onStart(StartGame event, Emitter<TraceColorState> emit) {
    if (gameLevels.isEmpty) {
      emit(const TraceColorError('No levels found.'));
      return;
    }
    _currentIndex = 0;
    final level = gameLevels[_currentIndex];
    emit(TraceColorActive(
      level: level,
      selectedColor: level.allColors.first,
    ));
  }

  void _onFinishTracing(FinishTracing event, Emitter<TraceColorState> emit) {
    final s = state;
    if (s is! TraceColorActive) return;
    emit(s.copyWith(phase: GamePhase.coloring));
  }

  void _onPickColor(PickColor event, Emitter<TraceColorState> emit) {
    final s = state;
    if (s is! TraceColorActive) return;
    emit(s.copyWith(selectedColor: event.color));
  }

  void _onFinishColoring(
      FinishColoring event, Emitter<TraceColorState> emit) {
    final s = state;
    if (s is! TraceColorActive) return;
    emit(s.copyWith(phase: GamePhase.celebration));
  }

  void _onNextLevel(NextLevel event, Emitter<TraceColorState> emit) {
    _currentIndex = (_currentIndex + 1) % gameLevels.length;
    final level = gameLevels[_currentIndex];
    emit(TraceColorActive(
      level: level,
      selectedColor: level.allColors.first,
    ));
  }

  void _onResetLevel(ResetLevel event, Emitter<TraceColorState> emit) {
    final s = state;
    if (s is! TraceColorActive) return;
    emit(TraceColorActive(
      level: s.level,
      selectedColor: s.level.allColors.first,
    ));
  }
}
