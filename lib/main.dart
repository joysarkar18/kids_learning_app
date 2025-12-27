import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_bloc.dart';
import 'package:kids_learning/routes/app_pages.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/services/locale_service.dart';
import 'package:kids_learning/services/snackbar_service.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AudioService().init();

  // Load saved language preference
  final savedLanguage = await LocaleService.getSavedLanguagePreference();

  runApp(MyApp(initialLocale: savedLanguage));
}

class MyApp extends StatefulWidget {
  final String? initialLocale;

  const MyApp({super.key, this.initialLocale});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();

    // Set initial locale from saved preference or default to English
    _locale = widget.initialLocale != null
        ? Locale(widget.initialLocale!)
        : const Locale('en');
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
        // Localization support
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('bn'), // Bengali
        ],
        routerConfig: router,
        builder: (context, child) {
          // Initialize SnackbarService with context here
          SnackbarService.initialize(context);

          return MultiBlocProvider(
            providers: [BlocProvider(create: (_) => OnboardingBloc())],
            child: child!,
          );
        },
      ),
    );
  }
}
