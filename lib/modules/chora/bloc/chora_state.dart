import 'package:equatable/equatable.dart';
import '../data/models/chora_model.dart';

sealed class ChoraState extends Equatable {
  final List<ChoraModel> choras;

  const ChoraState({this.choras = const []});

  @override
  List<Object?> get props => [choras];
}

final class ChoraInitial extends ChoraState {
  const ChoraInitial();
}

final class ChoraLoading extends ChoraState {
  const ChoraLoading();
}

final class ChoraLoaded extends ChoraState {
  const ChoraLoaded({required super.choras});
}

final class ChoraError extends ChoraState {
  final String errorMessage;
  const ChoraError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
