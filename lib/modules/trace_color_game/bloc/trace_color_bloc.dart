import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/guided_drawing/data/guided_drawing_service.dart';
import 'package:kids_learning/modules/guided_drawing/data/models/drawing_template.dart';
import 'trace_color_event.dart';
import 'trace_color_state.dart';
import '../data/game_level.dart';

class TraceColorBloc extends Bloc<TraceColorEvent, TraceColorState> {
  int _currentIndex = 0;
  final Random _rng = Random();

  TraceColorBloc() : super(TraceColorInitial()) {
    on<StartGame>(_onStart);
    on<FinishTracing>(_onFinishTracing);
    on<PickColor>(_onPickColor);
    on<FinishColoring>(_onFinishColoring);
    on<NextLevel>(_onNextLevel);
    on<ResetLevel>(_onResetLevel);
  }

  List<DrawingTemplate> get _templates =>
      GuidedDrawingService.instance.templates;

  GameLevel _levelAt(int index) {
    final template = _templates[index];
    return GameLevel(
      level: index + 1,
      template: template,
      correctColor: correctColorFor(template.id),
    );
  }

  /// Returns a random template index that is NOT equal to [avoidIndex].
  /// Falls back to 0 if there's only one template.
  int _pickRandomIndex({int? avoidIndex}) {
    final n = _templates.length;
    if (n <= 1) return 0;
    int idx;
    do {
      idx = _rng.nextInt(n);
    } while (idx == avoidIndex);
    return idx;
  }

  void _onStart(StartGame event, Emitter<TraceColorState> emit) {
    final service = GuidedDrawingService.instance;
    // Prefer templates from Firebase Remote Config; fall back to assets
    // only if the remote list is empty or hasn't loaded yet.
    if (!service.loadFromConfig()) {
      service.loadFromAssets();
    }

    if (_templates.isEmpty) {
      emit(const TraceColorError('No levels found.'));
      return;
    }
    _currentIndex = _pickRandomIndex();
    emit(TraceColorActive(
      level: _levelAt(_currentIndex),
      selectedColor: kidColorPalette.first,
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
    if (_templates.isEmpty) return;
    // Pick a new random image that is not the one just shown.
    _currentIndex = _pickRandomIndex(avoidIndex: _currentIndex);
    emit(TraceColorActive(
      level: _levelAt(_currentIndex),
      selectedColor: kidColorPalette.first,
    ));
  }

  void _onResetLevel(ResetLevel event, Emitter<TraceColorState> emit) {
    final s = state;
    if (s is! TraceColorActive) return;
    emit(TraceColorActive(
      level: s.level,
      selectedColor: kidColorPalette.first,
    ));
  }
}
