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
  final ScrollController _scrollController = ScrollController();
  late int _currentIndex;
  late List<String> _lines;
  int _currentLineIndex = 0;

  ChoraModel get _currentChora => widget.choras[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initForCurrentChora();
  }

  void _initForCurrentChora() {
    _lines = _currentChora.text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    _currentLineIndex = 0;

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

    _youtubeController.addListener(_onVideoProgress);

    final totalDuration = Duration(milliseconds: 400 + (_lines.length * 250));
    _textAnimationController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimationController.forward();
    });
  }

  void _onVideoProgress() {
    if (!mounted || _lines.isEmpty) return;

    final position = _youtubeController.value.position;
    final duration = _youtubeController.metadata.duration;

    if (duration.inMilliseconds <= 0) return;

    final progress = position.inMilliseconds / duration.inMilliseconds;
    final lineIndex = (progress * _lines.length).floor().clamp(
      0,
      _lines.length - 1,
    );

    if (lineIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = lineIndex;
      });
      _scrollToLine(lineIndex);
    }
  }

  void _scrollToLine(int lineIndex) {
    if (!_scrollController.hasClients) return;

    final estimatedLineHeight = 45.h;
    final targetOffset = lineIndex * estimatedLineHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _switchToChora(int newIndex) {
    if (newIndex < 0 || newIndex >= widget.choras.length) return;

    final oldYoutubeController = _youtubeController;
    final oldTextAnimationController = _textAnimationController;

    oldYoutubeController.removeListener(_onVideoProgress);

    _currentIndex = newIndex;
    _initForCurrentChora();

    setState(() {});

    // Reset scroll position
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    // Dispose old controllers after the frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldYoutubeController.dispose();
      oldTextAnimationController.dispose();
    });
  }

  @override
  void dispose() {
    _youtubeController.removeListener(_onVideoProgress);
    _youtubeController.dispose();
    _textAnimationController.dispose();
    _scrollController.dispose();
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
              // Background
              Image.asset(
                Assets.imagesGkBg2,
                fit: BoxFit.cover,
                height: 1.sh,
                width: 1.sw,
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Close button row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 10.w, top: 8.h),
                        child: GamingImageButton(
                          width: 0.20.sw,
                          imagePath: Assets.imagesCrossIcon,
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),

                    // Video player
                    _buildVideoFrame(),

                    SizedBox(height: 12.h),

                    // Lyrics parchment
                    Expanded(child: _buildTextFrame()),

                    // Space for bottom buttons
                    SizedBox(height: 96.h),
                  ],
                ),
              ),

              // Navigation buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoFrame() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary1, width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: YoutubePlayer(
          key: ValueKey(_currentIndex),
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
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF8B6914), width: 3.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5E6C8), Color(0xFFEDD9B0), Color(0xFFE8CFA0)],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(_lines.length, (index) {
                    final start = index / _lines.length;
                    final end = (index + 1) / _lines.length;
                    final interval = Interval(
                      start,
                      end,
                      curve: Curves.easeOutBack,
                    );
                    final progress = interval.transform(
                      _textAnimationController.value,
                    );

                    final isCurrentLine = index == _currentLineIndex;

                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - progress)),
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            vertical: 4.h,
                            horizontal: isCurrentLine ? 8.w : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentLine
                                ? const Color(
                                    0xFF8B6914,
                                  ).withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: isCurrentLine ? 26.sp : 22.sp,
                              fontWeight: isCurrentLine
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCurrentLine
                                  ? const Color(0xFFD32F2F)
                                  : index % 2 == 0
                                  ? const Color(0xFF3E2723)
                                  : const Color(0xFF5D4037),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            child: Text(
                              _lines[index],
                              textAlign: TextAlign.center,
                            ),
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
