import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/banan/data/models/banan_data_model.dart';
import 'package:kids_learning/modules/banan/data/repo/banan_repo.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

import '../bloc/banan_bloc.dart';
import '../bloc/banan_event.dart';
import '../bloc/banan_state.dart';

// ════════════════════════════════════════════════════════════════
//  Theme constants
// ════════════════════════════════════════════════════════════════
const _kWood = LinearGradient(
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
const _kWoodShadow = Color(0xFF3E2112);
const _kCorrectGreen = Color(0xFF43A047);
const _kWrongRed = Color(0xFFD32F2F);
const _kSlotBlue = Color(0xFF1E88E5);

const _kTextShadow = [
  Shadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x88000000)),
];

// ════════════════════════════════════════════════════════════════
//  Screen  — navigates directly, no wrapper needed
// ════════════════════════════════════════════════════════════════
class BananProblemScreen extends StatefulWidget {
  const BananProblemScreen({super.key});

  @override
  State<BananProblemScreen> createState() => _BananProblemScreenState();
}

class _BananProblemScreenState extends State<BananProblemScreen>
    with TickerProviderStateMixin {
  // ── Bloc owned by this State ──────────────────────────────────
  late final BananBloc _bloc;

  // ── Animations ───────────────────────────────────────────────
  late ConfettiController _confetti;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _bounceCtrl;

  static const _backgrounds = [
    Assets.imagesGkBg,
    Assets.imagesGkBg2,
    Assets.imagesGkBg3,
  ];

  String _bg(int index) => _backgrounds[index % _backgrounds.length];

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    _bloc = BananBloc(repository: BananRepository())..add(const BananInit());

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _bloc.close();
    _confetti.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    AudioService().resume();
    super.dispose();
  }

  void _resetBounce() {
    _bounceCtrl.reset();
    _bounceCtrl.forward();
  }

  // ── Tap-to-place: fills the next empty slot left → right ──────
  void _tapToPlace(BananLoaded state, String tileId) {
    if (state.answerStatus != BananAnswerStatus.none) return;
    final emptySlots =
        state.slotMap.entries
            .where((e) => e.value == null)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (emptySlots.isEmpty) return;
    _bloc.add(BananTilePlaced(tileId, emptySlots.first));
  }

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: PopScope(
        canPop: false,
        child: BlocConsumer<BananBloc, BananState>(
          listener: _listener,
          builder: (context, state) {
            final bgIndex = state is BananLoaded ? state.currentIndex : 0;

            return Scaffold(
              body: SizedBox(
                height: 1.sh,
                width: 1.sw,
                child: Stack(
                  children: [
                    Image.asset(
                      _bg(bgIndex),
                      fit: BoxFit.cover,
                      height: 1.sh,
                      width: 1.sw,
                    ),
                    _buildContent(context, state),
                    _buildBottomBar(context, state),
                    _buildCloseBtn(context),
                    _buildConfetti(),
                    if (state is BananInitial || state is BananLoading)
                      _buildLoading(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  LISTENER
  // ════════════════════════════════════════════════════════════════
  void _listener(BuildContext ctx, BananState state) async {
    if (state is BananLoaded) {
      if (state.answerStatus == BananAnswerStatus.correct) {
        _confetti.play();
        await Future.delayed(const Duration(milliseconds: 1800));
        if (!ctx.mounted) return;
        _bloc.add(const BananNextProblem());
        _resetBounce();
      } else if (state.answerStatus == BananAnswerStatus.wrong) {
        _shakeCtrl.forward(from: 0);
      }
    }
    if (state is BananRoundCompleted) {
      if (!ctx.mounted) return;
      _showCompletionSheet(ctx, state);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  CONTENT
  // ════════════════════════════════════════════════════════════════
  Widget _buildContent(BuildContext context, BananState state) {
    if (state is BananInitial || state is BananLoading) {
      return const SizedBox.shrink();
    }

    if (state is BananError) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text(
                state.errorMessage ?? 'Something went wrong',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => _bloc.add(const BananInit()),
                child: Text(
                  'আবার চেষ্টা করো',
                  style: GoogleFonts.hindSiliguri(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final problem = state.currentProblem;
    if (problem == null || state is! BananLoaded)
      return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: 85.h,
        bottom:
            140.h, // Increased padding to prevent overlap with bottom buttons
        left: 16.w,
        right: 16.w,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildQuestionCard(state, problem),
            SizedBox(height: 14.h),
            if (problem.questionImageUrl.isNotEmpty) ...[
              _buildImage(state, problem.questionImageUrl),
              SizedBox(height: 25.h),
            ],
            _buildSlots(state, problem),
            SizedBox(height: 24.h),
            _buildTileBank(state, problem),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  QUESTION CARD
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuestionCard(BananLoaded state, BananProblemModel problem) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _kWoodBorder.withValues(alpha: 0.25),
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
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF37474F),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (problem.questionAudioUrl.isNotEmpty) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _bloc.add(const BananReadQuestion()),
              child: AnimatedBuilder(
                animation: state.isPlayingAudio
                    ? _pulseCtrl
                    : kAlwaysDismissedAnimation,
                builder: (_, child) => Transform.scale(
                  scale: state.isPlayingAudio ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: state.isPlayingAudio
                        ? _kSlotBlue.withValues(alpha: 0.15)
                        : _kWoodBorder.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: state.isPlayingAudio ? _kSlotBlue : _kWoodBorder,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  IMAGE
  // ════════════════════════════════════════════════════════════════
  Widget _buildImage(BananLoaded state, String url) {
    Color borderColor = Colors.transparent;
    double borderWidth = 0;
    if (state.answerStatus == BananAnswerStatus.correct) {
      borderColor = _kCorrectGreen;
      borderWidth = 3.w;
    } else if (state.answerStatus == BananAnswerStatus.wrong) {
      borderColor = _kWrongRed;
      borderWidth = 3.w;
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (state.answerStatus == BananAnswerStatus.correct)
              BoxShadow(
                color: _kCorrectGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              )
            else if (state.answerStatus == BananAnswerStatus.wrong)
              BoxShadow(
                color: _kWrongRed.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 0.55.sw,
            height: 0.55.sw,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 0.55.sw,
              height: 0.22.sh,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 0.55.sw,
              height: 0.22.sh,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, size: 40.sp),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SLOTS — tap filled slot to undo
  // ════════════════════════════════════════════════════════════════
  Widget _buildSlots(BananLoaded state, BananProblemModel problem) {
    final letters = problem.letters;
    final slotSize = _slotSizeFor(letters.length);
    final isCorrect = state.answerStatus == BananAnswerStatus.correct;
    final isWrong = state.answerStatus == BananAnswerStatus.wrong;

    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: Offset(isWrong ? _shake.value : 0, 0),
        child: child,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (i) {
            final tileId = state.slotMap[i];
            final tile = tileId != null
                ? state.availableTiles.firstWhere(
                    (t) => t.id == tileId,
                    orElse: () => const BananLetterTile(id: '', letter: ''),
                  )
                : null;
            final isFilled = tile != null && tile.id.isNotEmpty;

            Color slotColor;
            Color slotBorder;
            Color textColor;

            if (isFilled && isCorrect) {
              slotColor = _kCorrectGreen;
              slotBorder = const Color(0xFF2E7D32);
              textColor = Colors.white;
            } else if (isFilled && isWrong) {
              slotColor = _kWrongRed;
              slotBorder = const Color(0xFFB71C1C);
              textColor = Colors.white;
            } else if (isFilled) {
              slotColor = _kSlotBlue;
              slotBorder = const Color(0xFF1565C0);
              textColor = Colors.white;
            } else {
              slotColor = const Color.fromARGB(
                255,
                255,
                210,
                181,
              ).withValues(alpha: 0.95);
              slotBorder = const Color.fromARGB(
                255,
                0,
                20,
                70,
              ).withValues(alpha: 0.8);
              textColor = Colors.transparent;
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: DragTarget<String>(
                onWillAcceptWithDetails: (_) =>
                    !isFilled && state.answerStatus == BananAnswerStatus.none,
                onAcceptWithDetails: (details) =>
                    _bloc.add(BananTilePlaced(details.data, i)),
                builder: (ctx, candidates, _) {
                  final hovering = candidates.isNotEmpty;
                  return GestureDetector(
                    onTap:
                        isFilled && state.answerStatus == BananAnswerStatus.none
                        ? () => _bloc.add(BananTileRemoved(i))
                        : null,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('slot_${i}_$tileId'),
                      tween: Tween(begin: isFilled ? 0.7 : 1.0, end: 1.0),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: slotSize,
                        height: slotSize,
                        decoration: BoxDecoration(
                          color: hovering ? const Color(0xFFBBDEFB) : slotColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: hovering
                                ? const Color(0xFF2196F3)
                                : slotBorder,
                            width: hovering ? 2.5.w : 2.w,
                          ),
                          boxShadow: [
                            if (isFilled && isCorrect)
                              BoxShadow(
                                color: _kCorrectGreen.withValues(alpha: 0.45),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            else if (hovering)
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 12,
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: isFilled
                              ? Text(
                                  tile!.letter,
                                  style: _letterStyle(
                                    _fontSizeFor(tile.letter, slotSize),
                                    textColor,
                                  ),
                                )
                              : Text(
                                  '_',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: slotSize * 0.4,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withValues(alpha: 0.7),
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
    );
  }

  double _slotSizeFor(int count) {
    if (count <= 3) return 72.w;
    if (count <= 5) return 60.w;
    if (count <= 7) return 50.w;
    return 42.w;
  }

  /// Shrinks font for Bengali grapheme clusters that contain matras
  double _fontSizeFor(String letter, double slotSize) {
    final units = letter.length; // code units
    if (units >= 3) return slotSize * 0.38;
    if (units == 2) return slotSize * 0.44;
    return slotSize * 0.52;
  }

  TextStyle _letterStyle(double size, Color color) => GoogleFonts.hindSiliguri(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    shadows: _kTextShadow,
  );

  // ════════════════════════════════════════════════════════════════
  //  TILE BANK — tap to place in next empty slot
  // ════════════════════════════════════════════════════════════════
  Widget _buildTileBank(BananLoaded state, BananProblemModel problem) {
    final unused = state.unusedTiles;
    final slotSize = _slotSizeFor(problem.letters.length);
    final isDisabled = state.answerStatus != BananAnswerStatus.none;

    return Column(
      children: [
        Container(
          width: 80.w,
          height: 2.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(height: 16.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: state.availableTiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              final isPlaced = !unused.any((t) => t.id == tile.id);

              if (isPlaced) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Opacity(
                    opacity: 0.0,
                    child: SizedBox(width: slotSize, height: slotSize),
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('tile_${tile.id}_bounce'),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + idx * 60),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(
                    scale: v.clamp(0.4, 1.0),
                    child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
                  ),
                  child: isDisabled
                      ? _tileWidget(tile, slotSize)
                      : GestureDetector(
                          onTap: () => _tapToPlace(state, tile.id),
                          child: Draggable<String>(
                            data: tile.id,
                            feedback: Material(
                              color: Colors.transparent,
                              child: _tileFeedback(tile, slotSize),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.2,
                              child: _tileWidget(tile, slotSize),
                            ),
                            child: _tileWidget(tile, slotSize),
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tileWidget(BananLetterTile tile, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _kWood,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _kWoodBorder, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: _kWoodShadow.withValues(alpha: 0.4),
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
          tile.letter,
          style: _letterStyle(_fontSizeFor(tile.letter, size), Colors.white),
        ),
      ),
    );
  }

  Widget _tileFeedback(BananLetterTile tile, double size) {
    return Container(
      width: size * 1.15,
      height: size * 1.15,
      decoration: BoxDecoration(
        gradient: _kWood,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFF2196F3), width: 2.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          tile.letter,
          style: _letterStyle(
            _fontSizeFor(tile.letter, size * 1.15),
            Colors.white,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  BOTTOM BAR
  // ════════════════════════════════════════════════════════════════
  Widget _buildBottomBar(BuildContext context, BananState state) {
    final isDisabled =
        state is BananInitial ||
        state is BananLoading ||
        state.answerStatus != BananAnswerStatus.none;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 28.h),
        child: IgnorePointer(
          ignoring: isDisabled,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GamingImageButton(
                imagePath: Assets.imagesRetryButton,
                width: 0.32.sw,
                onPressed: () => _bloc.add(const BananRetry()),
              ),
              const SizedBox(width: 20),
              GamingImageButton(
                imagePath: Assets.imagesArrowRight,
                width: 0.32.sw,
                onPressed: () => _bloc.add(const BananSkipProblem()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseBtn(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 10.w, top: 15.h),
        child: GamingImageButton(
          width: 0.18.sw,
          imagePath: Assets.imagesCrossIcon,
          onPressed: () {
            _bloc.add(const BananStop());
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
        confettiController: _confetti,
        blastDirection: pi / 2,
        maxBlastForce: 6,
        minBlastForce: 2,
        emissionFrequency: 0.06,
        numberOfParticles: 25,
        gravity: 0.25,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.yellow,
          Colors.cyan,
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16.h),
            Text(
              'লোড হচ্ছে...',
              style: GoogleFonts.hindSiliguri(
                fontSize: 18.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMPLETION SHEET
  // ════════════════════════════════════════════════════════════════
  void _showCompletionSheet(BuildContext context, BananRoundCompleted state) {
    final stars = state.roundStars;
    final accuracy = state.roundAnswered > 0
        ? (state.roundCorrect / state.roundAnswered * 100).round()
        : 0;
    _confetti.play();

    final isAllExhausted = state.isAllQuestionsExhausted;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dlgCtx) => Container(
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
                final earned = i < stars;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Icon(
                    earned ? Icons.star : Icons.star_border,
                    color: earned ? Colors.deepOrange : Colors.orange[200],
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
              isAllExhausted
                  ? 'সব প্রশ্ন শেষ! 🎉'
                  : (stars >= 2 ? 'চমৎকার! 🎉' : 'আরও চেষ্টা করো!'),
              style: GoogleFonts.hindSiliguri(
                fontSize: 30.sp,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 12.h),
            if (!isAllExhausted) ...[
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
            ] else ...[
              SizedBox(height: 16.h),
              Text(
                'তুমি সব প্রশ্নের উত্তর দিয়েছো!',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18.sp,
                  color: Colors.brown[700],
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _statRow(
                      'মোট প্রশ্ন',
                      '${state.roundAnswered}',
                    ),
                    SizedBox(height: 8.h),
                    _statRow('সঠিক', '${state.roundCorrect}'),
                    SizedBox(height: 8.h),
                    _statRow('নির্ভুলতা', '$accuracy%'),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                UniversalGamingButton(
                  onPressed: () {
                    Navigator.of(dlgCtx).pop();
                    _bloc.add(const BananPlayAgain());
                  },
                  text: 'আবার খেলো',
                  icon: Icons.replay_rounded,
                  width: 0.4.sw,
                  height: 50.h,
                  backgroundColor: _kCorrectGreen,
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
                    Navigator.of(dlgCtx).pop();
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
