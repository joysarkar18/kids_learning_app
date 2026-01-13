import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kids_learning/services/logger_service.dart';

/// A gaming-style image button with animation, sound, haptic feedback
/// and optional white glow shadow (kids friendly)
class GamingImageButton extends StatefulWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final double width;
  final double height;

  final bool enableSound;
  final String? customSoundPath;

  final bool hapticFeedback;
  final HapticFeedbackType hapticType;

  final bool enabled;

  final Duration animationDuration;
  final double pressScale;
  final Curve animationCurve;

  final BoxFit imageFit;
  final VoidCallback? onLongPress;

  /// 🌟 Optional white glow
  final bool enableGlow;
  final double glowIntensity;

  const GamingImageButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    this.width = 100,
    this.height = 100,
    this.enableSound = true,
    this.customSoundPath,
    this.hapticFeedback = true,
    this.hapticType = HapticFeedbackType.light,
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 100),
    this.pressScale = 0.95,
    this.animationCurve = Curves.easeOut,
    this.imageFit = BoxFit.contain,
    this.onLongPress,

    // 🌟 Glow options
    this.enableGlow = false,
    this.glowIntensity = 1.0,
  });

  @override
  State<GamingImageButton> createState() => _GamingImageButtonState();
}

enum HapticFeedbackType { light, medium, heavy, selection }

class _GamingImageButtonState extends State<GamingImageButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    if (!widget.enableSound) return;

    try {
      final soundPath = widget.customSoundPath ?? "audios/ui/button_press.wav";
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath), volume: 1.0);
    } catch (e) {
      LoggerService.logError('Sound playback failed: $e');
    }
  }

  void _triggerHaptic() {
    if (!widget.hapticFeedback) return;

    switch (widget.hapticType) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  void _handleTap() {
    if (!widget.enabled) return;

    setState(() => _isPressed = true);
    _triggerHaptic();
    _playSound();

    Future.delayed(widget.animationDuration, () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });

    widget.onPressed();
  }

  void _handleLongPress() {
    if (!widget.enabled || widget.onLongPress == null) return;
    HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: AnimatedScale(
          scale: _isPressed ? widget.pressScale : 1.0,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          child: AnimatedContainer(
            duration: widget.animationDuration,
            curve: Curves.easeOut,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              boxShadow: widget.enableGlow
                  ? [
                      // 🌟 Soft white glow
                      BoxShadow(
                        color: Colors.white.withOpacity(
                          (_isPressed ? 0.25 : 0.45) * widget.glowIntensity,
                        ),
                        blurRadius:
                            (_isPressed ? 10 : 18) * widget.glowIntensity,
                        spreadRadius:
                            (_isPressed ? 1 : 3) * widget.glowIntensity,
                      ),

                      // 🧱 Subtle depth
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Image.asset(widget.imagePath, fit: widget.imageFit),
          ),
        ),
      ),
    );
  }
}
