import 'package:equatable/equatable.dart';

abstract class DailyChallengeEvent extends Equatable {
  const DailyChallengeEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyChallenge extends DailyChallengeEvent {}

class CompleteMissionStep extends DailyChallengeEvent {
  final String moduleKey;

  const CompleteMissionStep(this.moduleKey);

  @override
  List<Object?> get props => [moduleKey];
}

class RefreshChallenge extends DailyChallengeEvent {}
