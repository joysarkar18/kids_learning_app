import 'package:equatable/equatable.dart';
import 'dart:ui';
import '../data/models/drawing_template.dart';

enum DrawingPhase { preview, tracing, coloring }

sealed class GuidedDrawingState extends Equatable {
  const GuidedDrawingState();

  @override
  List<Object?> get props => [];
}

class GuidedDrawingInitial extends GuidedDrawingState {}

class GuidedDrawingLoading extends GuidedDrawingState {}

class GuidedDrawingActive extends GuidedDrawingState {
  final DrawingTemplate template;
  final List<DrawingTemplate> allTemplates;
  final DrawingPhase phase;

  // Coloring state
  final Color selectedColor;
  final bool isEraser;

  const GuidedDrawingActive({
    required this.template,
    required this.allTemplates,
    this.phase = DrawingPhase.preview,
    this.selectedColor = const Color(0xFFE74C3C),
    this.isEraser = false,
  });

  GuidedDrawingActive copyWith({
    DrawingTemplate? template,
    List<DrawingTemplate>? allTemplates,
    DrawingPhase? phase,
    Color? selectedColor,
    bool? isEraser,
  }) {
    return GuidedDrawingActive(
      template: template ?? this.template,
      allTemplates: allTemplates ?? this.allTemplates,
      phase: phase ?? this.phase,
      selectedColor: selectedColor ?? this.selectedColor,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  @override
  List<Object?> get props => [template.id, phase, selectedColor, isEraser];
}

class GuidedDrawingError extends GuidedDrawingState {
  final String message;
  const GuidedDrawingError(this.message);

  @override
  List<Object?> get props => [message];
}
