import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/home/screen/widgets/friend_greeting_widget.dart';
import 'package:kids_learning/modules/home/screen/widgets/sun_menu_widget.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VoidCallback? _challengeListener;

  @override
  void initState() {
    super.initState();
    _challengeListener = () {
      if (mounted) setState(() {});
    };
    DailyChallengeService.instance.addListener(_challengeListener!);
  }

  @override
  void dispose() {
    if (_challengeListener != null) {
      DailyChallengeService.instance.removeListener(_challengeListener!);
    }
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

            // Sun menu in top right
            SunMenuWidget(),

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
                            context.pushNamed(Names.englishSonkha);
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
                    _StatBadge(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF6B35),
                      value:
                          DailyChallengeService.instance.progress.currentStreak,
                    ),
                    const Spacer(),
                    _DailyChallengeButton(),
                    const Spacer(),

                    _StatBadge(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFFD700),
                      value: DailyChallengeService.instance.progress.totalStars,
                    ),
                    SizedBox(width: 10.w),
                  ],
                ),
              ),
            ),
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
