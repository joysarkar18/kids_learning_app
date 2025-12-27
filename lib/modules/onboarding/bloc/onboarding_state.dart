import 'package:equatable/equatable.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

final class OnboardingInitial extends OnboardingState {}

final class FriendSelectionState extends OnboardingState {}

final class OnboardingLoadingState extends OnboardingState {}

final class OnboardingErrorState extends OnboardingState {
  final String message;

  const OnboardingErrorState(this.message);

  @override
  List<Object> get props => [message];
}
