// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get chooseLanguage => 'Choose Your Language';

  @override
  String get selectPreferred => 'Select your preferred language';

  @override
  String get english => 'English';

  @override
  String get bengali => 'বাংলা (Bengali)';

  @override
  String get letsGo => 'LET\'S GO!';

  @override
  String get chooseYourFriend => 'Choose Your Friend';

  @override
  String get pickFavorite => 'Pick your favorite character!';

  @override
  String get chintu => 'Chintu';

  @override
  String get gauri => 'Gauri';

  @override
  String get moti => 'Moti';

  @override
  String get gudiya => 'Gudiya';

  @override
  String get gajraj => 'Gajraj';

  @override
  String get chiku => 'Chiku';

  @override
  String get somethingWentWrong => 'Something went wrong!';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get welcome => 'Welcome!';

  @override
  String get signInToStart => 'Sign in to start learning!';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get agreeText => 'By continuing, you agree to our';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get andText => 'and';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get todaysMissions => 'Today\'s Missions';

  @override
  String get streak => 'Streak';

  @override
  String get stars => 'Stars';

  @override
  String get goButton => 'Go';

  @override
  String get missionComplete => 'Mission Complete!';

  @override
  String allMissionsComplete(int count) {
    return 'All missions complete! +$count';
  }

  @override
  String missionsProgress(int completed, int total) {
    return '$completed/$total missions done';
  }

  @override
  String get miniGames => 'Mini Games';

  @override
  String get settings => 'Settings';

  @override
  String get comingSoon => 'Coming Soon!';

  @override
  String get miniGamesSubtitle => 'More games are on their way!';

  @override
  String get noGamesFound => 'No games found';

  @override
  String get settingsSubtitle => 'Coming Soon!';
}
