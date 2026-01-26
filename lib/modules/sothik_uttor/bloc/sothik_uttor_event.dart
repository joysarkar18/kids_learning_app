import 'package:equatable/equatable.dart';

sealed class SothikUttorEvent extends Equatable {
  const SothikUttorEvent();

  @override
  List<Object?> get props => [];
}

final class SothikUttorInit extends SothikUttorEvent {}

final class SothikUttorNextQuestion extends SothikUttorEvent {}

final class SothikUttorSkipQuestion extends SothikUttorEvent {}

final class SothikUttorStartListening extends SothikUttorEvent {}

final class SothikUttorSpeechDetected extends SothikUttorEvent {
  final String text;
  const SothikUttorSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class SothikUttorRetry extends SothikUttorEvent {}

final class SothikUttorStop extends SothikUttorEvent {}

final class SothikUttorLoadMoreQuestions extends SothikUttorEvent {}

final class SothikUttorOptionSelected extends SothikUttorEvent {
  final int optionId;
  const SothikUttorOptionSelected(this.optionId);

  @override
  List<Object?> get props => [optionId];
}
