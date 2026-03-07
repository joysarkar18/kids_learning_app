import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/stories/data/models/story_model.dart';
import 'package:kids_learning/services/audio_service.dart';

class StoryReaderScreen extends StatefulWidget {
  final StoryModel story;

  const StoryReaderScreen({
    super.key,
    required this.story,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen>
    with SingleTickerProviderStateMixin {
  int _currentPageIndex = 0;
  bool _isAudioPlaying = false;
  bool _isLoadingImage = true;
  Timer? _autoAdvanceTimer;
  late PageController _pageController;
  late AnimationController _curlAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _curlAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _playPageAudio();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    _curlAnimationController.dispose();
    AudioService().stop();
    super.dispose();
  }

  void _playPageAudio() async {
    final currentPage = widget.story.pages[_currentPageIndex];
    if (currentPage.narration != null) {
      setState(() => _isAudioPlaying = true);
      
      try {
        await AudioService().play(currentPage.narration!);
        setState(() => _isAudioPlaying = false);
        
        // Auto-advance to next page after audio completes
        if (_currentPageIndex < widget.story.pages.length - 1) {
          _autoAdvanceTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              _nextPage();
            }
          });
        }
      } catch (e) {
        print('Audio play error: $e');
        setState(() => _isAudioPlaying = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPageIndex < widget.story.pages.length - 1) {
      setState(() => _isLoadingImage = true);
      _curlAnimationController.forward().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        ).then((_) {
          setState(() {
            _currentPageIndex++;
            _isLoadingImage = true;
          });
          _curlAnimationController.reset();
          _playPageAudio();
        });
      });
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      setState(() => _isLoadingImage = true);
      _curlAnimationController.forward().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        ).then((_) {
          setState(() {
            _currentPageIndex--;
            _isLoadingImage = true;
          });
          _curlAnimationController.reset();
          _playPageAudio();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Stack(
        children: [
          // Close button (top right)
          Positioned(
            top: 40.h,
            right: 20.w,
            child: GestureDetector(
              onTap: () {
                AudioService().stop();
                context.pop();
              },
              child: Container(
                width: 44.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          // Book with page curl effect
          Center(
            child: AspectRatio(
              aspectRatio: 1.414, // A4 ratio
              child: Container(
                margin: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      // Page content
                      PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.story.pages.length,
                        itemBuilder: (context, index) {
                          final page = widget.story.pages[index];
                          return _buildPage(page, index);
                        },
                      ),

                      // Page curl overlay
                      AnimatedBuilder(
                        animation: _curlAnimationController,
                        builder: (context, child) {
                          if (_curlAnimationController.value == 0) {
                            return Container();
                          }
                          return CustomPaint(
                            painter: PageCurlPainter(
                              progress: _curlAnimationController.value,
                            ),
                            child: Container(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(StoryPage page, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF8E1), // Warm paper color
            const Color(0xFFFFECB3).withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Column(
        children: [
          // Image area (top 60%)
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4A7C2C),
                      const Color(0xFF2D5016),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Story image
                    if (page.isImageUrl)
                      CachedNetworkImage(
                        imageUrl: page.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFFFFD700),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            '🖼️',
                            style: TextStyle(fontSize: 60.sp),
                          ),
                        ),
                        imageBuilder: (context, imageProvider) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _isLoadingImage = false);
                          });
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Center(
                        child: Text(
                          '🖼️',
                          style: TextStyle(fontSize: 60.sp),
                        ),
                      ),

                    // Loading indicator
                    if (_isLoadingImage)
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),

                    // Audio playing indicator
                    if (_isAudioPlaying && !_isLoadingImage)
                      Positioned(
                        top: 16.h,
                        right: 16.w,
                        child: _AudioIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Text area (bottom 40%)
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  // Decorative line
                  Container(
                    width: 100.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF4A7C2C),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Story text
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          page.text,
                          style: GoogleFonts.bubblegumSans(
                            fontSize: 18.sp,
                            height: 1.6,
                            color: const Color(0xFF2D5016),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  
                  // Page number
                  SizedBox(height: 12.h),
                  Text(
                    '${index + 1}',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tap zones for navigation
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 1.sw * 0.3,
            child: GestureDetector(
              onTap: _previousPage,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 1.sw * 0.3,
            child: GestureDetector(
              onTap: _nextPage,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Audio playing indicator widget
class _AudioIndicator extends StatefulWidget {
  @override
  State<_AudioIndicator> createState() => _AudioIndicatorState();
}

class _AudioIndicatorState extends State<_AudioIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 8 + (_controller.value * 4),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.volume_up_rounded,
            color: const Color(0xFF2D5016),
            size: 24.sp,
          ),
        );
      },
    );
  }
}

/// Custom painter for page curl effect
class PageCurlPainter extends CustomPainter {
  final double progress;

  PageCurlPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.3 * progress),
          Colors.transparent,
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * progress);

    final path = Path();
    final curlWidth = size.width * progress * 0.4;
    
    path.moveTo(size.width - curlWidth, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - curlWidth, size.height);
    path.quadraticBezierTo(
      size.width - curlWidth * 0.5,
      size.height * 0.5,
      size.width - curlWidth,
      0,
    );

    canvas.drawPath(path, paint);

    // Add shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2 * progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
    
    final shadowPath = Path();
    shadowPath.moveTo(size.width - curlWidth * 0.8, 0);
    shadowPath.lineTo(size.width, 0);
    shadowPath.lineTo(size.width, size.height * 0.3);
    shadowPath.quadraticBezierTo(
      size.width - curlWidth * 0.3,
      size.height * 0.5,
      size.width - curlWidth * 0.8,
      0,
    );
    
    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
