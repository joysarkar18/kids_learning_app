import 'package:equatable/equatable.dart';

sealed class AlphabetEvent extends Equatable {
  const AlphabetEvent();

  @override
  List<Object?> get props => [];
}

final class AlphabetInit extends AlphabetEvent {}

final class AlphabetNext extends AlphabetEvent {}

final class AlphabetPrevious extends AlphabetEvent {}

final class AlphabetRetry extends AlphabetEvent {}

final class AlphabetStartListening extends AlphabetEvent {}

final class AlphabetSpeechDetected extends AlphabetEvent {
  final String text;
  const AlphabetSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class AlphabetStop extends AlphabetEvent {}
