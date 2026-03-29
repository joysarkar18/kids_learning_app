import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/widgets/module_background.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_button.dart';

import '../bloc/sothik_uttor_bloc.dart';
import '../bloc/sothik_uttor_event.dart';
import '../bloc/sothik_uttor_state.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class SothikUttorScreen extends StatefulWidget {
  const SothikUttorScreen({super.key});

  @override
  State<SothikUttorScreen> createState() => _SothikUttorScreenState();
}

class _SothikUttorScreenState extends State<SothikUttorScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _micRingController;
  late Animation<double> _micRingAnim;

  static const _backgroundImages = [
    Assets.imagesGkBg,
    Assets.imagesGkBg2,
    Assets.imagesGkBg3,
  ];

  String _getBackgroundForQuestion(SothikUttorState state) {
    final index = state.currentIndex;
    return _backgroundImages[index % _backgroundImages.length];
  }

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _micRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _micRingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _micRingController, curve: Curves.easeOut),
    );

    context.read<SothikUttorBloc>().add(SothikUttorInit());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _micRingController.dispose();
    AudioService().resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocConsumer<SothikUttorBloc, SothikUttorState>(
        listener: (context, state) async {
          if (state.answerStatus == SothikUttorAnswerStatus.correct) {
            _confettiController.play();
            await Future.delayed(const Duration(seconds: 2));

            if (!context.mounted) return;

            // Move to next question after celebration
            context.read<SothikUttorBloc>().add(SothikUttorNextQuestion());
          }

          // Handle completion
          if (state is SothikUttorCompleted) {
            if (!context.mounted) return;
            _showCompletionDialog(context);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: ModuleBackground(
              backgroundImage: _getBackgroundForQuestion(state),
              child: SizedBox(
                height: 1.sh,
                width: 1.sw,
                child: Stack(
                  children: [
                    // -------------------------
                    // 2. MAIN CONTENT
                    // -------------------------
                    _buildMainContent(state),

                  // -------------------------
                  // 3. BOTTOM BUTTONS
                  // -------------------------
                  _buildBottomButtons(state),

                  // -------------------------
                  // 4. MIC BUTTON
                  // -------------------------
                  _buildMicButton(state),

                  // -------------------------
                  // 5. CLOSE BUTTON
                  // -------------------------
                  _buildCloseButton(),

                  // -------------------------
                  // 7. CONFETTI
                  // -------------------------
                  _buildConfetti(),

                  // -------------------------
                  // 8. LOADING OVERLAY
                  // -------------------------
                  if (state is SothikUttorLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildMainContent(SothikUttorState state) {
    if (state is SothikUttorLoading) {
      return const SizedBox.shrink();
    }

    if (state is SothikUttorError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              state.errorMessage ?? 'Something went wrong',
              style: GoogleFonts.nunito(fontSize: 18.sp, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                context.read<SothikUttorBloc>().add(SothikUttorInit());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 0.12.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question Text
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                currentQuestion.questionText,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 20.h),

            // Show MCQ options or Hint Image based on question type
            if (currentQuestion.isMcqQuestion)
              _buildMcqOptions(state, currentQuestion)
            else
              _buildHintImage(state, currentQuestion),
          ],
        ),
      ),
    );
  }

  Widget _buildHintImage(SothikUttorState state, currentQuestion) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: state.answerStatus == SothikUttorAnswerStatus.wrong
            ? Colors.red.withValues(alpha: 0.5)
            : state.answerStatus == SothikUttorAnswerStatus.correct
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(10.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: CachedNetworkImage(
          imageUrl: currentQuestion.hintImage,
          width: 0.7.sw,
          height: 0.3.sh,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            width: 0.7.sw,
            height: 0.3.sh,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 0.7.sw,
            height: 0.3.sh,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.image_not_supported,
              size: 50.sp,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMcqOptions(SothikUttorState state, currentQuestion) {
    final options = currentQuestion.options;
    final selectedOptionId = state.selectedOptionId;
    final answerStatus = state.answerStatus;
    final isDisabled = answerStatus != SothikUttorAnswerStatus.none;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.85,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedOptionId == option.id;

          // Determine colors based on selection state
          Color borderColor = Colors.transparent;
          Color textBgColor = Colors.white;
          Color textColor = Colors.black87;

          if (isSelected && answerStatus == SothikUttorAnswerStatus.correct) {
            borderColor = Colors.green;
            textBgColor = Colors.green;
            textColor = Colors.white;
          } else if (isSelected &&
              answerStatus == SothikUttorAnswerStatus.wrong) {
            borderColor = Colors.red;
            textBgColor = Colors.red;
            textColor = Colors.white;
          } else if (isSelected) {
            borderColor = Colors.blue;
            textBgColor = Colors.blue;
            textColor = Colors.white;
          }

          return GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    context.read<SothikUttorBloc>().add(
                      SothikUttorOptionSelected(option.id),
                    );
                  },
            child: Column(
              children: [
                // Option Image (no background)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: borderColor,
                        width: isSelected ? 4.w : 0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: CachedNetworkImage(
                        imageUrl: option.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(strokeWidth: 2.w),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported,
                          size: 40.sp,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                // Option Text (attached below image)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: textBgColor,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.primary1, width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    option.text,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(SothikUttorState state) {
    final isDisabled =
        state.isValidating ||
        state.isPlayingSkipAudio ||
        state is SothikUttorLoading;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 30.h),
        child: IgnorePointer(
          ignoring: isDisabled,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // RETRY / REPLAY AUDIO
              GamingImageButton(
                imagePath: Assets.imagesRetryButton,
                width: 0.32.sw,
                onPressed: () =>
                    context.read<SothikUttorBloc>().add(SothikUttorRetry()),
              ),
              SizedBox(width: 20),
              GamingImageButton(
                imagePath: Assets.imagesArrowRight,
                width: 0.32.sw,
                onPressed: () => context.read<SothikUttorBloc>().add(
                  SothikUttorSkipQuestion(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(SothikUttorState state) {
    // Hide mic button for MCQ questions
    final currentQuestion = state.currentQuestion;
    if (currentQuestion != null && currentQuestion.isMcqQuestion) {
      return const SizedBox.shrink();
    }

    final isDisabled =
        state.isValidating ||
        state.isListening ||
        state.isPlayingSkipAudio ||
        state is SothikUttorLoading;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 120.h),
        child: SizedBox(
          width: 0.35.sw + 20.w,
          height: 0.35.sw + 20.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (state.isListening)
                AnimatedBuilder(
                  animation: _micRingAnim,
                  builder: (context, _) {
                    return Container(
                      width: 0.35.sw +
                          20.w * _micRingAnim.value,
                      height: 0.35.sw +
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
              if (state.isValidating)
                SizedBox(
                  width: 0.35.sw + 14.w,
                  height: 0.35.sw + 14.w,
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
                    width: 0.35.sw,
                    imagePath: Assets.imagesMicButton,
                    onPressed: () => context.read<SothikUttorBloc>().add(
                      SothikUttorStartListening(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 10.w, top: 15.h),
        child: GamingImageButton(
          width: 0.18.sw,
          imagePath: Assets.imagesCrossIcon,
          onPressed: () {
            context.read<SothikUttorBloc>().add(SothikUttorStop());
            context.pop();
          },
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return Align(
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
          Colors.yellow,
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              'Loading questions...',
              style: GoogleFonts.nunito(fontSize: 18.sp, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFFE082), const Color(0xFFFFC107)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.orange, size: 40.sp),
                SizedBox(width: 8.w),
                Icon(Icons.star, color: Colors.deepOrange, size: 55.sp),
                SizedBox(width: 8.w),
                Icon(Icons.star, color: Colors.orange, size: 40.sp),
              ],
            ),
            SizedBox(height: 16.h),

            // Trophy icon
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber[700],
                size: 60.sp,
              ),
            ),
            SizedBox(height: 20.h),

            // Congratulations text
            Text(
              'অভিনন্দন!',
              style: GoogleFonts.hindSiliguri(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 8.h),

            Text(
              'তুমি সব প্রশ্নের উত্তর দিয়েছ!',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: Colors.brown[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            // Go Back Button
            UniversalGamingButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              text: 'ফিরে যাও',
              icon: Icons.home_rounded,
              width: 0.6.sw,
              height: 55.h,
              backgroundColor: const Color(0xFF4CAF50),
              textStyle: GoogleFonts.hindSiliguri(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              iconColor: Colors.white,
              iconSize: 28.sp,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
