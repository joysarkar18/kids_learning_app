import 'package:equatable/equatable.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/challenge_progress_model.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_challenge_model.dart';

abstract class DailyChallengeState extends Equatable {
  const DailyChallengeState();

  @override
  List<Object?> get props => [];
}

class DailyChallengeInitial extends DailyChallengeState {
  const DailyChallengeInitial();
}

class DailyChallengeLoading extends DailyChallengeState {
  const DailyChallengeLoading();
}

class DailyChallengeLoaded extends DailyChallengeState {
  final DailyChallenge challenge;
  final ChallengeProgress progress;
  final bool justCompletedAll;

  const DailyChallengeLoaded({
    required this.challenge,
    required this.progress,
    this.justCompletedAll = false,
  });

  @override
  List<Object?> get props => [challenge.date, challenge.starsEarned, progress.totalStars, justCompletedAll];
}

class DailyChallengeError extends DailyChallengeState {
  final String message;

  const DailyChallengeError(this.message);

  @override
  List<Object?> get props => [message];
}
