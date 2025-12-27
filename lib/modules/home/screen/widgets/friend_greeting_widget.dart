import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/audio/audio_key.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/services/friend_selection_service.dart';
import 'package:kids_learning/utils/assets.dart';

class FriendGreetingWidget extends StatefulWidget {
  const FriendGreetingWidget({super.key});

  @override
  State<FriendGreetingWidget> createState() => _FriendGreetingWidgetState();
}

class _FriendGreetingWidgetState extends State<FriendGreetingWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _messageController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _messageAnimation;
  late Timer _autoGreetingTimer;

  String? selectedFriendKey;
  String _greetingMessage = '';
  bool _showMessage = false;
  bool _isPlayingGreeting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSelectedFriend();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _messageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeOut),
    );
  }

  void _startAutoGreetingTimer() {
    _autoGreetingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && !_isPlayingGreeting) {
        _showAutoGreeting();
      }
    });
  }

  Future<void> _loadSelectedFriend() async {
    final friendKey = await FriendSelectionService.instance.getSelectedFriend();
    if (mounted) {
      setState(() {
        selectedFriendKey = friendKey;
      });
      // Show greeting on initial load
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _showAutoGreeting();
        _startAutoGreetingTimer();
      }
    }
  }

  Future<void> _showAutoGreeting() async {
    final l10n = AppLocalizations.of(context)!;

    // Scale animation (breathing effect)
    await _scaleController.forward();
    await _scaleController.reverse();

    // Show greeting message
    if (mounted) {
      setState(() {
        _greetingMessage = _getGreetingMessage(l10n);
        _showMessage = true;
      });

      await _messageController.forward();

      // Hide message after 1 second
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        await _messageController.reverse();
        if (mounted) {
          setState(() {
            _showMessage = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _messageController.dispose();
    _autoGreetingTimer.cancel();
    super.dispose();
  }

  String _getGreetingMessage(AppLocalizations l10n) {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning ?? 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return l10n.goodAfternoon ?? 'Good Afternoon';
    } else {
      return l10n.goodEvening ?? 'Good Evening';
    }
  }

  String _getTimePeriod() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  String _getCharacterImagePath(String? friendKey) {
    final characterImageMap = {
      'chintu': Assets.imagesChintuMenu,
      'gauri': Assets.imagesGauriMenu,
      'moti': Assets.imagesMotiMenu,
      'gudiya': Assets.imagesGudiyaMenu,
      'gajaraj': Assets.imagesGajrajMenu,
      'chiku': Assets.imagesChikuMenu,
    };

    return characterImageMap[friendKey] ?? Assets.imagesChikuMenu;
  }

  AudioKey _getGreetingAudioKey(String? friendKey, String timePeriod) {
    final audioKeyMap = {
      'chintu': {
        'morning': AudioKey.chintu_gm,
        'afternoon': AudioKey.chintu_ga,
        'evening': AudioKey.chintu_ge,
      },
      'gauri': {
        'morning': AudioKey.gauri_gm,
        'afternoon': AudioKey.gauri_ga,
        'evening': AudioKey.gauri_ge,
      },
      'moti': {
        'morning': AudioKey.moti_gm,
        'afternoon': AudioKey.moti_ga,
        'evening': AudioKey.moti_ge,
      },
      'gudiya': {
        'morning': AudioKey.gudiya_gm,
        'afternoon': AudioKey.gudiya_ga,
        'evening': AudioKey.gudiya_ge,
      },
      'gajaraj': {
        'morning': AudioKey.gajraj_gm,
        'afternoon': AudioKey.gajraj_ga,
        'evening': AudioKey.gajraj_ge,
      },
      'chiku': {
        'morning': AudioKey.chiku_gm,
        'afternoon': AudioKey.chiku_ga,
        'evening': AudioKey.chiku_ge,
      },
    };

    return audioKeyMap[friendKey]?[timePeriod] ?? AudioKey.chiku_gm;
  }

  void _onFriendTap() async {
    if (_isPlayingGreeting) {
      return;
    }

    _isPlayingGreeting = true;
    final l10n = AppLocalizations.of(context)!;
    final timePeriod = _getTimePeriod();

    await _scaleController.forward();
    await _scaleController.reverse();

    AudioPlayerService.instance.playLocalized(
      context: context,
      key: _getGreetingAudioKey(selectedFriendKey, timePeriod),
    );

    setState(() {
      _greetingMessage = _getGreetingMessage(l10n);
      _showMessage = true;
    });

    await _messageController.forward();

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      await _messageController.reverse();
      if (mounted) {
        setState(() {
          _showMessage = false;
          _isPlayingGreeting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 40.h, left: 16.w),
        child: GestureDetector(
          onTap: _onFriendTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  _getCharacterImagePath(selectedFriendKey),
                  width: 100.w,
                  height: 100.w,
                  fit: BoxFit.contain,
                ),
              ),
              if (_showMessage)
                Positioned(
                  top: -10.h,
                  left: 105.w,
                  child: FadeTransition(
                    opacity: _messageAnimation,
                    child: Transform.translate(
                      offset: Offset((_messageAnimation.value - 1) * 20, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Cloud shape bubble
                          CustomPaint(
                            painter: CloudBubblePainter(
                              borderColor: const Color(0xFF5C4BDB),
                              fillColor: Colors.white,
                            ),
                            size: Size(200.w, 85.h),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 14.h,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    _greetingMessage,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.bubblegumSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5C4BDB),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
}

class CloudBubblePainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  CloudBubblePainter({required this.borderColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final width = size.width;
    final height = size.height;

    // Create cloud shape path
    final path = Path();

    // Start from left middle
    path.moveTo(0, height * 0.5);

    // Tail pointer on the left
    path.lineTo(width * 0.05, height * 0.4);
    path.lineTo(width * 0.08, height * 0.55);
    path.lineTo(width * 0.05, height * 0.6);

    // Left curve
    path.cubicTo(
      width * 0.08,
      height * 0.75,
      width * 0.15,
      height * 0.85,
      width * 0.3,
      height * 0.85,
    );

    // Bottom curve
    path.cubicTo(
      width * 0.5,
      height * 0.88,
      width * 0.7,
      height * 0.85,
      width * 0.8,
      height * 0.75,
    );

    // Right bump
    path.cubicTo(
      width * 0.92,
      height * 0.7,
      width * 0.98,
      height * 0.6,
      width * 0.95,
      height * 0.45,
    );

    // Right top curve
    path.cubicTo(
      width * 0.98,
      height * 0.3,
      width * 0.92,
      height * 0.12,
      width * 0.75,
      height * 0.08,
    );

    // Top curve
    path.cubicTo(
      width * 0.55,
      height * 0.03,
      width * 0.3,
      height * 0.03,
      width * 0.15,
      height * 0.1,
    );

    // Left top curve back to start
    path.cubicTo(
      width * 0.08,
      height * 0.2,
      width * 0.03,
      height * 0.35,
      0,
      height * 0.5,
    );

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CloudBubblePainter oldDelegate) => false;
}
