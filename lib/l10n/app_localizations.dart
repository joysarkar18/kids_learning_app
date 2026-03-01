import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseLanguage;

  /// No description provided for @selectPreferred.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectPreferred;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা (Bengali)'**
  String get bengali;

  /// No description provided for @letsGo.
  ///
  /// In en, this message translates to:
  /// **'LET\'S GO!'**
  String get letsGo;

  /// No description provided for @chooseYourFriend.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Friend'**
  String get chooseYourFriend;

  /// No description provided for @pickFavorite.
  ///
  /// In en, this message translates to:
  /// **'Pick your favorite character!'**
  String get pickFavorite;

  /// No description provided for @chintu.
  ///
  /// In en, this message translates to:
  /// **'Chintu'**
  String get chintu;

  /// No description provided for @gauri.
  ///
  /// In en, this message translates to:
  /// **'Gauri'**
  String get gauri;

  /// No description provided for @moti.
  ///
  /// In en, this message translates to:
  /// **'Moti'**
  String get moti;

  /// No description provided for @gudiya.
  ///
  /// In en, this message translates to:
  /// **'Gudiya'**
  String get gudiya;

  /// No description provided for @gajraj.
  ///
  /// In en, this message translates to:
  /// **'Gajraj'**
  String get gajraj;

  /// No description provided for @chiku.
  ///
  /// In en, this message translates to:
  /// **'Chiku'**
  String get chiku;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong!'**
  String get somethingWentWrong;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @signInToStart.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start learning!'**
  String get signInToStart;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @agreeText.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get agreeText;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andText;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @todaysMissions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Missions'**
  String get todaysMissions;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @goButton.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get goButton;

  /// No description provided for @missionComplete.
  ///
  /// In en, this message translates to:
  /// **'Mission Complete!'**
  String get missionComplete;

  /// No description provided for @allMissionsComplete.
  ///
  /// In en, this message translates to:
  /// **'All missions complete! +{count}'**
  String allMissionsComplete(int count);

  /// No description provided for @missionsProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} missions done'**
  String missionsProgress(int completed, int total);

  /// No description provided for @miniGames.
  ///
  /// In en, this message translates to:
  /// **'Mini Games'**
  String get miniGames;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @miniGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More games are on their way!'**
  String get miniGamesSubtitle;

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get noGamesFound;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get settingsSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
