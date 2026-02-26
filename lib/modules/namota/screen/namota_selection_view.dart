import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/namota/bloc/namota_state.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

class NamotaSelectionScreen extends StatelessWidget {
  const NamotaSelectionScreen({super.key});

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
              // Jungle gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 3, 4, 3),
                      Color.fromARGB(255, 7, 8, 7),
                      Color.fromARGB(255, 3, 3, 3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Background image overlay
              Opacity(
                opacity: 0.5,
                child: Image.asset(
                  Assets.imagesGkBg,
                  fit: BoxFit.cover,
                  height: 1.sh,
                  width: 1.sw,
                ),
              ),

              // Top vine decoration
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(1.sw, 100.h),
                  painter: _VinePainter(),
                ),
              ),

              // Bottom grass decoration
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(1.sw, 60.h),
                  painter: _GrassPainter(),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 50.h),

                    // Title — wooden sign style
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 32.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6D4C41),
                            Color(0xFF8D6E63),
                            Color(0xFF6D4C41),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFF4E342E),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🌿 ', style: TextStyle(fontSize: 20.sp)),
                          Text(
                            'নামতা বাছো!',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFF8E1),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(1, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          Text(' 🌿', style: TextStyle(fontSize: 20.sp)),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Grid
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 0.95,
                              ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: 20,
                          itemBuilder: (context, index) {
                            final tableNum = index + 1;
                            return _JungleCard(
                              tableNumber: tableNum,
                              onPressed: () {
                                context.pushNamed(
                                  Names.namotaPractice,
                                  extra: tableNum,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
}

// ============ Jungle Card ============

class _JungleCard extends StatefulWidget {
  final int tableNumber;
  final VoidCallback onPressed;

  const _JungleCard({required this.tableNumber, required this.onPressed});

  @override
  State<_JungleCard> createState() => _JungleCardState();
}

class _JungleCardState extends State<_JungleCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  // Each number gets a unique animal
  static const _animals = [
    '🐒',
    '🦁',
    '🐘',
    '🦜',
    '🐍',
    '🦋',
    '🐸',
    '🦎',
    '🐢',
    '🦩',
    '🐆',
    '🦧',
    '🐊',
    '🦚',
    '🐝',
    '🦥',
    '🐞',
    '🦔',
    '🐠',
    '🦖',
  ];

  static const _cardStyles = [
    // [bgGradientStart, bgGradientEnd, borderColor]
    [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF1B5E20)], // Forest green
    [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF004D40)], // Deep teal
    [Color(0xFF827717), Color(0xFF9E9D24), Color(0xFF616116)], // Olive
    [Color(0xFF4E342E), Color(0xFF6D4C41), Color(0xFF3E2723)], // Bark brown
    [Color(0xFFE65100), Color(0xFFEF6C00), Color(0xFFBF360C)], // Sunset orange
    [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF0D47A1)], // River blue
    [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFF4A148C)], // Orchid purple
    [Color(0xFFC62828), Color(0xFFE53935), Color(0xFFB71C1C)], // Berry red
    [Color(0xFF00838F), Color(0xFF0097A7), Color(0xFF006064)], // Lagoon
    [Color(0xFFAD1457), Color(0xFFD81B60), Color(0xFF880E4F)], // Tropical pink
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 25),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
        );

    // Stagger the initial bounce
    Future.delayed(Duration(milliseconds: 80 * widget.tableNumber), () {
      if (mounted) _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _cardStyles[(widget.tableNumber - 1) % _cardStyles.length];
    final animal = _animals[(widget.tableNumber - 1) % _animals.length];
    final shadowColor = HSLColor.fromColor(style[0])
        .withLightness(
          (HSLColor.fromColor(style[0]).lightness - 0.18).clamp(0.0, 1.0),
        )
        .toColor();

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnim.value + (_pressed ? 5 : 0)),
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.7),
                offset: Offset(0, _pressed ? 2 : 6),
                blurRadius: _pressed ? 1 : 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [style[0], style[1]],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: style[2], width: 2.5),
              ),
              child: Stack(
                children: [
                  // Leaf pattern overlay
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Text('🍃', style: TextStyle(fontSize: 28.sp)),
                    ),
                  ),

                  // Animal in top-left
                  Positioned(
                    top: 4.h,
                    left: 6.w,
                    child: Text(animal, style: TextStyle(fontSize: 18.sp)),
                  ),

                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 4.h),
                        // Number in a circular badge
                        Container(
                          width: 52.w,
                          height: 52.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              toBengali(widget.tableNumber),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Label
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'এর নামতা',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ Custom Painters ============

class _VinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.4);

    // Wavy bottom edge
    for (double x = size.width; x >= 0; x -= 30) {
      path.quadraticBezierTo(
        x - 15,
        size.height * (0.4 + 0.3 * sin(x * 0.05)),
        x - 30,
        size.height * 0.4,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF33691E).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.5);

    // Wavy grass top edge
    for (double x = size.width; x >= 0; x -= 20) {
      path.quadraticBezierTo(
        x - 10,
        size.height * (0.5 - 0.4 * sin(x * 0.08)),
        x - 20,
        size.height * 0.5,
      );
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
