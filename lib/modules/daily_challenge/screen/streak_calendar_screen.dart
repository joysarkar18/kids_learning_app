import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kids_learning/l10n/app_localizations.dart';

/// A beautiful calendar screen showing daily challenge completion history
class StreakCalendarScreen extends StatelessWidget {
  final List<String> completedDates;
  final int currentStreak;
  final int longestStreak;
  final int totalStars;

  const StreakCalendarScreen({
    super.key,
    required this.completedDates,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalStars,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isBn ? 'তোমার অগ্রগতি' : 'Your Progress',
          style: GoogleFonts.bubblegumSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBigStat(
                      icon: Icons.local_fire_department_rounded,
                      value: '$currentStreak',
                      label: isBn ? 'বর্তমান ধারা' : 'Current Streak',
                      color: const Color(0xFFFF6B35),
                    ),
                    _buildBigStat(
                      icon: Icons.emoji_events_rounded,
                      value: '$longestStreak',
                      label: isBn ? 'সেরা ধারা' : 'Best Streak',
                      color: const Color(0xFFFFD700),
                    ),
                    _buildBigStat(
                      icon: Icons.star_rounded,
                      value: '$totalStars',
                      label: isBn ? 'মোট তারা' : 'Total Stars',
                      color: const Color(0xFF7CFF6B),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Calendar widget
                StreakCalendarWidget(
                  completedDates: completedDates,
                  currentStreak: currentStreak,
                  longestStreak: longestStreak,
                ),

                SizedBox(height: 24.h),

                // Motivational message
                _buildMotivationalMessage(l10n, isBn),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBigStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Icon(icon, color: color, size: 32.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.bubblegumSans(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.bubblegumSans(
            fontSize: 11.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalMessage(AppLocalizations? l10n, bool isBn) {
    final message = currentStreak >= 7
        ? isBn
              ? 'চমৎকার! তুমি তো একজন চ্যাম্পিয়ন! 🏆'
              : 'Amazing! You\'re on fire! Keep it up! 🏆'
        : currentStreak >= 3
        ? isBn
              ? 'দারুণ চলছ! এমনই চালিয়ে যাও! 💪'
              : 'Great job! Keep the momentum going! 💪'
        : isBn
        ? 'শুরুটা ভালো হয়েছে! প্রতিদিন চেষ্টা চালিয়ে যাও! ⭐'
        : 'Good start! Keep practicing daily! ⭐';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7CFF6B).withValues(alpha: 0.2),
            const Color(0xFF28A060).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7CFF6B).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            currentStreak >= 7
                ? Icons.emoji_events
                : currentStreak >= 3
                ? Icons.thumb_up
                : Icons.star,
            color: const Color(0xFF7CFF6B),
            size: 32.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendar widget showing monthly completion view
class StreakCalendarWidget extends StatelessWidget {
  final List<String> completedDates;
  final int currentStreak;
  final int longestStreak;

  const StreakCalendarWidget({
    super.key,
    required this.completedDates,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(currentMonth),
                style: GoogleFonts.bubblegumSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  _buildStatBadge(
                    icon: Icons.local_fire_department_rounded,
                    value: '$currentStreak',
                    label: 'Current',
                    color: const Color(0xFFFF6B35),
                  ),
                  SizedBox(width: 8.w),
                  _buildStatBadge(
                    icon: Icons.emoji_events_rounded,
                    value: '$longestStreak',
                    label: 'Best',
                    color: const Color(0xFFFFD700),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => SizedBox(
                    width: 40.w,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 8.h),

          // Calendar grid
          _buildCalendarGrid(now),

          // Legend
          SizedBox(height: 16.h),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.bubblegumSans(
                  fontSize: 9.sp,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime now) {
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final days = <Widget>[];

    // Add empty cells for days before the first of the month
    for (int i = 0; i < startingWeekday; i++) {
      days.add(SizedBox(width: 40.w, height: 40.w));
    }

    // Add day cells
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final dateStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, day));
      final isCompleted = completedDates.contains(dateStr);
      final isToday = day == now.day;

      days.add(
        _buildDayCell(day: day, isCompleted: isCompleted, isToday: isToday),
      );
    }

    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: days
          .map((day) => SizedBox(width: 40.w, height: 40.w, child: day))
          .toList(),
    );
  }

  Widget _buildDayCell({
    required int day,
    required bool isCompleted,
    required bool isToday,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF7CFF6B).withValues(alpha: 0.3)
            : isToday
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? const Color(0xFFFFD700)
              : isCompleted
              ? const Color(0xFF7CFF6B).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: isToday ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isCompleted
                    ? const Color(0xFF7CFF6B)
                    : isToday
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(color: const Color(0xFF7CFF6B), label: 'Completed'),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isDot = false,
  }) {
    return Row(
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: isDot ? color : color.withValues(alpha: 0.3),
            borderRadius: isDot
                ? BorderRadius.circular(8)
                : BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          label,
          style: GoogleFonts.bubblegumSans(
            fontSize: 12.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
