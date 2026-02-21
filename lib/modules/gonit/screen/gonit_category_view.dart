import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

class GanitCategoryScreen extends StatelessWidget {
  const GanitCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SizedBox(
          height: 1.sh,
          width: 1.sw,
          child: Stack(
            children: [
              // Background
              Image.asset(
                Assets.imagesGkBg,
                fit: BoxFit.cover,
                height: 1.sh,
                width: 1.sw,
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),

                      // Title
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'গণিত খেলা বাছো!',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Category buttons grid
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                          childAspectRatio: 1.4,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _CategoryButton(
                              label: 'যোগ/বিয়োগ',
                              icon: Icons.calculate_rounded,
                              color: const Color(0xFF4CAF50),
                              onPressed: () => _navigateToPlay(context, 'arithmetic'),
                            ),
                            _CategoryButton(
                              label: 'গোনা',
                              icon: Icons.format_list_numbered_rounded,
                              color: const Color(0xFF2196F3),
                              onPressed: () => _navigateToPlay(context, 'counting'),
                            ),
                            _CategoryButton(
                              label: 'তুলনা',
                              icon: Icons.compare_arrows_rounded,
                              color: const Color(0xFFFF9800),
                              onPressed: () => _navigateToPlay(context, 'comparison'),
                            ),
                            _CategoryButton(
                              label: 'ধারা',
                              icon: Icons.linear_scale_rounded,
                              color: const Color(0xFF9C27B0),
                              onPressed: () => _navigateToPlay(context, 'missing_number'),
                            ),
                            _CategoryButton(
                              label: 'শব্দ সমস্যা',
                              icon: Icons.menu_book_rounded,
                              color: const Color(0xFFE91E63),
                              onPressed: () => _navigateToPlay(context, 'word_problem'),
                            ),
                            _CategoryButton(
                              label: 'মিলাও',
                              icon: Icons.link_rounded,
                              color: const Color(0xFF00BCD4),
                              onPressed: () => _navigateToPlay(context, 'matching'),
                            ),
                            _CategoryButton(
                              label: 'সাজাও',
                              icon: Icons.sort_rounded,
                              color: const Color(0xFF795548),
                              onPressed: () => _navigateToPlay(context, 'ordering'),
                            ),
                          ],
                        ),
                      ),

                      // Mix All button
                      Padding(
                        padding: EdgeInsets.only(bottom: 40.h),
                        child: UniversalGamingButton(
                          onPressed: () => _navigateToPlay(context, null),
                          text: 'মিশ্র',
                          icon: Icons.shuffle_rounded,
                          width: 0.6.sw,
                          height: 55.h,
                          backgroundColor: const Color(0xFFFF5722),
                          textStyle: GoogleFonts.hindSiliguri(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          iconColor: Colors.white,
                          iconSize: 28.sp,
                          borderRadius: 16.r,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w, top: 15.h),
                  child: GamingImageButton(
                    width: 0.18.sw,
                    imagePath: Assets.imagesCrossIcon,
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPlay(BuildContext context, String? type) {
    context.pushNamed(Names.ganitPlay, extra: type);
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalGamingButton(
      onPressed: onPressed,
      icon: icon,
      text: label,
      backgroundColor: color,
      direction: Axis.vertical,
      spacing: 4,
      iconColor: Colors.white,
      iconSize: 32.sp,
      borderRadius: 16.r,
      textStyle: GoogleFonts.hindSiliguri(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
