import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

final class FriendSelectionEvent extends OnboardingEvent {
  final String selectedFriend;

  const FriendSelectionEvent({required this.selectedFriend});

  @override
  List<Object> get props => [selectedFriend];
}
