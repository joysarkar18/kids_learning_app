import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/home/screen/widgets/friend_greeting_widget.dart';
import 'package:kids_learning/modules/home/screen/widgets/sun_menu_widget.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/routes/app_pages.dart';
import 'package:kids_learning/services/app_update_service.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  VoidCallback? _challengeListener;

  void _showStreakCalendar() {
    final service = DailyChallengeService.instance;
    context.pushNamed(
      Names.streakCalendar,
      extra: {
        'completedDates': service.completedDates,
        'currentStreak': service.progress.currentStreak,
        'longestStreak': service.progress.longestStreak,
        'totalStars': service.progress.totalStars,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _challengeListener = () {
      if (mounted) setState(() {});
    };
    DailyChallengeService.instance.addListener(_challengeListener!);
    // Re-initialize to fetch fresh data from Firestore (auth may not
    // have been ready during the initial main.dart initialization).
    DailyChallengeService.instance.initialize();
    // Start background music when entering home page
    AudioService().playBackgroundMusic();
    // Check for app updates
    _checkForUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    GlobalNavigation.instance.routeObserver
        .subscribe(this, ModalRoute.of(context)!);
  }

  /// Called when another route is pushed on top (leaving home)
  @override
  void didPushNext() {
    AudioService().stopBackgroundMusic();
  }

  /// Called when the pushed route is popped and home is visible again
  @override
  void didPopNext() {
    AudioService().playBackgroundMusic();
  }

  Future<void> _checkForUpdate() async {
    final result = await AppUpdateService.instance.checkUpdateRequired();
    if (!mounted) return;
    if (result.status == UpdateStatus.forceUpdateRequired ||
        result.status == UpdateStatus.updateAvailable) {
      final isForce = result.status == UpdateStatus.forceUpdateRequired;
      _showUpdateBottomSheet(isForce: isForce);
    }
  }

  void _showUpdateBottomSheet({required bool isForce}) {
    showModalBottomSheet(
      context: context,
      isDismissible: !isForce,
      enableDrag: !isForce,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PopScope(
        canPop: !isForce,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE082), Color(0xFFFFC107)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.system_update_rounded,
                size: 64.sp,
                color: const Color(0xFF5D4037),
              ),
              SizedBox(height: 16.h),
              Text(
                isForce ? 'Update Required!' : 'Update Available!',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4037),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                isForce
                    ? 'A new version is available. Please update to continue using the app.'
                    : 'A new version is available. Update now for the best experience!',
                textAlign: TextAlign.center,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  color: const Color(0xFF795548),
                ),
              ),
              SizedBox(height: 24.h),
              UniversalGamingButton(
                onPressed: _openStore,
                width: 200.w,
                height: 50,
                borderRadius: 25,
                backgroundColor: const Color(0xFF4CAF50),
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                ),
                icon: Icons.update_rounded,
                iconColor: Colors.white,
                text: 'Update Now',
                textStyle: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                shadowDepth: 4,
                borderWidth: 1.5,
                borderColor: Colors.white.withValues(alpha: 0.3),
              ),
              if (!isForce) ...[
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Later',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 14.sp,
                      color: const Color(0xFF795548),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.byteberg.kids_learning',
      );
    } else {
      // Replace with your actual App Store ID when available
      url = Uri.parse(
        'https://apps.apple.com/app/id_YOUR_APP_STORE_ID',
      );
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    GlobalNavigation.instance.routeObserver.unsubscribe(this);
    if (_challengeListener != null) {
      DailyChallengeService.instance.removeListener(_challengeListener!);
    }
    // Stop background music when leaving home page
    AudioService().stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 1.sh,
        width: 1.sw,
        child: Stack(
          children: [
            // Background image
            Image.asset(Assets.imagesHomeBg, fit: BoxFit.cover, height: 1.sh),

            // Friend greeting widget
            const FriendGreetingWidget(),

            // Bottom menu with subject buttons
            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10.w,
                  right: 10.w,
                  bottom: 100.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // First row: Bengali, English, GK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.iconsBornomalaIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.bornomala);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsAlphabateIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.alphabate);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsSadharonGyan,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.sothikUttor);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Second row: Bangla Sonkha, Chora, Drawing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.iconsBanglaSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.banglaSonkha);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsChoraIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.chora);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsAkaaki,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.drawing);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Third row: English Sonkha, Gonit, Namota
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.iconsEnglishSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.englishSonkha);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsGonit,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.ganitPlay);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsNamota,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.namota);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.iconsGolpo,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.stories);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsMiniGame,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.miniGames);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.iconsBanan,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.banan);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                  ],
                ),
              ),
            ),

            // Daily Challenge button at bottom center
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 30.h),
                child: Row(
                  children: [
                    SizedBox(width: 10.w),
                    InkWell(
                      onTap: _showStreakCalendar,
                      borderRadius: BorderRadius.circular(20),
                      child: _StatBadge(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF6B35),
                        value: DailyChallengeService
                            .instance
                            .progress
                            .currentStreak,
                      ),
                    ),
                    const Spacer(),
                    _DailyChallengeButton(),
                    const Spacer(),

                    InkWell(
                      onTap: () {
                        context.pushNamed(Names.redeemProducts);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: _StatBadge(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFFFD700),
                        value:
                            DailyChallengeService.instance.progress.totalStars,
                      ),
                    ),
                    SizedBox(width: 10.w),
                  ],
                ),
              ),
            ),

            // Sun menu button - always visible, opens overlay menu
            const SunMenuWidget(),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = DailyChallengeService.instance;
    final challenge = service.todayChallenge;
    final completed = challenge?.starsEarned ?? 0;
    final total = challenge?.missions.length ?? 5;
    final allDone = challenge?.isAllCompleted == true;

    return UniversalGamingButton(
      onPressed: () => context.pushNamed(Names.dailyChallenge),
      width: 200.w,
      height: 50,
      borderRadius: 25,
      backgroundColor: allDone
          ? const Color.fromARGB(255, 139, 74, 30)
          : const Color.fromARGB(255, 122, 84, 27),
      gradient: LinearGradient(
        colors: allDone
            ? [
                const Color.fromARGB(255, 160, 94, 40),
                const Color.fromARGB(255, 122, 85, 27),
              ]
            : [
                const Color.fromARGB(255, 122, 79, 27),
                const Color.fromARGB(255, 91, 65, 17),
              ],
      ),
      icon: allDone
          ? Icons.check_circle_rounded
          : Icons.local_fire_department_rounded,
      iconColor: allDone ? const Color(0xFF7CFF6B) : const Color(0xFFFFD700),
      text: '${l10n?.dailyChallenge ?? "Daily Challenge"} $completed/$total',
      textStyle: GoogleFonts.bubblegumSans(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      shadowDepth: 4,
      borderWidth: 1.5,
      borderColor: const Color.fromARGB(
        255,
        255,
        174,
        107,
      ).withValues(alpha: 0.3),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;

  const _StatBadge({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 88, 58, 22),
            Color.fromARGB(255, 78, 51, 17),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            '$value',
            style: GoogleFonts.bubblegumSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
