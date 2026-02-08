import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repo/chora_repository.dart';
import 'chora_event.dart';
import 'chora_state.dart';

class ChoraBloc extends Bloc<ChoraEvent, ChoraState> {
  final ChoraRepository _repository = ChoraRepository();
  bool _isLoadingMore = false;

  ChoraBloc() : super(const ChoraInitial()) {
    on<ChoraInit>(_onInit);
    on<ChoraLoadMore>(_onLoadMore);
    on<ChoraStop>(_onStop);
  }

  Future<void> _onInit(ChoraInit event, Emitter<ChoraState> emit) async {
    emit(const ChoraLoading());
    _isLoadingMore = false;
    try {
      _repository.resetPagination();
      final choras = await _repository.fetchChoras();
      emit(ChoraLoaded(choras: choras, hasMore: _repository.hasMoreData));
    } catch (e) {
      emit(ChoraError(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMore(ChoraLoadMore event, Emitter<ChoraState> emit) async {
    if (_isLoadingMore || !_repository.hasMoreData) return;
    final currentState = state;
    if (currentState is! ChoraLoaded) return;

    _isLoadingMore = true;
    try {
      final moreChoras = await _repository.fetchChoras();
      emit(ChoraLoaded(
        choras: [...currentState.choras, ...moreChoras],
        hasMore: _repository.hasMoreData,
      ));
    } catch (e) {
      // Keep current data on load-more failure
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onStop(ChoraStop event, Emitter<ChoraState> emit) {
    // Cleanup if needed
  }
}
