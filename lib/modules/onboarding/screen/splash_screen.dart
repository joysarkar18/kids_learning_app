import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/onboarding/data/repo/route_gaurd.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// 1. Add SingleTickerProviderStateMixin for animations
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _loaderFadeAnimation;
  late Animation<Offset> _loaderSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkLanguageAndNavigate();
  }

  void _setupAnimations() {
    // Initialize controller for entrance animations (runs for 1.5 seconds total)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // --- Text Animation (Starts early, finishes early) ---
    // Interval(0.2, 0.7) means it starts at 20% of duration and ends at 70%
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    // Slide up with a slight bounce (easeOutBack)
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
          ),
        );

    // --- Loader Animation (Starts later, finishes later) ---
    // Interval(0.5, 1.0) starts halfway through
    _loaderFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _loaderSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // Start the animations
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLanguageAndNavigate() async {
    // 2. FIXED TYPO: Changed 1202 seconds to 3 seconds for realistic testing
    await Future.delayed(const Duration(seconds: 3));

    final needsLanguage = await RouteGuard.needsLanguageSelection();

    if (!mounted) return;

    if (needsLanguage) {
      context.goNamed(Names.language);
    } else {
      context.goNamed(Names.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Made colors slightly brighter for a more playful look
            colors: [Color(0xFFFFF0D4), Color(0xFFD9F0FF), Color(0xFFFFD9EA)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // The Lottie animation handles its own entrance nicely, so we leave it as is.
              Lottie.asset(
                Assets.animationsSplashAnimation,
                width: 300.w,
                // Optional: ensure it plays smoothly
                options: LottieOptions(enableMergePaths: true),
              ),

              SizedBox(height: 20.h),

              // 3. Wrap Text with Fade and Slide Transitions
              FadeTransition(
                opacity: _textFadeAnimation,
                child: SlideTransition(
                  position: _textSlideAnimation,
                  child: Text(
                    'Kids Learning Bangla',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5C4BDB),
                      // Added slight shadow for depth
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const Spacer(),

              // 4. Wrap Loader with Fade and Slide Transitions
              FadeTransition(
                opacity: _loaderFadeAnimation,
                child: SlideTransition(
                  position: _loaderSlideAnimation,
                  child: Container(
                    // Wrapped in a container to give the loader a background pill shape
                    padding: EdgeInsets.all(12.w),

                    child: const CircularProgressIndicator(
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5C4BDB),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }
}
