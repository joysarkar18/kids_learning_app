import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repo/mini_game_repository.dart';
import 'mini_games_event.dart';
import 'mini_games_state.dart';

class MiniGamesBloc extends Bloc<MiniGamesEvent, MiniGamesState> {
  final MiniGameRepository _repository;

  MiniGamesBloc({MiniGameRepository? repository})
      : _repository = repository ?? MiniGameRepository(),
        super(const MiniGamesInitial()) {
    on<MiniGamesLoadEvent>(_onLoad);
    on<MiniGamesLoadMoreEvent>(_onLoadMore);
  }

  Future<void> _onLoad(
    MiniGamesLoadEvent event,
    Emitter<MiniGamesState> emit,
  ) async {
    emit(const MiniGamesLoading());
    try {
      _repository.resetPagination();
      final games = await _repository.fetchGames();
      emit(MiniGamesLoaded(
        games: games,
        hasMore: _repository.hasMoreData,
      ));
    } catch (e) {
      emit(MiniGamesError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    MiniGamesLoadMoreEvent event,
    Emitter<MiniGamesState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MiniGamesLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    try {
      final moreGames = await _repository.fetchGames();
      emit(MiniGamesLoaded(
        games: [...currentState.games, ...moreGames],
        hasMore: _repository.hasMoreData,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }
}
