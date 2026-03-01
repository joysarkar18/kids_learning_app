import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';

/// Wraps a child widget and shows a snackbar when a daily challenge
/// mission is completed. Only active when [enabled] is true (i.e. the
/// module was launched from the Daily Challenge screen).
class DailyChallengeSnackbarListener extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const DailyChallengeSnackbarListener({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  State<DailyChallengeSnackbarListener> createState() =>
      _DailyChallengeSnackbarListenerState();
}

class _DailyChallengeSnackbarListenerState
    extends State<DailyChallengeSnackbarListener> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _subscription =
          DailyChallengeService.instance.onMissionCompleted.listen(_onComplete);
    }
  }

  void _onComplete(String missionTitle) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF28A060),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                l10n?.missionComplete ?? 'Mission Complete!',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.star_rounded, color: const Color(0xFFFFD700), size: 20.sp),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
