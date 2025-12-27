import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_event.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_state.dart';
import 'package:kids_learning/services/friend_selection_service.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingEvent>((event, emit) {});
    on<FriendSelectionEvent>((event, emit) async {
      emit(OnboardingLoadingState());
      try {
        final success = await FriendSelectionService.instance.saveFriend(
          event.selectedFriend,
        );

        if (success) {
          emit(FriendSelectionState());
        } else {
          emit(OnboardingErrorState('Failed to save friend selection'));
        }
      } catch (e) {
        emit(OnboardingErrorState(e.toString()));
      }
    });
  }
}
