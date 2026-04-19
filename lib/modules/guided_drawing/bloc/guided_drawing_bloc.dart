import 'dart:math';
import 'package:bloc/bloc.dart';
import 'guided_drawing_event.dart';
import 'guided_drawing_state.dart';
import '../data/guided_drawing_service.dart';

class GuidedDrawingBloc
    extends Bloc<GuidedDrawingEvent, GuidedDrawingState> {
  final Random _random = Random();
  String? _currentTemplateId;

  GuidedDrawingBloc() : super(GuidedDrawingInitial()) {
    on<InitTemplates>(_onInit);
    on<SelectTemplate>(_onSelectTemplate);
    on<LoadNextTemplate>(_onLoadNext);
    on<DismissPreview>(_onDismissPreview);
    on<FinishTracing>(_onFinishTracing);
    on<SelectColor>(_onSelectColor);
    on<ToggleEraser>(_onToggleEraser);
    on<ResetDrawing>(_onResetDrawing);
  }

  void _onInit(InitTemplates event, Emitter<GuidedDrawingState> emit) {
    emit(GuidedDrawingLoading());

    final service = GuidedDrawingService.instance;
    service.loadFromAssets();

    if (service.templates.isEmpty) {
      emit(const GuidedDrawingError('No drawing templates found.'));
      return;
    }

    final template =
        service.templates[_random.nextInt(service.templates.length)];
    _currentTemplateId = template.id;

    emit(GuidedDrawingActive(
      template: template,
      allTemplates: service.templates,
    ));
  }

  void _onSelectTemplate(
    SelectTemplate event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final service = GuidedDrawingService.instance;
    final template = service.templates
        .where((t) => t.id == event.templateId)
        .firstOrNull;

    if (template == null) {
      emit(const GuidedDrawingError('Template not found'));
      return;
    }

    _currentTemplateId = template.id;
    emit(GuidedDrawingActive(
      template: template,
      allTemplates: service.templates,
    ));
  }

  void _onLoadNext(
    LoadNextTemplate event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final service = GuidedDrawingService.instance;
    final pool = service.templates;

    if (pool.isEmpty) {
      emit(const GuidedDrawingError('No templates available'));
      return;
    }

    if (pool.length == 1) {
      _currentTemplateId = pool[0].id;
      emit(GuidedDrawingActive(
        template: pool[0],
        allTemplates: pool,
      ));
      return;
    }

    // Pick a different template
    var template = pool[_random.nextInt(pool.length)];
    while (template.id == _currentTemplateId) {
      template = pool[_random.nextInt(pool.length)];
    }

    _currentTemplateId = template.id;
    emit(GuidedDrawingActive(
      template: template,
      allTemplates: pool,
    ));
  }

  void _onDismissPreview(
    DismissPreview event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final s = state;
    if (s is! GuidedDrawingActive) return;
    emit(s.copyWith(phase: DrawingPhase.tracing));
  }

  void _onFinishTracing(
    FinishTracing event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final s = state;
    if (s is! GuidedDrawingActive) return;
    emit(s.copyWith(phase: DrawingPhase.coloring));
  }

  void _onSelectColor(
    SelectColor event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final s = state;
    if (s is! GuidedDrawingActive) return;
    emit(s.copyWith(selectedColor: event.color, isEraser: false));
  }

  void _onToggleEraser(
    ToggleEraser event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final s = state;
    if (s is! GuidedDrawingActive) return;
    emit(s.copyWith(isEraser: !s.isEraser));
  }

  void _onResetDrawing(
    ResetDrawing event,
    Emitter<GuidedDrawingState> emit,
  ) {
    final s = state;
    if (s is! GuidedDrawingActive) return;
    emit(GuidedDrawingActive(
      template: s.template,
      allTemplates: s.allTemplates,
    ));
  }
}
