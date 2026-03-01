import 'package:equatable/equatable.dart';
import '../data/models/mini_game_model.dart';

abstract class MiniGamesState extends Equatable {
  const MiniGamesState();

  @override
  List<Object?> get props => [];
}

class MiniGamesInitial extends MiniGamesState {
  const MiniGamesInitial();
}

class MiniGamesLoading extends MiniGamesState {
  const MiniGamesLoading();
}

class MiniGamesLoaded extends MiniGamesState {
  final List<MiniGameModel> games;
  final bool hasMore;
  final bool isLoadingMore;

  const MiniGamesLoaded({
    required this.games,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  MiniGamesLoaded copyWith({
    List<MiniGameModel>? games,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MiniGamesLoaded(
      games: games ?? this.games,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [games, hasMore, isLoadingMore];
}

class MiniGamesError extends MiniGamesState {
  final String message;

  const MiniGamesError(this.message);

  @override
  List<Object?> get props => [message];
}
