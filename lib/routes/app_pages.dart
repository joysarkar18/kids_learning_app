import 'package:kids_learning/modules/drawing/screen/drawing_view.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_view.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_wrapper.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_wrapper.dart';
import 'package:kids_learning/modules/sothik_uttor/screen/sothik_uttor_wrapper.dart';
import 'package:kids_learning/modules/onboarding/screen/language_selection_screen.dart';
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
  ],
);
