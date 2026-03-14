import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/services/review_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _canShowReview = false;

  @override
  void initState() {
    super.initState();
    _checkReviewAvailability();
  }

  Future<void> _checkReviewAvailability() async {
    final shouldShow = await ReviewService.instance.shouldShowReview();
    if (mounted) {
      setState(() => _canShowReview = shouldShow);
    }
  }

  Future<void> _showReviewDialog() async {
    await ReviewService.instance.markAsPrompted();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B7A40), Color(0xFF0E4A2A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Icon(Icons.star_rate_rounded, size: 64, color: Color(0xFFFFD700)),
              SizedBox(height: 16),
              Text(
                'Enjoying the app?',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Rate us to help other parents discover this app!',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 14, color: Colors.white70),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () async {
                      await ReviewService.instance.markAsDismissed();
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text(
                      'Later',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await ReviewService.instance.markAsCompleted();
                      if (mounted) Navigator.pop(context);
                      // TODO: Open Play Store/App Store review
                      // For now, just mark as completed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFD700),
                      foregroundColor: Color(0xFF0A1628),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Rate Now',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        width: 1.sw,
        height: 1.sh,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B7A40).withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.settings_rounded,
                  size: 60.sp,
                  color: const Color(0xFFFFD700),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                l10n?.settings ?? 'Settings',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n?.settingsSubtitle ?? 'Coming Soon!',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 32.h),
              // Rate Us button (only shown when review is available)
              if (_canShowReview)
                ElevatedButton.icon(
                  onPressed: _showReviewDialog,
                  icon: Icon(Icons.star_rate, color: Color(0xFF0A1628)),
                  label: Text(
                    'Rate Us',
                    style: GoogleFonts.lato(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFD700),
                    foregroundColor: Color(0xFF0A1628),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
