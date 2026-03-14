import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/firebase_options.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_bloc.dart';
import 'package:kids_learning/routes/app_pages.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/services/locale_service.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/remote_config_service.dart';
import 'package:kids_learning/services/snackbar_service.dart';
import 'package:kids_learning/services/review_service.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await AudioService().init();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Crashlytics (disable in debug mode)
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      // Pass uncaught Flutter framework errors to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Set Crashlytics user identifier if already logged in
      if (AuthService.instance.isLoggedIn) {
        final user = AuthService.instance.currentUser;
        if (user != null) {
          await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
        }
      }

      final savedLanguage = await LocaleService.getSavedLanguagePreference();
      await RemoteConfigService().initialize();

      await DailyChallengeService.instance.initialize();
      runApp(MyApp(initialLocale: savedLanguage));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class MyApp extends StatefulWidget {
  final String? initialLocale;

  const MyApp({super.key, this.initialLocale});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late Locale _locale;
  bool _showReviewDialog = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _locale = widget.initialLocale != null
        ? Locale(widget.initialLocale!)
        : const Locale('en');

    _initializeReview();
  }

  Future<void> _initializeReview() async {
    // Increment launch count
    await ReviewService.instance.incrementLaunchCount();

    // Check if we should show review dialog
    final shouldShow = await ReviewService.instance.shouldShowReview();
    if (shouldShow && mounted) {
      setState(() => _showReviewDialog = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App goes to background
        AudioService().pause();
        break;

      case AppLifecycleState.resumed:
        // App comes back to foreground
        AudioService().resume();
        break;

      case AppLifecycleState.detached:
        AudioService().stop();
        break;
      case AppLifecycleState.hidden:
        // iOS only: App is not visible
        AudioService().pause();
        break;
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Kids Learning',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.baseColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.baseColor,
            primary: AppColors.primary1,
          ),
        ),
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('bn')],
        routerConfig: router,
        builder: (context, child) {
          SnackbarService.initialize(context);

          return MultiBlocProvider(
            providers: [BlocProvider(create: (_) => OnboardingBloc())],
            child: Stack(
              children: [
                child!,
                if (_showReviewDialog) _buildReviewDialog(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewDialog(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B7A40), Color(0xFF0E4A2A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Icon(Icons.star_rate_rounded, size: 64, color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text(
                'Enjoying the app?',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Rate us to help other parents discover this app!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      await ReviewService.instance.markAsDismissed();
                      setState(() => _showReviewDialog = false);
                    },
                    child: Text(
                      'Later',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await ReviewService.instance.markAsCompleted();
                      setState(() => _showReviewDialog = false);
                      // TODO: Open Play Store/App Store review
                      // For now, just mark as completed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFD700),
                      foregroundColor: Color(0xFF0A1628),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Rate Now',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
