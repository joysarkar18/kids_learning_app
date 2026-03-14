import 'dart:ui';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/chora/data/models/chora_model.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

// Accent colors
const _kTitleColor = Color(0xFFFFC947);
const _kActiveLineColor = Color(0xFFFFD700);
const _kGlowColor = Color(0xFFFFB300);

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  late int _currentIndex;
  int _currentLineIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  late AnimationController _headerController;
  late Animation<double> _headerFade;

  // Floating orb ambient animation
  late AnimationController _ambientController;

  late List<AnimationController> _lineControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  ChoraModel get _currentChora => widget.choras[_currentIndex];
  List<String> get _textLines => _currentChora.textLines;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _setupHeaderAnimation();
    _setupAmbientAnimation();
    _setupLineAnimations();
    _initAudioListener();
    _initForCurrentChora();
  }

  void _setupHeaderAnimation() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
  }

  void _setupAmbientAnimation() {
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  void _setupLineAnimations() {
    _lineControllers = List.generate(
      _textLines.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _fadeAnimations = _lineControllers
        .map(
          (c) => Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
    _slideAnimations = _lineControllers
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.22),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();
  }

  void _disposeLineAnimations() {
    for (final c in _lineControllers) {
      c.dispose();
    }
  }

  void _initAudioListener() {
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
      _onAudioProgress(position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _totalDuration = duration);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
  }

  void _initForCurrentChora() {
    _currentLineIndex = 0;
    _isPlaying = false;
    _currentPosition = Duration.zero;

    _headerController.reset();
    _setupLineAnimations();

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _headerController.forward();
    });

    for (int i = 0; i < _lineControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 250 + i * 90), () {
        if (mounted) _lineControllers[i].forward();
      });
    }

    // Report progress to Daily Challenge
    DailyChallengeService.instance.reportProgress('chora');

    _playAudio();
  }

  void _playAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(_currentChora.audioUrl));
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _onAudioProgress(Duration position) {
    if (!mounted || _textLines.isEmpty) return;
    final positionSec = position.inMilliseconds / 1000.0;
    final totalSec = _currentChora.duration;
    if (totalSec <= 0) return;
    final progress = positionSec / totalSec;
    final lineIndex = (progress * _textLines.length).floor().clamp(
      0,
      _textLines.length - 1,
    );
    if (lineIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = lineIndex);
      _scrollToLine(lineIndex);
    }
  }

  void _scrollToLine(int lineIndex) {
    if (!_scrollController.hasClients) return;
    final estimatedLineHeight = 72.h;
    final targetOffset = lineIndex * estimatedLineHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  void _switchToChora(int newIndex) async {
    if (newIndex < 0 || newIndex >= widget.choras.length) return;
    await _audioPlayer.stop();
    _disposeLineAnimations();
    setState(() {
      _currentIndex = newIndex;
      _currentLineIndex = 0;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    _initForCurrentChora();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _headerController.dispose();
    _ambientController.dispose();
    _disposeLineAnimations();
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
              // Blurred background image
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: CachedNetworkImage(
                    imageUrl: _currentChora.backgroundImage,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary2.withValues(alpha: 0.7),
                            AppColors.primary1.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Container(color: const Color(0xFF1A1A2E)),
                  ),
                ),
              ),

              // Dark tint
              Positioned.fill(
                child: Container(color: Colors.black.withValues(alpha: 0.52)),
              ),

              // Ambient floating orbs (top-right & bottom-left)
              AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  final t = _ambientController.value;
                  return Stack(
                    children: [
                      // Top-right orb
                      Positioned(
                        top: -40.h + (20.h * math.sin(t * math.pi)),
                        right: -30.w + (15.w * t),
                        child: _buildOrb(
                          size: 180.w,
                          color: _kGlowColor.withValues(alpha: 0.08 + 0.04 * t),
                        ),
                      ),
                      // Bottom-left orb
                      Positioned(
                        bottom: 80.h - (15.h * t),
                        left: -40.w + (10.w * math.sin(t * math.pi)),
                        child: _buildOrb(
                          size: 150.w,
                          color: AppColors.primary1.withValues(
                            alpha: 0.07 + 0.03 * t,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Decorative top arc line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(1.sw, 120.h),
                  painter: _ArcLinePainter(),
                ),
              ),

              // Corner ornament top-right
              Positioned(
                top: 10.h,
                right: 14.w,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: _buildCornerOrnament(),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    _buildAuthorRow(),
                    SizedBox(height: 2.h),
                    _buildDivider(),
                    SizedBox(height: 10.h),
                    Expanded(child: _buildPoemScroll()),
                    SizedBox(height: 8.h),
                    _buildBottomOrnament(),
                    SizedBox(height: 10.h),
                    _buildNavButtons(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildCornerOrnament() {
    return SizedBox(
      width: 36.w,
      height: 36.w,
      child: CustomPaint(painter: _CornerOrnamentPainter()),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            // Cross button on the left
            GamingImageButton(
              width: 0.18.sw,
              imagePath: Assets.imagesCrossIcon,
              onPressed: () => context.pop(),
            ),
            // Centered title
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 0.18.sw),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_kTitleColor, Color(0xFFFFE082)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
                  child: Text(
                    _currentChora.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white, // masked by shader
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: _kTitleColor.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorRow() {
    final author = _currentChora.author;
    if (author == null || author.isEmpty) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: _kTitleColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              author,
              style: GoogleFonts.lato(
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: _kTitleColor.withValues(alpha: 0.75),
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kTitleColor.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Icon(
                Icons.auto_stories_outlined,
                color: _kTitleColor.withValues(alpha: 0.45),
                size: 14.sp,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _kTitleColor.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoemScroll() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_textLines.length, _buildLine),
      ),
    );
  }

  Widget _buildLine(int index) {
    if (index >= _lineControllers.length) return const SizedBox.shrink();

    final isActive = index == _currentLineIndex;
    final isPast = index < _currentLineIndex;

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            style: GoogleFonts.hindSiliguri(
              fontSize: isActive ? 26.sp : 20.sp,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive
                  ? _kActiveLineColor
                  : isPast
                  ? Colors.white.withValues(alpha: 0.72) // clearly readable
                  : Colors.white.withValues(alpha: 0.88),
              height: 1.55,
              shadows: isActive
                  ? [
                      Shadow(
                        color: _kGlowColor.withValues(alpha: 0.55),
                        blurRadius: 22,
                      ),
                      const Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            textAlign: TextAlign.center,
            child: Text(_textLines[index], textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOrnament() {
    return FadeTransition(
      opacity: _headerFade,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSmallDot(),
          SizedBox(width: 6.w),
          _buildSmallDot(large: true),
          SizedBox(width: 6.w),
          _buildSmallDot(),
        ],
      ),
    );
  }

  Widget _buildSmallDot({bool large = false}) {
    return Container(
      width: large ? 6.w : 4.w,
      height: large ? 6.w : 4.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kTitleColor.withValues(alpha: large ? 0.55 : 0.30),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GamingImageButton(
            imagePath: Assets.imagesArrowLeft,
            width: 0.28.sw,
            onPressed: _currentIndex > 0
                ? () => _switchToChora(_currentIndex - 1)
                : () {},
          ),
          GamingImageButton(
            imagePath: Assets.imagesRetryButton,
            width: 0.28.sw,
            onPressed: () => _switchToChora(_currentIndex),
          ),
          GamingImageButton(
            imagePath: Assets.imagesArrowRight,
            width: 0.28.sw,
            onPressed: _currentIndex < widget.choras.length - 1
                ? () => _switchToChora(_currentIndex + 1)
                : () {},
          ),
        ],
      ),
    );
  }
}

// Subtle curved arc drawn behind the top bar
class _ArcLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC947).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(-20, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.3,
        size.width + 20,
        size.height * 0.85,
      );

    canvas.drawPath(path, paint);

    // Second slightly offset arc
    final paint2 = Paint()
      ..color = const Color(0xFFFFC947).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path2 = Path()
      ..moveTo(-20, size.height * 0.95)
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.15,
        size.width + 20,
        size.height * 0.95,
      );

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Small corner ornament (top-right)
class _CornerOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC947).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Outer arc
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      math.pi,
      math.pi / 2,
      false,
      paint,
    );

    // Inner arc
    final innerPaint = Paint()
      ..color = const Color(0xFFFFC947).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawArc(
      Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
      math.pi,
      math.pi / 2,
      false,
      innerPaint,
    );

    // Dot at center
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      2,
      Paint()..color = const Color(0xFFFFC947).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
