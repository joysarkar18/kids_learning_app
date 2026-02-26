import 'package:equatable/equatable.dart';

sealed class NamotaEvent extends Equatable {
  const NamotaEvent();

  @override
  List<Object?> get props => [];
}

final class NamotaInit extends NamotaEvent {
  final int tableNumber;
  const NamotaInit(this.tableNumber);

  @override
  List<Object?> get props => [tableNumber];
}

final class NamotaStartListening extends NamotaEvent {}

final class NamotaSpeechDetected extends NamotaEvent {
  final String text;
  const NamotaSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class NamotaRetry extends NamotaEvent {}

final class NamotaPlayAll extends NamotaEvent {}

final class NamotaStop extends NamotaEvent {}
