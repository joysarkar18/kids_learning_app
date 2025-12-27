import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kids_learning/services/logger_service.dart';

/// A highly customizable gaming-style button with smooth animations, sounds, and haptic feedback
class UniversalGamingButton extends StatefulWidget {
  // Callback
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  // Icon options (use only one)
  final IconData? icon;
  final Widget? iconWidget;
  final String? svgPath;
  final String? imagePath;

  // Text options
  final String? text;
  final TextStyle? textStyle;

  // Size and shape
  final double? width;
  final double? height;
  final double? size; // For square buttons
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final BoxShape shape; // circle or rectangle

  // Colors
  final Color backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? shadowColor;
  final Color? borderColor;
  final Gradient? gradient;

  // Icon/Text sizing
  final double? iconSize;
  final double? fontSize;

  // Shadow and elevation
  final double shadowDepth;
  final double? elevation;
  final List<BoxShadow>? customShadows;

  // Border
  final double borderWidth;

  // Animation
  final Duration animationDuration;
  final double pressScale;
  final Curve animationCurve;

  // Sound and haptics
  final bool enableSound;
  final String? customSoundPath;
  final bool hapticFeedback;
  final HapticFeedbackType hapticType;

  // States
  final bool enabled;
  final bool loading;
  final Widget? loadingWidget;

  // Layout
  final MainAxisAlignment contentAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis direction; // horizontal or vertical layout for icon+text
  final double spacing; // Space between icon and text

  // Advanced customization
  final bool showGlossEffect;
  final bool show3DEffect;
  final List<Color>? glossColors;

  const UniversalGamingButton({
    super.key,
    required this.onPressed,
    this.onLongPress,
    // Icons
    this.icon,
    this.iconWidget,
    this.svgPath,
    this.imagePath,
    // Text
    this.text,
    this.textStyle,
    // Size
    this.width,
    this.height,
    this.size,
    this.padding,
    this.borderRadius = 16,
    this.shape = BoxShape.rectangle,
    // Colors
    this.backgroundColor = const Color(0xFF6C63FF),
    this.iconColor,
    this.textColor,
    this.shadowColor,
    this.borderColor,
    this.gradient,
    // Sizing
    this.iconSize,
    this.fontSize,
    // Shadow
    this.shadowDepth = 6,
    this.elevation,
    this.customShadows,
    // Border
    this.borderWidth = 0,
    // Animation
    this.animationDuration = const Duration(milliseconds: 100),
    this.pressScale = 0.95,
    this.animationCurve = Curves.easeOut,
    // Sound & Haptics
    this.enableSound = true,
    this.customSoundPath,
    this.hapticFeedback = true,
    this.hapticType = HapticFeedbackType.light,
    // States
    this.enabled = true,
    this.loading = false,
    this.loadingWidget,
    // Layout
    this.contentAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.direction = Axis.horizontal,
    this.spacing = 8,
    // Advanced
    this.showGlossEffect = false,
    this.show3DEffect = true,
    this.glossColors,
  });

  // Convenience constructors
  factory UniversalGamingButton.icon({
    required VoidCallback onPressed,
    required IconData icon,
    double size = 60,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
    bool circular = false,
  }) {
    return UniversalGamingButton(
      onPressed: onPressed,
      icon: icon,
      size: size,
      backgroundColor: backgroundColor ?? const Color(0xFF6C63FF),
      iconColor: iconColor,
      iconSize: iconSize,
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  factory UniversalGamingButton.text({
    required VoidCallback onPressed,
    required String text,
    double? width,
    double? height,
    Color? backgroundColor,
    Color? textColor,
    TextStyle? textStyle,
  }) {
    return UniversalGamingButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      backgroundColor: backgroundColor ?? const Color(0xFF6C63FF),
      textColor: textColor,
      textStyle: textStyle,
    );
  }

  factory UniversalGamingButton.iconText({
    required VoidCallback onPressed,
    IconData? icon,
    String? text,
    double? width,
    double? height,
    Color? backgroundColor,
    Axis direction = Axis.horizontal,
  }) {
    return UniversalGamingButton(
      onPressed: onPressed,
      icon: icon,
      text: text,
      width: width,
      height: height,
      backgroundColor: backgroundColor ?? const Color(0xFF6C63FF),
      direction: direction,
    );
  }

  @override
  State<UniversalGamingButton> createState() => _UniversalGamingButtonState();
}

enum HapticFeedbackType { light, medium, heavy, selection }

class _UniversalGamingButtonState extends State<UniversalGamingButton> {
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
    if (!widget.enabled || widget.loading) return;

    setState(() => _isPressed = true);
    _triggerHaptic();
    _playSound();

    // Quick animation - press and release automatically
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isPressed = false);
      }
    });

    widget.onPressed();
  }

  void _handleLongPress() {
    if (!widget.enabled || widget.loading || widget.onLongPress == null) return;

    HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  Widget _buildIcon() {
    if (widget.loading) {
      return widget.loadingWidget ??
          SizedBox(
            width: widget.iconSize ?? 24,
            height: widget.iconSize ?? 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.iconColor ?? Colors.white,
              ),
            ),
          );
    }

    if (widget.iconWidget != null) {
      return widget.iconWidget!;
    } else if (widget.svgPath != null) {
      return SvgPicture.asset(
        widget.svgPath!,
        width: widget.iconSize ?? 24,
        height: widget.iconSize ?? 24,
        colorFilter: widget.iconColor != null
            ? ColorFilter.mode(widget.iconColor!, BlendMode.srcIn)
            : null,
      );
    } else if (widget.imagePath != null) {
      return Image.asset(
        widget.imagePath!,
        width: widget.iconSize ?? 24,
        height: widget.iconSize ?? 24,
        color: widget.iconColor,
      );
    } else if (widget.icon != null) {
      return Icon(
        widget.icon,
        size: widget.iconSize ?? 24,
        color: widget.iconColor ?? widget.textColor ?? Colors.white,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildText() {
    if (widget.text == null || widget.loading) return const SizedBox.shrink();

    final defaultTextStyle = TextStyle(
      fontSize: widget.fontSize ?? 16,
      color: widget.textColor ?? Colors.white,
      fontWeight: FontWeight.bold,
    );

    return Text(
      widget.text!,
      style: widget.textStyle ?? defaultTextStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContent() {
    final hasIcon =
        widget.icon != null ||
        widget.iconWidget != null ||
        widget.svgPath != null ||
        widget.imagePath != null ||
        widget.loading;
    final hasText = widget.text != null && !widget.loading;

    if (!hasIcon && !hasText) {
      return const SizedBox.shrink();
    }

    if (hasIcon && !hasText) {
      return _buildIcon();
    }

    if (!hasIcon && hasText) {
      return _buildText();
    }

    // Both icon and text
    return widget.direction == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.contentAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: [
              _buildIcon(),
              SizedBox(width: widget.spacing),
              _buildText(),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.contentAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            children: [
              _buildIcon(),
              SizedBox(height: widget.spacing),
              _buildText(),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.width ?? widget.size;
    final effectiveHeight = widget.height ?? widget.size;
    final effectivePadding =
        widget.padding ??
        EdgeInsets.symmetric(
          horizontal: effectiveWidth != null ? 16 : 24,
          vertical: effectiveHeight != null ? 12 : 16,
        );

    // Duolingo-style: darker shade for bottom shadow
    final bottomColor =
        widget.shadowColor ??
        HSLColor.fromColor(widget.backgroundColor)
            .withLightness(
              (HSLColor.fromColor(widget.backgroundColor).lightness - 0.15)
                  .clamp(0.0, 1.0),
            )
            .toColor();

    // Calculate vertical offset based on press state
    final verticalOffset = _isPressed ? widget.shadowDepth : 0.0;

    // Calculate shadow height - shrinks when pressed
    final shadowHeight = _isPressed ? 0.0 : widget.shadowDepth;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: SizedBox(
          width: effectiveWidth,
          height: effectiveHeight != null
              ? effectiveHeight + widget.shadowDepth
              : null,
          child: Stack(
            children: [
              // Bottom shadow layer (Duolingo-style)
              if (widget.show3DEffect)
                AnimatedPositioned(
                  duration: widget.animationDuration,
                  curve: widget.animationCurve,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: widget.animationDuration,
                    curve: widget.animationCurve,
                    height: effectiveHeight != null
                        ? effectiveHeight + shadowHeight
                        : null,
                    decoration: BoxDecoration(
                      color: bottomColor,
                      borderRadius: widget.shape == BoxShape.rectangle
                          ? BorderRadius.circular(widget.borderRadius)
                          : null,
                      shape: widget.shape == BoxShape.circle
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                    ),
                  ),
                ),
              // Main button layer
              AnimatedPositioned(
                duration: widget.animationDuration,
                curve: widget.animationCurve,
                left: 0,
                right: 0,
                top: verticalOffset,
                child: Container(
                  width: effectiveWidth,
                  height: effectiveHeight,
                  padding: effectivePadding,
                  decoration: BoxDecoration(
                    shape: widget.shape,
                    borderRadius: widget.shape == BoxShape.rectangle
                        ? BorderRadius.circular(widget.borderRadius)
                        : null,
                    color: widget.gradient == null
                        ? widget.backgroundColor
                        : null,
                    gradient: widget.gradient,
                    border: widget.borderWidth > 0
                        ? Border.all(
                            color:
                                widget.borderColor ??
                                Colors.white.withValues(alpha: 0.3),
                            width: widget.borderWidth,
                          )
                        : null,
                  ),
                  child: Center(child: _buildContent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
