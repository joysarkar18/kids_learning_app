import 'package:equatable/equatable.dart';

sealed class ChoraEvent extends Equatable {
  const ChoraEvent();

  @override
  List<Object?> get props => [];
}

final class ChoraInit extends ChoraEvent {}

final class ChoraLoadMore extends ChoraEvent {}

final class ChoraStop extends ChoraEvent {}
