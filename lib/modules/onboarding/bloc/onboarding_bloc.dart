import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_event.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingEvent>((event, emit) {});
    on<FriendSelectionEvent>((event, emit) async {
      emit(OnboardingLoadingState());
      try {
        await SharedPreferences.getInstance().then((prefs) async {
          await prefs.setString('selected_friend', event.selectedFriend);
          emit(FriendSelectionState());
        });
      } catch (e) {
        emit(OnboardingErrorState(e.toString()));
      }
    });
  }
}
