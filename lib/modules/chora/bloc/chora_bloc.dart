import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repo/chora_repository.dart';
import 'chora_event.dart';
import 'chora_state.dart';

class ChoraBloc extends Bloc<ChoraEvent, ChoraState> {
  final ChoraRepository _repository = ChoraRepository();

  ChoraBloc() : super(const ChoraInitial()) {
    on<ChoraInit>(_onInit);
    on<ChoraLoadMore>(_onLoadMore);
    on<ChoraStop>(_onStop);
  }

  Future<void> _onInit(ChoraInit event, Emitter<ChoraState> emit) async {
    emit(const ChoraLoading());
    try {
      _repository.resetPagination();
      final choras = await _repository.fetchChoras();
      emit(ChoraLoaded(choras: choras));
    } catch (e) {
      emit(ChoraError(errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMore(ChoraLoadMore event, Emitter<ChoraState> emit) async {
    if (!_repository.hasMoreData) return;
    final currentState = state;
    if (currentState is! ChoraLoaded) return;

    try {
      final moreChoras = await _repository.fetchChoras();
      emit(ChoraLoaded(choras: [...currentState.choras, ...moreChoras]));
    } catch (e) {
      // Keep current data on load-more failure
    }
  }

  void _onStop(ChoraStop event, Emitter<ChoraState> emit) {
    // Cleanup if needed
  }
}
