import 'package:bloc/bloc.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

import 'daily_challenge_event.dart';
import 'daily_challenge_state.dart';

class DailyChallengeBloc
    extends Bloc<DailyChallengeEvent, DailyChallengeState> {
  final DailyChallengeService _service = DailyChallengeService.instance;

  DailyChallengeBloc() : super(const DailyChallengeInitial()) {
    on<LoadDailyChallenge>(_onLoad);
    on<CompleteMissionStep>(_onCompleteMissionStep);
    on<RefreshChallenge>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadDailyChallenge event,
    Emitter<DailyChallengeState> emit,
  ) async {
    emit(const DailyChallengeLoading());
    try {
      await _service.initialize();
      final challenge = _service.todayChallenge;
      if (challenge == null) {
        emit(const DailyChallengeError('Failed to load daily challenge'));
        return;
      }
      emit(DailyChallengeLoaded(
        challenge: challenge,
        progress: _service.progress,
      ));
    } catch (e) {
      emit(DailyChallengeError(e.toString()));
    }
  }

  Future<void> _onCompleteMissionStep(
    CompleteMissionStep event,
    Emitter<DailyChallengeState> emit,
  ) async {
    final challenge = _service.todayChallenge;
    if (challenge == null) return;

    final wasAllCompleted = challenge.isAllCompleted;
    await _service.reportProgress(event.moduleKey);
    final nowAllCompleted = challenge.isAllCompleted;

    emit(DailyChallengeLoaded(
      challenge: challenge,
      progress: _service.progress,
      justCompletedAll: !wasAllCompleted && nowAllCompleted,
    ));
  }

  Future<void> _onRefresh(
    RefreshChallenge event,
    Emitter<DailyChallengeState> emit,
  ) async {
    await _service.initialize();
    final challenge = _service.todayChallenge;
    if (challenge != null) {
      emit(DailyChallengeLoaded(
        challenge: challenge,
        progress: _service.progress,
      ));
    }
  }
}
