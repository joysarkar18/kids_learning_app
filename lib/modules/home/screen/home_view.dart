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
import 'package:kids_learning/widgets/gaming_image_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                    // Daily Challenge Banner
                    _DailyChallengeBanner(),

                    SizedBox(height: 20.h),

                    // First row: Bengali, English, GK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesBengaliIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.bornomala);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesEnglishIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.alphabate);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesGkIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.sothikUttor);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),

                    // Second row: Math, Chora, Drawing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesBanglaSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.banglaSonkha);
                          },
                        ),

                        GamingImageButton(
                          imagePath: Assets.imagesChoraIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.chora);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesDrawingIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.drawing);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Second row: Math, Chora, Drawing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesEngrejiSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.englishSonkha);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesGonit,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.ganitPlay);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesNamota,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.namota);
                          },
                        ),
                      ],
                    ),
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

class _DailyChallengeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = DailyChallengeService.instance;
    final challenge = service.todayChallenge;
    final progress = service.progress;
    final completed = challenge?.starsEarned ?? 0;

    return GestureDetector(
      onTap: () => context.pushNamed(Names.dailyChallenge),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B7A40), Color(0xFF0E4A2A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF7CFF6B).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E4A2A).withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Fire/star icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                progress.currentStreak > 0
                    ? Icons.local_fire_department_rounded
                    : Icons.star_rounded,
                color: progress.currentStreak > 0
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFFFFD700),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.dailyChallenge ?? 'Daily Challenge',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    l10n?.missionsProgress(completed) ??
                        '$completed/3 missions done',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 12.sp,
                      color: const Color(0xFFD4FFD0),
                    ),
                  ),
                ],
              ),
            ),
            // Progress dots
            Row(
              children: List.generate(3, (i) {
                final done = i < completed;
                return Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 6.w : 0),
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? const Color(0xFF7CFF6B)
                          : Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: done
                            ? const Color(0xFF7CFF6B)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: done
                        ? Icon(Icons.check, color: Colors.white, size: 10.sp)
                        : null,
                  ),
                );
              }),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
