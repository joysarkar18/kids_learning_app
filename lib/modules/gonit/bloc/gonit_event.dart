import 'package:equatable/equatable.dart';

sealed class GanitEvent extends Equatable {
  const GanitEvent();

  @override
  List<Object?> get props => [];
}

final class GanitInit extends GanitEvent {
  final String? type;
  const GanitInit({this.type});

  @override
  List<Object?> get props => [type];
}

final class GanitOptionSelected extends GanitEvent {
  final int optionId;
  const GanitOptionSelected(this.optionId);

  @override
  List<Object?> get props => [optionId];
}

final class GanitNextProblem extends GanitEvent {}

final class GanitSkipProblem extends GanitEvent {}

final class GanitRetry extends GanitEvent {}

final class GanitStop extends GanitEvent {}

final class GanitLoadMoreProblems extends GanitEvent {}

final class GanitPlayAgain extends GanitEvent {}

final class GanitStartListening extends GanitEvent {}

final class GanitSpeechDetected extends GanitEvent {
  final String text;
  const GanitSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class GanitReadQuestion extends GanitEvent {}

final class GanitMatchLeftSelected extends GanitEvent {
  final int pairId;
  const GanitMatchLeftSelected(this.pairId);

  @override
  List<Object?> get props => [pairId];
}

final class GanitMatchRightSelected extends GanitEvent {
  final int pairId;
  final int? leftPairId; // For drag-and-drop (overrides selectedLeftId)
  const GanitMatchRightSelected(this.pairId, {this.leftPairId});

  @override
  List<Object?> get props => [pairId, leftPairId];
}

final class GanitOrderItemPlaced extends GanitEvent {
  final int itemId;
  final int slotPosition;
  const GanitOrderItemPlaced(this.itemId, this.slotPosition);

  @override
  List<Object?> get props => [itemId, slotPosition];
}

final class GanitOrderItemRemoved extends GanitEvent {
  final int slotPosition;
  const GanitOrderItemRemoved(this.slotPosition);

  @override
  List<Object?> get props => [slotPosition];
}
