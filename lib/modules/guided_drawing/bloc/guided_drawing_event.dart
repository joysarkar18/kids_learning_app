import 'package:equatable/equatable.dart';
import 'dart:ui';

sealed class GuidedDrawingEvent extends Equatable {
  const GuidedDrawingEvent();

  @override
  List<Object?> get props => [];
}

/// Load templates and auto-select first
class InitTemplates extends GuidedDrawingEvent {
  const InitTemplates();
}

/// Select a specific template
class SelectTemplate extends GuidedDrawingEvent {
  final String templateId;
  const SelectTemplate(this.templateId);

  @override
  List<Object?> get props => [templateId];
}

/// Load next template (skip current)
class LoadNextTemplate extends GuidedDrawingEvent {
  const LoadNextTemplate();
}

/// Dismiss the reference preview → start tracing
class DismissPreview extends GuidedDrawingEvent {
  const DismissPreview();
}

/// Done tracing → move to coloring
class FinishTracing extends GuidedDrawingEvent {
  const FinishTracing();
}

/// Select a color in the palette
class SelectColor extends GuidedDrawingEvent {
  final Color color;
  const SelectColor(this.color);

  @override
  List<Object?> get props => [color];
}

/// Toggle eraser mode
class ToggleEraser extends GuidedDrawingEvent {
  const ToggleEraser();
}

/// Reset current drawing to start over
class ResetDrawing extends GuidedDrawingEvent {
  const ResetDrawing();
}
