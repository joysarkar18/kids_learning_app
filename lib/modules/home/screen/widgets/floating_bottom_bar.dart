import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

class FloatingBottomBar extends StatelessWidget {
  const FloatingBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = DailyChallengeService.instance;
    final challenge = service.todayChallenge;
    final completed = challenge?.starsEarned ?? 0;
    final total = challenge?.missions.length ?? 5;
    final allDone = challenge?.isAllCompleted == true;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h, left: 16.w, right: 16.w),
        child: SizedBox(
          height: 92.h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // === BAR 3D SHADOW LAYER ===
              Container(
                height: 66.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B0764),
                  borderRadius: BorderRadius.circular(33),
                ),
              ),

              // === MAIN BAR BODY (elevated above shadow) ===
              Positioned(
                bottom: 6.h,
                left: 0,
                right: 0,
                child: Container(
                  height: 66.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(33),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Left: Mini Games
                      Expanded(
                        child: _Bar3DItem(
                          icon: Icons.sports_esports_rounded,
                          label: l10n?.miniGames ?? 'Mini Games',
                          buttonGradient: const [
                            Color(0xFFFBBF24),
                            Color(0xFFF59E0B),
                          ],
                          shadowColor: const Color(0xFFB45309),
                          onTap: () => context.pushNamed(Names.miniGames),
                        ),
                      ),
                      // Spacer for center button
                      SizedBox(width: 84.w),
                      // Right: Empty (Settings moved to sun menu)
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),

              // === CENTER: Daily Challenge 3D Button (protruding) ===
              Positioned(
                top: 0,
                child: _DailyChallenge3DButton(
                  completed: completed,
                  total: total,
                  allDone: allDone,
                  onTap: () => context.pushNamed(Names.dailyChallenge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single side item in the bar with a 3D circular icon button.
class _Bar3DItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> buttonGradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _Bar3DItem({
    required this.icon,
    required this.label,
    required this.buttonGradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D icon circle
          SizedBox(
            width: 42.w,
            height: 46.w,
            child: Stack(
              children: [
                // Shadow circle
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 42.w,
                    decoration: BoxDecoration(
                      color: shadowColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Main icon circle
                Container(
                  height: 42.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: buttonGradient,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.bubblegumSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// The large protruding center button for Daily Challenge with 3D depth.
class _DailyChallenge3DButton extends StatelessWidget {
  final int completed;
  final int total;
  final bool allDone;
  final VoidCallback onTap;

  const _DailyChallenge3DButton({
    required this.completed,
    required this.total,
    required this.allDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mainColors = allDone
        ? const [Color(0xFFFBBF24), Color(0xFFF59E0B)]
        : const [Color(0xFF34D399), Color(0xFF10B981)];
    final shadow = allDone ? const Color(0xFFB45309) : const Color(0xFF047857);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 78.w,
        height: 86.w,
        child: Stack(
          children: [
            // 3D shadow circle
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 78.w,
                decoration: BoxDecoration(
                  color: shadow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main circle
            Container(
              height: 78.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: mainColors,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    allDone
                        ? Icons.check_circle_rounded
                        : Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                  Text(
                    '$completed/$total',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
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
      ),
    );
  }
}
