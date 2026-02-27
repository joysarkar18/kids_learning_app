import 'package:kids_learning/modules/drawing/screen/drawing_view.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_view.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_wrapper.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_wrapper.dart';
import 'package:kids_learning/modules/bangla_sonkha/screen/bangla_sonkha_wrapper.dart';
import 'package:kids_learning/modules/chora/data/models/chora_model.dart';
import 'package:kids_learning/modules/chora/screen/chora_player_view.dart';
import 'package:kids_learning/modules/chora/screen/chora_wrapper.dart';
import 'package:kids_learning/modules/english_sonkha/screen/english_sonkha_wrapper.dart';
import 'package:kids_learning/modules/gonit/screen/gonit_category_view.dart';
import 'package:kids_learning/modules/gonit/screen/gonit_wrapper.dart';
import 'package:kids_learning/modules/daily_challenge/screen/daily_challenge_view.dart';
import 'package:kids_learning/modules/namota/screen/namota_selection_view.dart';
import 'package:kids_learning/modules/namota/screen/namota_wrapper.dart';
import 'package:kids_learning/modules/sothik_uttor/screen/sothik_uttor_wrapper.dart';
import 'package:kids_learning/modules/onboarding/screen/language_selection_screen.dart';
import 'package:kids_learning/modules/onboarding/screen/login_screen.dart';
import 'package:kids_learning/modules/onboarding/screen/onboarding_view.dart';
import 'package:kids_learning/routes/app_routes.dart';

// Screens
import 'package:kids_learning/modules/onboarding/screen/splash_screen.dart';
import 'package:kids_learning/modules/home/screen/home_view.dart';

// Global Key for Context access if needed outside widgets
class GlobalNavigation {
  static final GlobalNavigation instance = GlobalNavigation._internal();
  GlobalNavigation._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

final router = GoRouter(
  initialLocation: Routes.init, // Start at Splash
  navigatorKey: GlobalNavigation.instance.navigatorKey,
  routes: [
    GoRoute(
      name: Names.drawing,
      path: Routes.drawing,
      builder: (context, state) => const DrawingScreen(),
    ),

    GoRoute(
      name: Names.chora,
      path: Routes.chora,
      builder: (context, state) => const ChoraScreenWrapper(),
    ),

    GoRoute(
      name: Names.choraPlayer,
      path: Routes.choraPlayer,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null) {
          return const ChoraScreenWrapper();
        }
        return ChoraPlayerScreen(
          choras: data['choras'] as List<ChoraModel>,
          initialIndex: data['index'] as int,
        );
      },
    ),

    GoRoute(
      name: Names.alphabate,
      path: Routes.alphabate,
      builder: (context, state) => const AlphabetScreenWrapper(),
    ),

    GoRoute(
      name: Names.bornomala,
      path: Routes.bornomala,
      builder: (context, state) => const BornomalaScreenWrapper(),
    ),

    GoRoute(
      name: Names.sothikUttor,
      path: Routes.sothikUttor,
      builder: (context, state) => const SothikUttorScreenWrapper(),
    ),

    GoRoute(
      name: Names.banglaSonkha,
      path: Routes.banglaSonkha,
      builder: (context, state) => const BanglaSonkhaScreenWrapper(),
    ),

    GoRoute(
      name: Names.englishSonkha,
      path: Routes.englishSonkha,
      builder: (context, state) => const EnglishSonkhaScreenWrapper(),
    ),

    GoRoute(
      name: Names.ganit,
      path: Routes.ganit,
      builder: (context, state) => const GanitCategoryScreen(),
    ),

    GoRoute(
      name: Names.ganitPlay,
      path: Routes.ganitPlay,
      builder: (context, state) {
        final type = state.extra as String?;
        return GanitScreenWrapper(type: type);
      },
    ),

    GoRoute(
      name: Names.namota,
      path: Routes.namota,
      builder: (context, state) => const NamotaSelectionScreen(),
    ),

    GoRoute(
      name: Names.namotaPractice,
      path: Routes.namotaPractice,
      builder: (context, state) {
        final tableNumber = state.extra as int? ?? 1;
        return NamotaScreenWrapper(tableNumber: tableNumber);
      },
    ),

    // 1. Splash Screen (Entry Point)
    GoRoute(
      name: Names.init,
      path: Routes.init,
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Language Selector
    GoRoute(
      name: Names.language,
      path: Routes.language,
      builder: (context, state) => const LanguageSelectorScreen(),
    ),

    // 2.5 Login Screen
    GoRoute(
      name: Names.login,
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),

    // 3. Character Selector (Onboarding)
    GoRoute(
      name: Names.onboarding,
      path: Routes.onboarding,
      builder: (context, state) => const CharacterSelectorScreen(),
    ),

    // 4. Home Screen
    GoRoute(
      name: Names.home,
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
    ),

    // 5. Daily Challenge
    GoRoute(
      name: Names.dailyChallenge,
      path: Routes.dailyChallenge,
      builder: (context, state) => const DailyChallengeView(),
    ),
  ],
);
