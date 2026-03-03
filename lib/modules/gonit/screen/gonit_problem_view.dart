import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

import '../bloc/gonit_bloc.dart';
import '../bloc/gonit_event.dart';
import '../bloc/gonit_state.dart';
import '../data/models/gonit_problem_model.dart';

// ════════════════════════════════════════════════════════════════
//  Wooden theme constants
// ════════════════════════════════════════════════════════════════
const _kWoodGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.3, 0.6, 1.0],
  colors: [
    Color(0xFFC9915A),
    Color(0xFFB07D48),
    Color(0xFFA06E3C),
    Color(0xFF8B5E34),
  ],
);

const _kWoodBorder = Color(0xFF5C3D1E);
const _kWoodText = Color(0xFF2E1A0E);
const _kWoodShadow = Color(0xFF3E2112);

const _kTextShadows = [
  Shadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x88000000)),
];

class GanitProblemScreen extends StatefulWidget {
  const GanitProblemScreen({super.key});

  @override
  State<GanitProblemScreen> createState() => _GanitProblemScreenState();
}

class _GanitProblemScreenState extends State<GanitProblemScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  // Shake animation for wrong matches
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int? _wrongMatchLeftId;

  // Glow animation for correct matches
  late AnimationController _glowController;


  // Drag-to-match line drawing
  int? _draggingLeftPairId;
  Offset? _dragLineStart;
  Offset? _dragLineEnd;
  final GlobalKey _matchAreaKey = GlobalKey();

  static const _backgroundImages = [
    Assets.imagesGkBg,
    Assets.imagesGkBg2,
    Assets.imagesGkBg3,
  ];

  String _getBackgroundForQuestion(GanitState state) {
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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    AudioService().resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocConsumer<GanitBloc, GanitState>(
        listener: (context, state) async {
          if (state is GanitLoaded) {
            // Detect wrong match for shake animation
            final wrongEntry = state.matchResults.entries
                .where((e) => e.value == false)
                .firstOrNull;
            if (wrongEntry != null && _wrongMatchLeftId != wrongEntry.key) {
              setState(() => _wrongMatchLeftId = wrongEntry.key);
              _shakeController.forward(from: 0).then((_) {
                if (mounted) setState(() => _wrongMatchLeftId = null);
              });
            }

            if (state.answerStatus == GanitAnswerStatus.correct) {
              _confettiController.play();
              await Future.delayed(const Duration(seconds: 2));
              if (!context.mounted) return;
              context.read<GanitBloc>().add(GanitNextProblem());
            }
          }

          if (state is GanitRoundCompleted) {
            if (!context.mounted) return;
            _showCompletionDialog(context, state);
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SizedBox(
              height: 1.sh,
              width: 1.sw,
              child: Stack(
                children: [
                  Image.asset(
                    _getBackgroundForQuestion(state),
                    fit: BoxFit.cover,
                    height: 1.sh,
                    width: 1.sw,
                  ),
                  _buildMainContent(state),
                  _buildMicButton(state),
                  _buildBottomButtons(state),
                  _buildCloseButton(),
                  _buildConfetti(),
                  if (state is GanitLoading) _buildLoadingOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MAIN CONTENT
  // ════════════════════════════════════════════════════════════════
  Widget _buildMainContent(GanitState state) {
    if (state is GanitLoading) return const SizedBox.shrink();

    if (state is GanitError) {
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
              onPressed: () => context.read<GanitBloc>().add(const GanitInit()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final currentProblem = state.currentProblem;
    if (currentProblem == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: 60.h,
        bottom: 120.h,
        left: 16.w,
        right: 16.w,
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuestionContainer(currentProblem),
              SizedBox(height: 16.h),

              if (currentProblem.questionImageUrl.isNotEmpty) ...[
                _buildQuestionImage(state, currentProblem.questionImageUrl),
                SizedBox(height: 12.h),
              ],

              // Content by type
              if (currentProblem.isMatchingType)
                _buildMatchingContent(state, currentProblem)
              else if (currentProblem.isOrderingType)
                _buildOrderingContent(state, currentProblem)
              else
                _buildMcqOptions(state),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  QUESTION CONTAINER — simple wooden plaque
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuestionContainer(GanitProblemModel problem) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _kWoodBorder.withValues(alpha: 0.3),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              problem.questionText,
              style: GoogleFonts.hindSiliguri(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF37474F),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (problem.questionAudioUrl.isNotEmpty) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => context.read<GanitBloc>().add(GanitReadQuestion()),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _kWoodBorder.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: _kWoodBorder,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionImage(GanitState state, String imageUrl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: state.answerStatus == GanitAnswerStatus.wrong
            ? Colors.red.withValues(alpha: 0.3)
            : state.answerStatus == GanitAnswerStatus.correct
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(8.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 0.6.sw,
          height: 0.2.sh,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            width: 0.6.sw,
            height: 0.2.sh,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MCQ OPTIONS — smart layout: grid for short, full-width for long
  // ════════════════════════════════════════════════════════════════
  Widget _buildMcqOptions(GanitState state) {
    final currentProblem = state.currentProblem;
    if (currentProblem == null) return const SizedBox.shrink();

    final options = currentProblem.options;
    final selectedOptionId = state.selectedOptionId;
    final answerStatus = state.answerStatus;
    final isDisabled = answerStatus != GanitAnswerStatus.none || state.isPlayingSkipAudio;
    final hasImages = options.any((o) => o.imageUrl.isNotEmpty);

    if (hasImages) {
      return _buildImageMcqGrid(
        options,
        selectedOptionId,
        answerStatus,
        isDisabled,
      );
    }

    // Short options (numbers / 1-3 chars) → 2x2 grid with big buttons
    final allShort = options.every((o) => o.text.trim().length <= 3);
    if (allShort) {
      return _buildShortMcqGrid(
        options,
        selectedOptionId,
        answerStatus,
        isDisabled,
      );
    }

    // Long text options → full-width vertical list
    return _buildLongMcqList(
      options,
      selectedOptionId,
      answerStatus,
      isDisabled,
    );
  }

  Widget _buildShortMcqGrid(
    List<GanitOptionModel> options,
    int? selectedOptionId,
    GanitAnswerStatus answerStatus,
    bool isDisabled,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14.w,
          mainAxisSpacing: 14.h,
          childAspectRatio: 1.3,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return _buildOptionButton(
            option: option,
            isSelected: selectedOptionId == option.id,
            answerStatus: answerStatus,
            isDisabled: isDisabled,
            fontSize: 36.sp,
            borderRadius: 20.r,
          );
        },
      ),
    );
  }

  Widget _buildLongMcqList(
    List<GanitOptionModel> options,
    int? selectedOptionId,
    GanitAnswerStatus answerStatus,
    bool isDisabled,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Column(
        children: options.map((option) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildOptionButton(
              option: option,
              isSelected: selectedOptionId == option.id,
              answerStatus: answerStatus,
              isDisabled: isDisabled,
              fontSize: 24.sp,
              height: 58.h,
              borderRadius: 16.r,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOptionButton({
    required GanitOptionModel option,
    required bool isSelected,
    required GanitAnswerStatus answerStatus,
    required bool isDisabled,
    required double fontSize,
    required double borderRadius,
    double? height,
  }) {
    Color? solidColor;
    Color borderColor = _kWoodBorder;

    if (isSelected && answerStatus == GanitAnswerStatus.correct) {
      solidColor = const Color(0xFF43A047);
      borderColor = const Color(0xFF2E7D32);
    } else if (isSelected && answerStatus == GanitAnswerStatus.wrong) {
      solidColor = const Color(0xFFD32F2F);
      borderColor = const Color(0xFFB71C1C);
    } else if (isSelected) {
      solidColor = const Color(0xFF1E88E5);
      borderColor = const Color(0xFF1565C0);
    }

    final isDefault = !isSelected;

    return TweenAnimationBuilder<double>(
      key: ValueKey('opt_${option.id}_$isSelected'),
      tween: Tween(begin: isSelected ? 0.92 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: GestureDetector(
        onTap: isDisabled
            ? null
            : () {

                context.read<GanitBloc>().add(GanitOptionSelected(option.id));
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: isDefault ? _kWoodGradient : null,
            color: isDefault ? null : solidColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 2.5.w),
            boxShadow: [
              BoxShadow(
                color: _kWoodShadow.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              option.text,
              style: GoogleFonts.hindSiliguri(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: _kTextShadows,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMcqGrid(
    List<GanitOptionModel> options,
    int? selectedOptionId,
    GanitAnswerStatus answerStatus,
    bool isDisabled,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.9,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedOptionId == option.id;

          Color? solidColor;
          Color borderColor = _kWoodBorder;
          Color textColor = _kWoodText;

          if (isSelected && answerStatus == GanitAnswerStatus.correct) {
            solidColor = const Color(0xFF43A047);
            borderColor = const Color(0xFF2E7D32);
            textColor = Colors.white;
          } else if (isSelected && answerStatus == GanitAnswerStatus.wrong) {
            solidColor = const Color(0xFFD32F2F);
            borderColor = const Color(0xFFB71C1C);
            textColor = Colors.white;
          } else if (isSelected) {
            solidColor = const Color(0xFF1E88E5);
            borderColor = const Color(0xFF1565C0);
            textColor = Colors.white;
          }

          final isDefault = !isSelected;

          return TweenAnimationBuilder<double>(
            key: ValueKey('opt_${option.id}_$isSelected'),
            tween: Tween(begin: isSelected ? 0.88 : 1.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
      
                      context.read<GanitBloc>().add(
                        GanitOptionSelected(option.id),
                      );
                    },
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isDefault ? _kWoodGradient : null,
                        color: isDefault
                            ? null
                            : solidColor?.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: borderColor,
                          width: isDefault ? 2.w : 3.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kWoodShadow.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13.r),
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
                  SizedBox(height: 6.h),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: isDefault ? _kWoodGradient : null,
                      color: isDefault ? null : solidColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: borderColor,
                        width: isDefault ? 1.5.w : 2.w,
                      ),
                    ),
                    child: Text(
                      option.text,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: isDefault ? Colors.white : textColor,
                        shadows: isDefault ? _kTextShadows : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MATCHING CONTENT (drag + tap, bounce, shake, glow)
  // ════════════════════════════════════════════════════════════════
  void _onMatchDragStart(int pairId, GanitProblemModel problem) {
    context.read<GanitBloc>().add(GanitMatchLeftSelected(pairId));

    // Calculate start position (right edge center of left item)
    final matchAreaBox =
        _matchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (matchAreaBox == null) return;

    final leftIndex = problem.matchPairs.indexWhere((p) => p.id == pairId);
    if (leftIndex == -1) return;

    final itemHeight = 56.h;
    final gap = 10.h;
    final leftColumnWidth = (matchAreaBox.size.width - 40.w) / 2;
    final startY = leftIndex * (itemHeight + gap) + itemHeight / 2;

    setState(() {
      _draggingLeftPairId = pairId;
      _dragLineStart = Offset(leftColumnWidth, startY);
      _dragLineEnd = Offset(leftColumnWidth, startY);
    });
  }

  void _onMatchDragUpdate(Offset globalPosition) {
    if (_draggingLeftPairId == null) return;
    final matchAreaBox =
        _matchAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (matchAreaBox == null) return;

    final localPos = matchAreaBox.globalToLocal(globalPosition);
    setState(() {
      _dragLineEnd = localPos;
    });
  }

  void _onMatchDragEnd(GanitProblemModel problem) {
    if (_draggingLeftPairId == null) return;

    // Check if the drag ended over a right item
    if (_dragLineEnd != null) {
      final matchAreaBox =
          _matchAreaKey.currentContext?.findRenderObject() as RenderBox?;
      if (matchAreaBox != null) {
        final itemHeight = 56.h;
        final gap = 10.h;
        final leftColumnWidth = (matchAreaBox.size.width - 40.w) / 2;
        final rightColumnStart = leftColumnWidth + 40.w;
        final state = context.read<GanitBloc>().state;
        final shuffledRightIds = state.shuffledRightIds;

        // Check if end position is within right column
        if (_dragLineEnd!.dx >= rightColumnStart - 20.w) {
          final rightItems = shuffledRightIds
              .map((id) => problem.matchPairs.firstWhere((p) => p.id == id))
              .toList();

          for (int i = 0; i < rightItems.length; i++) {
            final itemTop = i * (itemHeight + gap);
            final itemBottom = itemTop + itemHeight;
            if (_dragLineEnd!.dy >= itemTop && _dragLineEnd!.dy <= itemBottom) {
              // Found the target right item
              context.read<GanitBloc>().add(
                GanitMatchRightSelected(
                  rightItems[i].id,
                  leftPairId: _draggingLeftPairId,
                ),
              );
              break;
            }
          }
        }
      }
    }

    setState(() {
      _draggingLeftPairId = null;
      _dragLineStart = null;
      _dragLineEnd = null;
    });
  }

  Widget _buildMatchingContent(GanitState state, GanitProblemModel problem) {
    final matchPairs = problem.matchPairs;
    final shuffledRightIds = state.shuffledRightIds;
    final selectedLeftId = state.selectedLeftId;
    final matchedPairs = state.matchedPairs;
    final matchResults = state.matchResults;

    final itemHeight = 56.h;
    final gap = 10.h;
    final totalHeight = matchPairs.length * (itemHeight + gap) - gap;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Listener(
        onPointerMove: (event) => _onMatchDragUpdate(event.position),
        onPointerUp: (_) => _onMatchDragEnd(problem),
        child: SizedBox(
          key: _matchAreaKey,
          height: totalHeight,
          child: Stack(
            children: [
              // Completed match lines
              CustomPaint(
                size: Size(double.infinity, totalHeight),
                painter: _MatchLinePainter(
                  matchPairs: matchPairs,
                  shuffledRightIds: shuffledRightIds,
                  matchedPairs: matchedPairs,
                  matchResults: matchResults,
                  itemHeight: itemHeight,
                  gap: gap,
                ),
              ),
              // Active drag line
              if (_dragLineStart != null && _dragLineEnd != null)
                CustomPaint(
                  size: Size(double.infinity, totalHeight),
                  painter: _DragLinePainter(
                    start: _dragLineStart!,
                    end: _dragLineEnd!,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: matchPairs.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final pair = entry.value;
                        final isSelected = selectedLeftId == pair.id;
                        final isDragging = _draggingLeftPairId == pair.id;
                        final isMatched = matchResults[pair.id] == true;
                        final isWrong = matchResults[pair.id] == false;
                        final isDefault =
                            !isMatched && !isWrong && !isSelected && !isDragging;
                        final isShaking = _wrongMatchLeftId == pair.id;

                        Color? solidColor;
                        Color borderColor = _kWoodBorder;

                        if (isMatched) {
                          solidColor = const Color(0xFF43A047);
                          borderColor = const Color(0xFF2E7D32);
                        } else if (isWrong) {
                          solidColor = const Color(0xFFD32F2F);
                          borderColor = const Color(0xFFB71C1C);
                        } else if (isSelected || isDragging) {
                          solidColor = const Color(0xFF1E88E5);
                          borderColor = const Color(0xFF1565C0);
                        }

                        Widget card = AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: itemHeight,
                          decoration: BoxDecoration(
                            gradient: isDefault ? _kWoodGradient : null,
                            color: isDefault ? null : solidColor,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: borderColor, width: 2.w),
                            boxShadow: [
                              BoxShadow(
                                color: _kWoodShadow.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                              if (isDefault)
                                BoxShadow(
                                  color: const Color(
                                    0xFFEDD5B3,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 3,
                                  offset: const Offset(-1, -1),
                                ),
                              if (isMatched)
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              pair.left,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: _kTextShadows,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );

                        if (isShaking) {
                          card = AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: child,
                            ),
                            child: card,
                          );
                        }

                        card = TweenAnimationBuilder<double>(
                          key: ValueKey('left_${pair.id}_$isSelected'),
                          tween: Tween(
                              begin: isSelected ? 0.88 : 1.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: card,
                        );

                        // Staggered pop-in
                        card = TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + idx * 80),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) => Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: value.clamp(0.5, 1.0),
                              child: child,
                            ),
                          ),
                          child: card,
                        );

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: pair != matchPairs.last ? gap : 0,
                          ),
                          child: isMatched
                              ? card
                              : GestureDetector(
                                  onTap: () {
                    
                                    context.read<GanitBloc>().add(
                                      GanitMatchLeftSelected(pair.id),
                                    );
                                  },
                                  onLongPressStart: (_) {
                                    _onMatchDragStart(pair.id, problem);
                                  },
                                  child: card,
                                ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(width: 40.w),

                  // Right column
                  Expanded(
                    child: Column(
                      children: () {
                        final rightItems = shuffledRightIds
                            .map((id) =>
                                matchPairs.firstWhere((p) => p.id == id))
                            .toList();

                        return rightItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pair = entry.value;
                          final isMatched = matchedPairs.entries.any(
                            (e) =>
                                e.value == pair.id &&
                                matchResults[e.key] == true,
                          );
                          final isWrong = matchedPairs.entries.any(
                            (e) =>
                                e.value == pair.id &&
                                matchResults[e.key] == false,
                          );
                          final isDefault = !isMatched && !isWrong;

                          // Check if drag line is hovering over this item
                          final isHovering = _draggingLeftPairId != null &&
                              _dragLineEnd != null &&
                              () {
                                final matchAreaBox = _matchAreaKey
                                    .currentContext
                                    ?.findRenderObject() as RenderBox?;
                                if (matchAreaBox == null) return false;
                                final leftColumnWidth =
                                    (matchAreaBox.size.width - 40.w) / 2;
                                final rightColumnStart =
                                    leftColumnWidth + 40.w;
                                final itemTop = idx * (itemHeight + gap);
                                final itemBottom = itemTop + itemHeight;
                                return _dragLineEnd!.dx >=
                                        rightColumnStart - 20.w &&
                                    _dragLineEnd!.dy >= itemTop &&
                                    _dragLineEnd!.dy <= itemBottom;
                              }();

                          Color? solidColor;
                          Color borderColor = _kWoodBorder;

                          if (isMatched) {
                            solidColor = const Color(0xFF43A047);
                            borderColor = const Color(0xFF2E7D32);
                          } else if (isWrong) {
                            solidColor = const Color(0xFFD32F2F);
                            borderColor = const Color(0xFFB71C1C);
                          }

                          Widget rightCard = AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: itemHeight,
                            decoration: BoxDecoration(
                              gradient: isDefault && !isHovering
                                  ? _kWoodGradient
                                  : null,
                              color: isDefault
                                  ? (isHovering
                                      ? const Color(0xFFBBDEFB)
                                      : null)
                                  : solidColor,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isHovering
                                    ? const Color(0xFF2196F3)
                                    : borderColor,
                                width: isHovering ? 3.w : 2.w,
                              ),
                              boxShadow: [
                                if (isHovering)
                                  BoxShadow(
                                    color:
                                        Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                else
                                  BoxShadow(
                                    color: _kWoodShadow.withValues(
                                        alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                if (isDefault && !isHovering)
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEDD5B3,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 3,
                                    offset: const Offset(-1, -1),
                                  ),
                                if (isMatched)
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                pair.right,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isHovering
                                      ? const Color(0xFF1565C0)
                                      : Colors.white,
                                  shadows:
                                      isHovering ? null : _kTextShadows,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: pair != rightItems.last ? gap : 0,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration:
                                  Duration(milliseconds: 300 + idx * 80),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) => Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: value.clamp(0.5, 1.0),
                                  child: child,
                                ),
                              ),
                              child: GestureDetector(
                                onTap: () {
                  
                                  context.read<GanitBloc>().add(
                                    GanitMatchRightSelected(pair.id),
                                  );
                                },
                                child: rightCard,
                              ),
                            ),
                          );
                        }).toList();
                      }(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  ORDERING CONTENT (drag items into slots)
  // ════════════════════════════════════════════════════════════════
  Widget _buildOrderingContent(GanitState state, GanitProblemModel problem) {
    final orderItems = problem.orderItems;
    final placedItems = state.placedItems;
    final shuffledIds = state.shuffledOrderIds;
    final slotCount = orderItems.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: [
          // Target slots
          SizedBox(
            height: 70.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slotCount, (slotIndex) {
                final placedItemId = placedItems[slotIndex];
                final placedItem = placedItemId != null
                    ? orderItems.firstWhere((i) => i.id == placedItemId)
                    : null;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: DragTarget<int>(
                    onWillAcceptWithDetails: (_) => true,
                    onAcceptWithDetails: (details) {
      
                      context.read<GanitBloc>().add(
                        GanitOrderItemPlaced(details.data, slotIndex),
                      );
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isHovering = candidateData.isNotEmpty;

                      return GestureDetector(
                        onTap: placedItem != null
                            ? () {
                                context.read<GanitBloc>().add(
                                  GanitOrderItemRemoved(slotIndex),
                                );
                              }
                            : null,
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('slot_${slotIndex}_$placedItemId'),
                          tween: Tween(
                            begin: placedItem != null ? 0.85 : 1.0,
                            end: 1.0,
                          ),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 62.w,
                            height: 62.h,
                            decoration: BoxDecoration(
                              gradient: placedItem != null
                                  ? _kWoodGradient
                                  : null,
                              color: placedItem == null
                                  ? (isHovering
                                        ? const Color(0xFFBBDEFB)
                                        : _kWoodBorder.withValues(alpha: 0.15))
                                  : null,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isHovering
                                    ? const Color(0xFF2196F3)
                                    : _kWoodBorder,
                                width: 2.w,
                              ),
                              boxShadow: placedItem != null
                                  ? [
                                      BoxShadow(
                                        color: _kWoodShadow.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: placedItem != null
                                  ? Text(
                                      placedItem.text,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        shadows: _kTextShadows,
                                      ),
                                    )
                                  : Text(
                                      '${slotIndex + 1}',
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: _kWoodBorder.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),

          SizedBox(height: 24.h),

          // Draggable items
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.w,
            runSpacing: 12.h,
            children: shuffledIds.map((itemId) {
              final item = orderItems.firstWhere((i) => i.id == itemId);
              final isPlaced = placedItems.values.contains(itemId);
              final itemIndex = shuffledIds.indexOf(itemId);

              if (isPlaced) {
                return Opacity(
                  opacity: 0.25,
                  child: Container(
                    width: 62.w,
                    height: 62.h,
                    decoration: BoxDecoration(
                      color: _kWoodBorder.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _kWoodBorder.withValues(alpha: 0.3),
                        width: 1.5.w,
                      ),
                    ),
                  ),
                );
              }

              return LongPressDraggable<int>(
                data: item.id,
                delay: const Duration(milliseconds: 150),
                hapticFeedbackOnStart: true,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 68.w,
                    height: 68.h,
                    decoration: BoxDecoration(
                      gradient: _kWoodGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFF2196F3),
                        width: 2.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        item.text,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: _kTextShadows,
                        ),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: Container(
                    width: 62.w,
                    height: 62.h,
                    decoration: BoxDecoration(
                      color: _kWoodBorder.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (itemIndex * 80)),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value.clamp(0.5, 1.0),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 62.w,
                    height: 62.h,
                    decoration: BoxDecoration(
                      gradient: _kWoodGradient,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _kWoodBorder, width: 2.w),
                      boxShadow: [
                        BoxShadow(
                          color: _kWoodShadow.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: const Color(0xFFEDD5B3).withValues(alpha: 0.3),
                          blurRadius: 3,
                          offset: const Offset(-1, -1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        item.text,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: _kTextShadows,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  MIC BUTTON
  // ════════════════════════════════════════════════════════════════
  Widget _buildMicButton(GanitState state) {
    if (state.currentProblem?.isMatchingType == true ||
        state.currentProblem?.isOrderingType == true) {
      return const SizedBox.shrink();
    }

    final isDisabled =
        state.isValidating ||
        state.isListening ||
        _isPlayingFeedbackAudio ||
        state.isPlayingSkipAudio ||
        state.answerStatus != GanitAnswerStatus.none ||
        state is GanitLoading;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 140.h),
        child: IgnorePointer(
          ignoring: isDisabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isListening)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hearing, color: Colors.white, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'শুনছি...',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

  bool get _isPlayingFeedbackAudio =>
      context.read<GanitBloc>().state.answerStatus != GanitAnswerStatus.none;

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM BUTTONS / CLOSE / CONFETTI / LOADING
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomButtons(GanitState state) {
    final isDisabled =
        state is GanitLoading ||
        state.isPlayingSkipAudio ||
        state.answerStatus != GanitAnswerStatus.none;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 30.h),
        child: IgnorePointer(
          ignoring: isDisabled,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GamingImageButton(
                imagePath: Assets.imagesRetryButton,
                width: 0.32.sw,
                onPressed: () => context.read<GanitBloc>().add(GanitRetry()),
              ),
              const SizedBox(width: 20),
              GamingImageButton(
                imagePath: Assets.imagesArrowRight,
                width: 0.32.sw,
                onPressed: () =>
                    context.read<GanitBloc>().add(GanitSkipProblem()),
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
            context.read<GanitBloc>().add(GanitStop());
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
              'Loading problems...',
              style: GoogleFonts.nunito(fontSize: 18.sp, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMPLETION DIALOG
  // ════════════════════════════════════════════════════════════════
  void _showCompletionDialog(BuildContext context, GanitRoundCompleted state) {
    final stars = state.roundStars;
    final accuracy = state.roundAnswered > 0
        ? (state.roundCorrect / state.roundAnswered * 100).round()
        : 0;

    _confettiController.play();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFC107)],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isEarned = i < stars;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Icon(
                    isEarned ? Icons.star : Icons.star_border,
                    color: isEarned ? Colors.deepOrange : Colors.orange[200],
                    size: i == 1 ? 55.sp : 40.sp,
                  ),
                );
              }),
            ),
            SizedBox(height: 16.h),
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
            Text(
              stars >= 2 ? 'অসাধারণ!' : 'চেষ্টা করো!',
              style: GoogleFonts.hindSiliguri(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  _statRow(
                    'সঠিক',
                    '${state.roundCorrect}/${state.roundAnswered}',
                  ),
                  SizedBox(height: 8.h),
                  _statRow('নির্ভুলতা', '$accuracy%'),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                UniversalGamingButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<GanitBloc>().add(GanitPlayAgain());
                  },
                  text: 'আবার খেলো',
                  icon: Icons.replay_rounded,
                  width: 0.4.sw,
                  height: 50.h,
                  backgroundColor: const Color(0xFF4CAF50),
                  textStyle: GoogleFonts.hindSiliguri(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  iconColor: Colors.white,
                  iconSize: 24.sp,
                  borderRadius: 14.r,
                ),
                UniversalGamingButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.pop();
                  },
                  text: 'ফিরে যাও',
                  icon: Icons.home_rounded,
                  width: 0.4.sw,
                  height: 50.h,
                  backgroundColor: const Color(0xFFFF5722),
                  textStyle: GoogleFonts.hindSiliguri(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  iconColor: Colors.white,
                  iconSize: 24.sp,
                  borderRadius: 14.r,
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.brown[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.hindSiliguri(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.brown[900],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  CustomPainter: draws curved lines between matched pairs
// ════════════════════════════════════════════════════════════════
class _MatchLinePainter extends CustomPainter {
  final List<GanitMatchPairModel> matchPairs;
  final List<int> shuffledRightIds;
  final Map<int, int> matchedPairs;
  final Map<int, bool> matchResults;
  final double itemHeight;
  final double gap;

  _MatchLinePainter({
    required this.matchPairs,
    required this.shuffledRightIds,
    required this.matchedPairs,
    required this.matchResults,
    required this.itemHeight,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final halfWidth = size.width / 2;
    const centerGap = 40.0;

    for (final entry in matchedPairs.entries) {
      final leftId = entry.key;
      final rightId = entry.value;
      final isCorrect = matchResults[leftId] == true;

      final leftIndex = matchPairs.indexWhere((p) => p.id == leftId);
      final rightIndex = shuffledRightIds.indexOf(rightId);

      if (leftIndex == -1 || rightIndex == -1) continue;

      final leftY = leftIndex * (itemHeight + gap) + itemHeight / 2;
      final rightY = rightIndex * (itemHeight + gap) + itemHeight / 2;

      final leftX = halfWidth - centerGap / 2;
      final rightX = halfWidth + centerGap / 2;

      if (isCorrect) {
        final glowPaint = Paint()
          ..color = const Color(0xFF4CAF50).withValues(alpha: 0.25)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

        final glowPath = Path()
          ..moveTo(leftX, leftY)
          ..cubicTo(
            leftX + (rightX - leftX) * 0.4,
            leftY,
            rightX - (rightX - leftX) * 0.4,
            rightY,
            rightX,
            rightY,
          );
        canvas.drawPath(glowPath, glowPaint);
      }

      final paint = Paint()
        ..color = isCorrect
            ? const Color(0xFF4CAF50).withValues(alpha: 0.9)
            : const Color(0xFFE53935).withValues(alpha: 0.8)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(leftX, leftY)
        ..cubicTo(
          leftX + (rightX - leftX) * 0.4,
          leftY,
          rightX - (rightX - leftX) * 0.4,
          rightY,
          rightX,
          rightY,
        );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MatchLinePainter oldDelegate) {
    return matchedPairs != oldDelegate.matchedPairs ||
        matchResults != oldDelegate.matchResults;
  }
}

// ════════════════════════════════════════════════════════════════
//  CustomPainter: draws the active drag line from left item to finger
// ════════════════════════════════════════════════════════════════
class _DragLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  _DragLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.25)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

    final dx = (end.dx - start.dx).abs() * 0.4;
    final glowPath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + dx,
        start.dy,
        end.dx - dx,
        end.dy,
        end.dx,
        end.dy,
      );
    canvas.drawPath(glowPath, glowPaint);

    // Line
    final paint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + dx,
        start.dy,
        end.dx - dx,
        end.dy,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);

    // Small dot at the end
    final dotPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, 6.0, dotPaint);

    // Dot outline
    final dotOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(end, 6.0, dotOutline);
  }

  @override
  bool shouldRepaint(covariant _DragLinePainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}
