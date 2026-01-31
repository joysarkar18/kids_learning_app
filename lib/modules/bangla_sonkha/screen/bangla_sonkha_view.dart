import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/bornomala/screen/writing_screen.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/bangla_sonkha_bloc.dart';
import '../bloc/bangla_sonkha_event.dart';
import '../bloc/bangla_sonkha_state.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class BanglaSonkhaScreen extends StatefulWidget {
  const BanglaSonkhaScreen({super.key});

  @override
  State<BanglaSonkhaScreen> createState() => _BanglaSonkhaScreenState();
}

class _BanglaSonkhaScreenState extends State<BanglaSonkhaScreen> {
  late ConfettiController _confettiController;

  static const _boardImages = [
    Assets.imagesChikuBlackBoard,
    Assets.imagesCowBoard,
    Assets.imagesDogBoard,
    Assets.imagesFoxBoard,
    Assets.imagesOwlBoard,
    Assets.imagesDonkiBoard,
    Assets.imagesElephantBoard,
  ];

  // Pre-assigned random board image per number index
  late final List<int> _boardImageIndices;

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    // Assign a random board image to each number once, so it stays stable
    final random = Random();
    _boardImageIndices = List.generate(
      bengaliNumbers.length,
      (_) => random.nextInt(_boardImages.length),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    context.read<BanglaSonkhaBloc>().add(BanglaSonkhaInit());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    AudioService().resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocConsumer<BanglaSonkhaBloc, BanglaSonkhaState>(
        listener: (context, state) async {
          if (state.answerStatus == SonkhaAnswerStatus.correct) {
            _confettiController.play();

            await Future.delayed(const Duration(seconds: 2));

            if (!context.mounted) return;

            final bool? writtenSuccessfully = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChalkBoardScreen(alphabet: state.currentNumber),
              ),
            );

            if (!context.mounted) return;

            if (writtenSuccessfully == true) {
              context.read<BanglaSonkhaBloc>().add(BanglaSonkhaNext());
            } else {
              context.read<BanglaSonkhaBloc>().add(BanglaSonkhaRetry());
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SizedBox(
              height: 1.sh,
              width: 1.sw,
              child: Stack(
                children: [
                  // 1. BACKGROUND
                  Image.asset(
                    Assets.imagesSonkhaBg,
                    fit: BoxFit.cover,
                    height: 1.sh,
                    width: 1.sw,
                  ),

                  // 2. NUMBER DISPLAY
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.18.sh),
                      child: BlocBuilder<BanglaSonkhaBloc, BanglaSonkhaState>(
                        buildWhen: (prev, curr) =>
                            prev.index != curr.index ||
                            prev.answerStatus != curr.answerStatus,
                        builder: (context, state) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 0.86.sw,
                            height: 0.45.sh,
                            decoration: BoxDecoration(
                              color:
                                  state.answerStatus == SonkhaAnswerStatus.wrong
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),

                            child: Stack(
                              children: [
                                Image.asset(
                                  _boardImages[_boardImageIndices[state.index]],
                                ),
                                Align(
                                  alignment: AlignmentGeometry.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 40.h),
                                    child: Text(
                                      state.currentNumber,
                                      key: ValueKey(state.currentNumber),
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 130.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 20,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. NAVIGATION BUTTONS (Bottom Row)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: IgnorePointer(
                        ignoring: state.isValidating,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GamingImageButton(
                              imagePath: Assets.imagesArrowLeft,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BanglaSonkhaBloc>()
                                  .add(BanglaSonkhaPrevious()),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesRetryButton,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BanglaSonkhaBloc>()
                                  .add(BanglaSonkhaRetry()),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesArrowRight,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BanglaSonkhaBloc>()
                                  .add(BanglaSonkhaNext()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. MIC BUTTON
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 180),
                      child: IgnorePointer(
                        ignoring: state.isValidating || state.isListening,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GamingImageButton(
                              width: 0.4.sw,
                              imagePath: Assets.imagesMicButton,
                              onPressed: () => context
                                  .read<BanglaSonkhaBloc>()
                                  .add(BanglaSonkhaStartListening()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 5. CLOSE BUTTON
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.w, top: 15.h),
                      child: GamingImageButton(
                        width: 0.2.sw,
                        imagePath: Assets.imagesCrossIcon,
                        onPressed: () {
                          context.read<BanglaSonkhaBloc>().add(
                            BanglaSonkhaStop(),
                          );
                          context.pop();
                        },
                      ),
                    ),
                  ),

                  // 6. CONFETTI OVERLAY
                  Align(
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
                      ],
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
}
