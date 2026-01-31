import 'package:equatable/equatable.dart';

sealed class BanglaSonkhaEvent extends Equatable {
  const BanglaSonkhaEvent();

  @override
  List<Object?> get props => [];
}

final class BanglaSonkhaInit extends BanglaSonkhaEvent {}

final class BanglaSonkhaNext extends BanglaSonkhaEvent {}

final class BanglaSonkhaPrevious extends BanglaSonkhaEvent {}

final class BanglaSonkhaRetry extends BanglaSonkhaEvent {}

final class BanglaSonkhaStartListening extends BanglaSonkhaEvent {}

final class BanglaSonkhaSpeechDetected extends BanglaSonkhaEvent {
  final String text;
  const BanglaSonkhaSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class BanglaSonkhaStop extends BanglaSonkhaEvent {}
