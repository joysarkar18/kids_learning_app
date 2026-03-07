import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class StorySelectionScreen extends StatefulWidget {
  const StorySelectionScreen({super.key});

  @override
  State<StorySelectionScreen> createState() => _StorySelectionScreenState();
}

class _StorySelectionScreenState extends State<StorySelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 1.sh,
        width: 1.sw,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a2a6c), Color(0xFF2a4d8f), Color(0xFF3d6cb5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: Center(child: _buildComingSoonContent())),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Coming Soon badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                '⏳ Coming Soon',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1a2a6c),
                ),
              ),
            ),
            SizedBox(height: 40.h),

            // Main title
            Text(
              'Nurture Your Child\'s\nImagination!',
              textAlign: TextAlign.center,
              style: GoogleFonts.bubblegumSans(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            SizedBox(height: 24.h),

            // Brainrot message
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '🚫 No Brainrot Videos!',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Help your kids develop creativity and imagination through carefully crafted stories instead of mindless internet videos.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 14.sp,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // Positive message
            Text(
              '✨ Build Imagination Power ✨',
              style: GoogleFonts.bubblegumSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF98FB98),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Our stories are designed to spark creativity,\nencourage critical thinking, and inspire young minds to dream big!',
              textAlign: TextAlign.center,
              style: GoogleFonts.bubblegumSans(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
