import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart'; // Added for navigation
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/onboarding/data/models/language_model.dart';
import 'package:kids_learning/modules/onboarding/screen/widgets/language_card.dart';
import 'package:kids_learning/routes/app_routes.dart'; // Added for Names
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/locale_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_button.dart';

class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen>
    with SingleTickerProviderStateMixin {
  int? selectedLanguageIndex;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<LanguageModel> languages = [
    LanguageModel(
      name: "English",
      nativeName: "English",
      code: "en",
      flagEmoji: Assets.iconsEnglishIcon,
      backgroundColor: const Color(0xFFE5F3FF),
    ),
    LanguageModel(
      name: "Bengali",
      nativeName: "বাংলা",
      code: "bn",
      flagEmoji: Assets.iconsBanglaIcon,
      backgroundColor: const Color(0xFFE5FFE5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedLanguage();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguageCode = await LocaleService.getSavedLanguagePreference();

    if (savedLanguageCode != null) {
      final index = languages.indexWhere(
        (lang) => lang.code == savedLanguageCode,
      );
      if (index != -1) {
        setState(() {
          selectedLanguageIndex = index;
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- Helper to handle language change immediately on tap ---
  Future<void> _handleLanguageSelection(int index) async {
    // If clicking same language, do nothing
    if (selectedLanguageIndex == index) return;

    setState(() {
      selectedLanguageIndex = index;
    });

    final selectedLanguage = languages[index];
    LoggerService.logInfo(
      "Changing Language to: ${selectedLanguage.name} (${selectedLanguage.code})",
    );

    // Change language immediately
    await LocaleService.changeLanguage(context, selectedLanguage.code);
  }

  @override
  Widget build(BuildContext context) {
    // Note: When LocaleService changes language, the app rebuilds.
    // Ensure AppLocalizations is not null.
    final l10n = AppLocalizations.of(context);

    // Safety check if l10n is not ready yet
    if (isLoading || l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9E6), Color(0xFFE6F4FF), Color(0xFFFFE6F0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header
                    _buildHeader(l10n),

                    SizedBox(height: 50.h),

                    // Language Cards
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < languages.length; i++) ...[
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 500 + (i * 200),
                                ),
                                curve: Curves.easeOutBack, // The bouncy curve
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale:
                                        value, // Scale can overshoot > 1.0 (Good!)
                                    child: Opacity(
                                      // FIX: Clamp value so it never exceeds 1.0
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: LanguageCard(
                                  language: languages[i],
                                  isSelected: selectedLanguageIndex == i,
                                  onTap: () => _handleLanguageSelection(i),
                                ),
                              ),
                              if (i < languages.length - 1)
                                SizedBox(height: 20.h),
                            ],
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Continue Button
                    AnimatedOpacity(
                      opacity: selectedLanguageIndex != null ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: UniversalGamingButton(
                        onPressed: selectedLanguageIndex != null
                            ? () {
                                // Just navigate to the next screen
                                context.goNamed(Names.onboarding);
                              }
                            : () {}, // Disable click if no selection
                        width: 320.w,
                        height: 50,
                        text: l10n.letsGo,
                        textStyle: GoogleFonts.bubblegumSans(
                          color: AppColors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        // Decorative Icon
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5C4BDB).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text('🌍', style: TextStyle(fontSize: 40.sp)),
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          l10n.chooseLanguage,
          style: GoogleFonts.bubblegumSans(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5C4BDB),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.selectPreferred,
          style: GoogleFonts.bubblegumSans(
            fontSize: 16.sp,
            color: const Color(0xFF9E9E9E),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
