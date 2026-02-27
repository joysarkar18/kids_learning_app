import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/daily_challenge/bloc/daily_challenge_bloc.dart';
import 'package:kids_learning/modules/daily_challenge/bloc/daily_challenge_event.dart';
import 'package:kids_learning/modules/daily_challenge/bloc/daily_challenge_state.dart';
import 'package:kids_learning/modules/daily_challenge/data/models/daily_mission_model.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';

class DailyChallengeView extends StatefulWidget {
  const DailyChallengeView({super.key});

  @override
  State<DailyChallengeView> createState() => _DailyChallengeViewState();
}

class _DailyChallengeViewState extends State<DailyChallengeView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return BlocProvider(
      create: (_) => DailyChallengeBloc()..add(LoadDailyChallenge()),
      child: BlocConsumer<DailyChallengeBloc, DailyChallengeState>(
        listener: (context, state) {
          if (state is DailyChallengeLoaded && state.justCompletedAll) {
            _confettiController.play();
          }
        },
        builder: (context, state) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A1628),
                    Color(0xFF0D2137),
                    Color(0xFF0B3328),
                    Color(0xFF0E4A2A),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  SafeArea(
                    child: _buildBody(state, l10n, isBn),
                  ),
                  // Confetti overlay
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      maxBlastForce: 20,
                      minBlastForce: 5,
                      gravity: 0.2,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFF7CFF6B),
                        Color(0xFFFF6B6B),
                        Color(0xFF80D8FF),
                        Color(0xFFE040FB),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      DailyChallengeState state, AppLocalizations? l10n, bool isBn) {
    if (state is DailyChallengeLoading || state is DailyChallengeInitial) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (state is DailyChallengeError) {
      return Center(
        child: Text(
          state.message,
          style: GoogleFonts.bubblegumSans(color: Colors.white, fontSize: 18.sp),
        ),
      );
    }

    if (state is! DailyChallengeLoaded) return const SizedBox.shrink();

    final challenge = state.challenge;
    final progress = state.progress;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          SizedBox(height: 10.h),

          // Title
          Text(
            l10n?.todaysMissions ?? "Today's Missions",
            style: GoogleFonts.bubblegumSans(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: const Color(0xFF7CFF6B).withValues(alpha: 0.5),
                  blurRadius: 16,
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Streak & Stars row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFF6B35),
                value: '${progress.currentStreak}',
                label: l10n?.streak ?? 'Streak',
              ),
              SizedBox(width: 24.w),
              _buildStatChip(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFD700),
                value: '${progress.totalStars}',
                label: l10n?.stars ?? 'Stars',
              ),
            ],
          ),

          SizedBox(height: 24.h),

          // Mission cards
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(bottom: 20.h),
              itemCount: challenge.missions.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                return _MissionCard(
                  mission: challenge.missions[index],
                  isBn: isBn,
                  onGoPressed: () =>
                      _navigateToModule(challenge.missions[index].moduleKey),
                );
              },
            ),
          ),

          // Completion banner
          if (challenge.isAllCompleted)
            Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7CFF6B), Color(0xFF28A060)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7CFF6B).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    l10n?.allMissionsComplete ??
                        'All missions complete! +3',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.star_rounded,
                      color: const Color(0xFFFFD700), size: 20.sp),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22.sp),
          SizedBox(width: 6.w),
          Text(
            value,
            style: GoogleFonts.bubblegumSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.bubblegumSans(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToModule(String moduleKey) {
    final routeMap = {
      'bornomala': Names.bornomala,
      'alphabate': Names.alphabate,
      'sothik_uttor': Names.sothikUttor,
      'gonit': Names.ganitPlay,
      'bangla_sonkha': Names.banglaSonkha,
      'english_sonkha': Names.englishSonkha,
      'drawing': Names.drawing,
      'namota': Names.namota,
    };

    final routeName = routeMap[moduleKey];
    if (routeName != null) {
      context.pushNamed(routeName);
    }
  }
}

// ─── Mission Card Widget ─────────────────────────────────────────────
class _MissionCard extends StatelessWidget {
  final DailyMission mission;
  final bool isBn;
  final VoidCallback onGoPressed;

  const _MissionCard({
    required this.mission,
    required this.isBn,
    required this.onGoPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = isBn ? mission.titleBn : mission.titleEn;
    final color = _moduleColor(mission.moduleKey);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: mission.isCompleted
              ? const Color(0xFF7CFF6B).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Module icon
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                _moduleIcon(mission.moduleKey),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: 14.w),

          // Title + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: mission.progressFraction,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mission.isCompleted
                          ? const Color(0xFF7CFF6B)
                          : color,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${mission.currentCount}/${mission.targetCount}',
                  style: GoogleFonts.bubblegumSans(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          // Go button or checkmark
          if (mission.isCompleted)
            Container(
              width: 44.w,
              height: 44.w,
              decoration: const BoxDecoration(
                color: Color(0xFF7CFF6B),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 24.sp),
            )
          else
            UniversalGamingButton(
              onPressed: onGoPressed,
              width: 70.w,
              height: 38,
              borderRadius: 19,
              backgroundColor: color,
              shadowDepth: 3,
              text: l10n?.goButton ?? 'Go',
              textStyle: GoogleFonts.bubblegumSans(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _moduleIcon(String moduleKey) {
    const map = {
      'bornomala': Assets.imagesBengaliIcon,
      'alphabate': Assets.imagesEnglishIcon,
      'sothik_uttor': Assets.imagesGkIcon,
      'gonit': Assets.imagesGonit,
      'bangla_sonkha': Assets.imagesBanglaSonkha,
      'english_sonkha': Assets.imagesEngrejiSonkha,
      'drawing': Assets.imagesDrawingIcon,
      'namota': Assets.imagesNamota,
    };
    return map[moduleKey] ?? Assets.imagesGkIcon;
  }

  Color _moduleColor(String moduleKey) {
    const map = {
      'bornomala': Color(0xFFE91E63),
      'alphabate': Color(0xFF2196F3),
      'sothik_uttor': Color(0xFFFF9800),
      'gonit': Color(0xFF9C27B0),
      'bangla_sonkha': Color(0xFFFF5722),
      'english_sonkha': Color(0xFF00BCD4),
      'drawing': Color(0xFF4CAF50),
      'namota': Color(0xFF795548),
    };
    return map[moduleKey] ?? const Color(0xFF5C4BDB);
  }
}
