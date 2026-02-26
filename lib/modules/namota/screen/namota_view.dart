import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/services/audio_service.dart';

import '../bloc/namota_bloc.dart';
import '../bloc/namota_event.dart';
import '../bloc/namota_state.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class NamotaScreen extends StatefulWidget {
  const NamotaScreen({super.key});

  @override
  State<NamotaScreen> createState() => _NamotaScreenState();
}

class _NamotaScreenState extends State<NamotaScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _micRingController;
  late Animation<double> _micRingAnim;

  // Vibrant color palettes for each row (gradient start, gradient end, border)
  static const _rowStyles = [
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

  static const _rowEmojis = [
    '🌿', '🍃', '🌴', '🪵', '🌺', '💧', '🦋', '🍒', '🐢', '🌸',
  ];

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _micRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _micRingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _micRingController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _micRingController.dispose();
    AudioService().resume();
    super.dispose();
  }

  void _scrollToCurrentRow(int rowIndex) {
    if (!_scrollController.hasClients) return;
    final targetOffset = (rowIndex * 82.0).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocConsumer<NamotaBloc, NamotaState>(
        listener: (context, state) async {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentRow(state.currentRowIndex);
          });

          if (state.answerStatus == NamotaAnswerStatus.correct) {
            _confettiController.play();
          }

          if (state.isAllCompleted &&
              state.answerStatus == NamotaAnswerStatus.correct) {
            _confettiController.play();
            await Future.delayed(const Duration(seconds: 3));
            if (!context.mounted) return;
            context.read<NamotaBloc>().add(NamotaStop());
            context.pop();
          }
        },
        builder: (context, state) {
          final completedCount = state.completedRows.length;
          final isListening = state.isListening;
          final isValidating = state.isValidating;
          final isDisabled =
              isValidating || isListening || state.isPlayingAll;

          return Scaffold(
            body: SizedBox(
              height: 1.sh,
              width: 1.sw,
              child: Stack(
                children: [
                  // Background — matches selection screen
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
                      size: Size(1.sw, 80.h),
                      painter: _VinePainter(),
                    ),
                  ),

                  // Bottom grass decoration
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(1.sw, 50.h),
                      painter: _GrassPainter(),
                    ),
                  ),

                  // Main content
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 4.h),

                        // Header
                        _buildHeader(context, state),

                        SizedBox(height: 6.h),

                        // Progress stars
                        _buildProgress(completedCount),

                        SizedBox(height: 8.h),

                        // Rows — float directly on jungle background
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              vertical: 4.h,
                              horizontal: 14.w,
                            ),
                            itemCount: 10,
                            itemBuilder: (context, index) =>
                                _buildRow(context, state, index),
                          ),
                        ),

                        SizedBox(height: 6.h),

                        // Mic button
                        SizedBox(
                          width: 0.3.sw + 20.w,
                          height: 0.3.sw + 20.w,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isListening)
                                AnimatedBuilder(
                                  animation: _micRingAnim,
                                  builder: (context, _) {
                                    return Container(
                                      width: 0.3.sw +
                                          20.w * _micRingAnim.value,
                                      height: 0.3.sw +
                                          20.w * _micRingAnim.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFFD54F)
                                              .withValues(
                                            alpha: 0.6 *
                                                (1 - _micRingAnim.value),
                                          ),
                                          width: 3,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (isValidating)
                                SizedBox(
                                  width: 0.3.sw + 14.w,
                                  height: 0.3.sw + 14.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      const Color(0xFFFFD54F)
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              IgnorePointer(
                                ignoring: isDisabled,
                                child: Opacity(
                                  opacity: isDisabled ? 0.6 : 1.0,
                                  child: GamingImageButton(
                                    width: 0.3.sw,
                                    imagePath: Assets.imagesMicButton,
                                    onPressed: () => context
                                        .read<NamotaBloc>()
                                        .add(NamotaStartListening()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),

                  // Confetti
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.2,
                      colors: const [
                        Colors.green,
                        Colors.blue,
                        Colors.pink,
                        Colors.orange,
                        Colors.purple,
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

  // ============ Header ============
  Widget _buildHeader(BuildContext context, NamotaState state) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4E342E), Color(0xFF6D4C41), Color(0xFF4E342E)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFF3E2723), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<NamotaBloc>().add(NamotaStop());
              context.pop();
            },
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: const Color(0xFFFFF8E1),
                size: 22.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '${toBengali(state.tableNumber)} এর নামতা',
              style: GoogleFonts.hindSiliguri(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFF8E1),
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
          GestureDetector(
            onTap: state.isPlayingAll
                ? null
                : () => context.read<NamotaBloc>().add(NamotaPlayAll()),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: state.isPlayingAll
                      ? [const Color(0xFFFF8F00), const Color(0xFFFFB74D)]
                      : [const Color(0xFF43A047), const Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isPlayingAll
                        ? Icons.volume_up_rounded
                        : Icons.headphones_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    state.isPlayingAll ? 'চলছে...' : 'শোনো',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Progress ============
  Widget _buildProgress(int completedCount) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(10, (i) {
          final done = i < completedCount;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              width: done ? 22.w : 16.w,
              height: done ? 22.w : 16.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? const Color(0xFFFFD54F)
                    : Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: done
                      ? const Color(0xFFF9A825)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD54F)
                              .withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: done
                  ? Center(
                      child: Icon(
                        Icons.star_rounded,
                        size: 14.sp,
                        color: const Color(0xFFF57F17),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  // ============ Row ============
  Widget _buildRow(BuildContext context, NamotaState state, int index) {
    final tableNum = state.tableNumber;
    final multiplier = index + 1;
    final result = tableNum * multiplier;

    final isCurrent = state.currentRowIndex == index;
    final isCompleted = state.completedRows.contains(index);
    final isWrong =
        isCurrent && state.answerStatus == NamotaAnswerStatus.wrong;
    final isCorrect =
        isCurrent && state.answerStatus == NamotaAnswerStatus.correct;

    final style = _rowStyles[index % _rowStyles.length];
    final emoji = _rowEmojis[index % _rowEmojis.length];

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        // Determine gradient colors based on state
        List<Color> gradientColors;
        Color borderColor;
        double borderWidth;
        List<BoxShadow>? shadows;

        if (isWrong) {
          gradientColors = [
            const Color(0xFFC62828),
            const Color(0xFFE53935),
          ];
          borderColor = const Color(0xFFFF8A80);
          borderWidth = 3;
          shadows = [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ];
        } else if (isCorrect) {
          gradientColors = [
            const Color(0xFF2E7D32),
            const Color(0xFF43A047),
          ];
          borderColor = const Color(0xFF69F0AE);
          borderWidth = 3;
          shadows = [
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ];
        } else if (isCurrent) {
          gradientColors = [
            Color.lerp(style[0], const Color(0xFFFF8F00), 0.15)!,
            Color.lerp(style[1], const Color(0xFFFFB74D), 0.15)!,
          ];
          borderColor = Color.lerp(
            const Color(0xFFFFCA28),
            const Color(0xFFFFD54F),
            _pulseAnim.value,
          )!;
          borderWidth = 3;
          shadows = [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(
                alpha: 0.2 + _pulseAnim.value * 0.2,
              ),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: style[0].withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ];
        } else if (isCompleted) {
          gradientColors = [
            Color.lerp(style[0], const Color(0xFF1B5E20), 0.4)!,
            Color.lerp(style[1], const Color(0xFF2E7D32), 0.4)!,
          ];
          borderColor = const Color(0xFF66BB6A).withValues(alpha: 0.5);
          borderWidth = 2;
          shadows = [
            BoxShadow(
              color: style[0].withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];
        } else {
          gradientColors = [style[0], style[1]];
          borderColor = style[2];
          borderWidth = 2;
          shadows = [
            BoxShadow(
              color: style[0].withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ];
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                // Leaf decoration
                Positioned(
                  top: -4,
                  right: -4,
                  child: Opacity(
                    opacity: 0.3,
                    child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
                  ),
                ),

                // Main content
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 10.w,
                  ),
                  child: Row(
                    children: [
                      // Status dot / checkmark
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF43A047)
                              : Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFF66BB6A)
                                : Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16.sp,
                                )
                              : Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(width: 8.w),

                      // Equation
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              toBengali(tableNum),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: isCurrent ? 26.sp : 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text(
                                '×',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            Text(
                              toBengali(multiplier),
                              style: GoogleFonts.notoSansBengali(
                                fontSize: isCurrent ? 26.sp : 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            // Result — highlighted
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                toBengali(result),
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: isCurrent ? 28.sp : 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFFF8E1),
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.4),
                                      offset: const Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
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
      },
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
