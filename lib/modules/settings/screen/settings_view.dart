import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            ],
          ),
        ),
      ),
    );
  }
}
