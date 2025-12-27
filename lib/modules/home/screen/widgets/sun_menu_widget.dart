import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/utils/assets.dart';

class SunMenuWidget extends StatefulWidget {
  const SunMenuWidget({super.key});

  @override
  State<SunMenuWidget> createState() => _SunMenuWidgetState();
}

class _SunMenuWidgetState extends State<SunMenuWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  bool _isPlayingGreeting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  UiAudioKey _getGreetingAudioKey() {
    return UiAudioKey.yay_sound; // Replace with your sun audio key
  }

  void _onSunTap() async {
    // Prevent multiple taps while greeting is playing
    if (_isPlayingGreeting) {
      return;
    }

    _isPlayingGreeting = true;

    // Scale animation
    await _scaleController.forward();
    await _scaleController.reverse();

    // Play greeting audio (always the same audio)
    AudioPlayerService.instance.playUi(key: _getGreetingAudioKey());

    // Wait for audio to finish (approximately 3 seconds)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isPlayingGreeting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(top: 40.h, right: 16.w),
        child: GestureDetector(
          onTap: _onSunTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              Assets.imagesSunMenu,
              width: 100.w,
              height: 100.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
