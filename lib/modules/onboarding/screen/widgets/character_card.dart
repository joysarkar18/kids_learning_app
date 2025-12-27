import 'package:audioplayers/audioplayers.dart'; // 1. Import this
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/modules/onboarding/data/models/character_model.dart';

class CharacterCard extends StatefulWidget {
  final CharacterModel character;
  final bool isSelected;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // 3. Create the AudioPlayer instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 4. Dispose player
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        AudioPlayerService.instance.playLocalized(
          context: context,
          key: widget.character.audioKey,
        );
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? const Color.fromARGB(
                            255,
                            150,
                            138,
                            238,
                          ).withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: widget.isSelected ? 20 : 10,
                    offset: Offset(0, widget.isSelected ? 8 : 4),
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFF5C4BDB)
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Character Image Container
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: widget.character.backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AnimatedScale(
                          scale: widget.isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Image.asset(
                            widget.character.imagePath,
                            width: 80.w,
                            height: 80.w,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 60.sp,
                                color: Colors.grey.shade400,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Character Name
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Text(
                      widget.character.name,
                      style: GoogleFonts.bubblegumSans(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? const Color(0xFF5C4BDB)
                            : const Color(0xFF424242),
                      ),
                    ),
                  ),

                  // Selected Indicator
                  if (widget.isSelected)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: const AnimatedCheckmark(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({super.key});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: const BoxDecoration(
          color: Color(0xFF5C4BDB),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: Colors.white, size: 18.sp),
      ),
    );
  }
}
