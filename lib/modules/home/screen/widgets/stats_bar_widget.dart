import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

class StatsBarWidget extends StatelessWidget {
  const StatsBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DailyChallengeService.instance;
    final progress = service.progress;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(top: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stars badge
            _Badge3D(
              icon: Icons.star_rounded,
              value: '${progress.totalStars}',
              gradientColors: const [Color(0xFFFFC107), Color(0xFFFF9800)],
              shadowColor: const Color(0xFFE65100),
            ),
            SizedBox(width: 10.w),
            // Streak badge
            _Badge3D(
              icon: Icons.local_fire_department_rounded,
              value: '${progress.currentStreak}',
              gradientColors: const [Color(0xFFFF5722), Color(0xFFE91E63)],
              shadowColor: const Color(0xFFAD1457),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge3D extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<Color> gradientColors;
  final Color shadowColor;

  const _Badge3D({
    required this.icon,
    required this.value,
    required this.gradientColors,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: Stack(
        children: [
          // 3D shadow layer (peeking out at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 28.h,
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Main badge (sits on top of shadow)
          Container(
            height: 28.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  value,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
