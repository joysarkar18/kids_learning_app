import 'package:equatable/equatable.dart';

sealed class BornomalaEvent extends Equatable {
  const BornomalaEvent();

  @override
  List<Object?> get props => [];
}

final class BornomalaInit extends BornomalaEvent {}

final class BornomalaNext extends BornomalaEvent {}

final class BornomalaPrevious extends BornomalaEvent {}

final class BornomalaRetry extends BornomalaEvent {}

final class BornomalaStartListening extends BornomalaEvent {}

final class BornomalaSpeechDetected extends BornomalaEvent {
  final String text;
  const BornomalaSpeechDetected(this.text);

  @override
  List<Object?> get props => [text];
}

final class BornomalaStop extends BornomalaEvent {}
