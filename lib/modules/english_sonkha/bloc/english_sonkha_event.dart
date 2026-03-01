import 'package:equatable/equatable.dart';

sealed class EnglishSonkhaEvent extends Equatable {
  const EnglishSonkhaEvent();

  @override
  List<Object?> get props => [];
}

final class EnglishSonkhaInit extends EnglishSonkhaEvent {
  final int? startingIndex;
  const EnglishSonkhaInit({this.startingIndex});

  @override
  List<Object?> get props => [startingIndex];
}

final class EnglishSonkhaNext extends EnglishSonkhaEvent {}

final class EnglishSonkhaPrevious extends EnglishSonkhaEvent {}

final class EnglishSonkhaRetry extends EnglishSonkhaEvent {}

final class EnglishSonkhaStartListening extends EnglishSonkhaEvent {}

final class EnglishSonkhaSpeechDetected extends EnglishSonkhaEvent {
  final String text;
  const EnglishSonkhaSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class EnglishSonkhaStop extends EnglishSonkhaEvent {}
