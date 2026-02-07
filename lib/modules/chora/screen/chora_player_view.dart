import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/chora/data/models/chora_model.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ChoraPlayerScreen extends StatefulWidget {
  final List<ChoraModel> choras;
  final int initialIndex;

  const ChoraPlayerScreen({
    super.key,
    required this.choras,
    required this.initialIndex,
  });

  @override
  State<ChoraPlayerScreen> createState() => _ChoraPlayerScreenState();
}

class _ChoraPlayerScreenState extends State<ChoraPlayerScreen>
    with TickerProviderStateMixin {
  late YoutubePlayerController _youtubeController;
  late AnimationController _textAnimationController;
  late int _currentIndex;
  late List<String> _lines;

  ChoraModel get _currentChora => widget.choras[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initForCurrentChora();
  }

  void _initForCurrentChora() {
    _lines =
        _currentChora.text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    final videoId =
        YoutubePlayer.convertUrlToId(_currentChora.youtubeUrl) ?? '';

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        showLiveFullscreenButton: false,
      ),
    );

    final totalDuration = Duration(milliseconds: 400 + (_lines.length * 250));
    _textAnimationController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimationController.forward();
    });
  }

  void _switchToChora(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.choras.length) return;

    _youtubeController.dispose();
    _textAnimationController.dispose();

    setState(() {
      _currentIndex = newIndex;
    });

    _initForCurrentChora();
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

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
              // 1. BACKGROUND
              Image.asset(
                Assets.imagesGkBg2,
                fit: BoxFit.cover,
                height: 1.sh,
                width: 1.sw,
              ),

              // 2. MAIN CONTENT
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 50.h),

                    // Video player in a frame
                    _buildVideoFrame(),

                    SizedBox(height: 12.h),

                    // Title
                    Text(
                      _currentChora.title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.h),

                    // Animated text in a frame
                    Expanded(child: _buildTextFrame()),

                    // Space for bottom buttons
                    SizedBox(height: 80.h),
                  ],
                ),
              ),

              // 3. NAVIGATION BUTTONS (Bottom)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GamingImageButton(
                        imagePath: Assets.imagesArrowLeft,
                        width: 0.32.sw,
                        onPressed: _currentIndex > 0
                            ? () => _switchToChora(_currentIndex - 1)
                            : () {},
                      ),
                      GamingImageButton(
                        imagePath: Assets.imagesRetryButton,
                        width: 0.32.sw,
                        onPressed: () => _switchToChora(_currentIndex),
                      ),
                      GamingImageButton(
                        imagePath: Assets.imagesArrowRight,
                        width: 0.32.sw,
                        onPressed: _currentIndex < widget.choras.length - 1
                            ? () => _switchToChora(_currentIndex + 1)
                            : () {},
                      ),
                    ],
                  ),
                ),
              ),

              // 4. CLOSE BUTTON
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

  Widget _buildVideoFrame() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary1, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: YoutubePlayer(
          controller: _youtubeController,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary1,
          progressColors: const ProgressBarColors(
            playedColor: Color(0xFF8EDF0E),
            handleColor: Color(0xFF6C63FF),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFrame() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary2, width: 3.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary2.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary2.withValues(alpha: 0.05),
                AppColors.primary1.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_lines.length, (index) {
                    final start = index / _lines.length;
                    final end = (index + 1) / _lines.length;
                    final interval =
                        Interval(start, end, curve: Curves.easeOutBack);
                    final progress =
                        interval.transform(_textAnimationController.value);

                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - progress)),
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Text(
                            _lines[index],
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              color: index % 2 == 0
                                  ? AppColors.primary2
                                  : Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
