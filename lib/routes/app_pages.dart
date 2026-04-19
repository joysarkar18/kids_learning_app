import 'package:kids_learning/modules/banan/screen/banan_view.dart';
import 'package:kids_learning/modules/drawing/screen/drawing_view.dart';
import 'package:kids_learning/modules/guided_drawing/screen/guided_drawing_screen.dart';
import 'package:kids_learning/modules/trace_color_game/screen/trace_color_screen.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_wrapper.dart';
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
import 'package:kids_learning/modules/daily_challenge/screen/redeem_products_view.dart';
import 'package:kids_learning/modules/daily_challenge/screen/address_form_view.dart';
import 'package:kids_learning/modules/daily_challenge/screen/my_redemptions_view.dart';
import 'package:kids_learning/modules/daily_challenge/screen/streak_calendar_screen.dart';
import 'package:kids_learning/modules/mini_games/screen/mini_games_view.dart';
import 'package:kids_learning/modules/mini_games/screen/mini_game_webview.dart';
import 'package:kids_learning/modules/namota/screen/namota_selection_view.dart';
import 'package:kids_learning/modules/namota/screen/namota_wrapper.dart';
import 'package:kids_learning/modules/sothik_uttor/screen/sothik_uttor_wrapper.dart';
import 'package:kids_learning/modules/onboarding/screen/language_selection_screen.dart';
import 'package:kids_learning/modules/onboarding/screen/login_screen.dart';
import 'package:kids_learning/modules/onboarding/screen/onboarding_view.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/analytics_service.dart';

// Screens
import 'package:kids_learning/modules/onboarding/screen/splash_screen.dart';
import 'package:kids_learning/modules/home/screen/home_view.dart';
import 'package:kids_learning/modules/stories/screen/story_selection_screen.dart';
import 'package:kids_learning/modules/stories/screen/story_reader_screen.dart';
import 'package:kids_learning/modules/stories/data/models/story_model.dart';

// Global Key for Context access if needed outside widgets
class GlobalNavigation {
  static final GlobalNavigation instance = GlobalNavigation._internal();
  GlobalNavigation._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();
}

final router = GoRouter(
  initialLocation: Routes.init, // Start at Splash
  navigatorKey: GlobalNavigation.instance.navigatorKey,
  observers: [
    AnalyticsService().observer, // Automatic screen view tracking
    GlobalNavigation.instance.routeObserver,
  ],
  routes: [
    GoRoute(
      name: Names.banan,
      path: Routes.banan,
      builder: (context, state) => const BananProblemScreen(),
    ),

    GoRoute(
      name: Names.drawing,
      path: Routes.drawing,
      builder: (context, state) => const DrawingScreen(),
    ),

    GoRoute(
      name: Names.guidedDrawing,
      path: Routes.guidedDrawing,
      builder: (context, state) => const GuidedDrawingScreen(),
    ),

    GoRoute(
      name: Names.traceColorGame,
      path: Routes.traceColorGame,
      builder: (context, state) => const TraceColorScreen(),
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

    // 6. Mini Games
    GoRoute(
      name: Names.miniGames,
      path: Routes.miniGames,
      builder: (context, state) => const MiniGamesScreen(),
    ),

    // 6.1 Mini Game WebView Player
    GoRoute(
      name: Names.miniGamePlay,
      path: Routes.miniGamePlay,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        return MiniGameWebViewScreen(
          name: data?['name'] ?? '',
          playUrl: data?['playUrl'] ?? '',
        );
      },
    ),

    // 7. Stories
    GoRoute(
      name: Names.stories,
      path: Routes.stories,
      builder: (context, state) => const StorySelectionScreen(),
    ),

    // 7.1 Story Reader
    GoRoute(
      name: Names.storyReader,
      path: Routes.storyReader,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;
        if (data == null || data['story'] == null) {
          return const StorySelectionScreen();
        }
        return StoryReaderScreen(story: data['story'] as StoryModel);
      },
    ),

    // 9. Redeem Products
    GoRoute(
      name: Names.redeemProducts,
      path: Routes.redeemProducts,
      builder: (context, state) => const RedeemProductsView(),
    ),

    // 10. Address Form for Redemption
    GoRoute(
      name: Names.addressForm,
      path: Routes.addressForm,
      builder: (context, state) {
        final productId = state.pathParameters['productId'] ?? '';
        return AddressFormView(productId: productId);
      },
    ),

    // 11. My Redemptions
    GoRoute(
      name: Names.myRedemptions,
      path: Routes.myRedemptions,
      builder: (context, state) => const MyRedemptionsView(),
    ),

    // 12. Streak Calendar
    GoRoute(
      name: Names.streakCalendar,
      path: Routes.streakCalendar,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final completedDates = extra?['completedDates'] as List? ?? [];
        return StreakCalendarScreen(
          completedDates: completedDates.cast<String>(),
          currentStreak: extra?['currentStreak'] as int? ?? 0,
          longestStreak: extra?['longestStreak'] as int? ?? 0,
          totalStars: extra?['totalStars'] as int? ?? 0,
        );
      },
    ),
  ],
);
