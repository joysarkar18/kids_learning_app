import 'package:equatable/equatable.dart';

abstract class MiniGamesEvent extends Equatable {
  const MiniGamesEvent();

  @override
  List<Object?> get props => [];
}

class MiniGamesLoadEvent extends MiniGamesEvent {
  const MiniGamesLoadEvent();
}

class MiniGamesLoadMoreEvent extends MiniGamesEvent {
  const MiniGamesLoadMoreEvent();
}
