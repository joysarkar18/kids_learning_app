import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/bornomala/screen/writing_screen.dart';
import 'package:kids_learning/services/audio_service.dart';

import '../bloc/english_sonkha_bloc.dart';
import '../bloc/english_sonkha_event.dart';
import '../bloc/english_sonkha_state.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class EnglishSonkhaScreen extends StatefulWidget {
  const EnglishSonkhaScreen({super.key});

  @override
  State<EnglishSonkhaScreen> createState() => _EnglishSonkhaScreenState();
}

class _EnglishSonkhaScreenState extends State<EnglishSonkhaScreen> {
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

  late final List<int> _boardImageIndices;

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    final random = Random();
    _boardImageIndices = List.generate(
      englishNumbers.length,
      (_) => random.nextInt(_boardImages.length),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    context.read<EnglishSonkhaBloc>().add(EnglishSonkhaInit());
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
      child: BlocConsumer<EnglishSonkhaBloc, EnglishSonkhaState>(
        listener: (context, state) async {
          if (state.answerStatus == EnglishSonkhaAnswerStatus.correct) {
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
              context.read<EnglishSonkhaBloc>().add(EnglishSonkhaNext());
            } else {
              context.read<EnglishSonkhaBloc>().add(EnglishSonkhaRetry());
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
                    Assets.imagesBanglaSonkhaBg,
                    fit: BoxFit.cover,
                    height: 1.sh,
                    width: 1.sw,
                  ),

                  // 2. NUMBER DISPLAY
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.18.sh),
                      child: BlocBuilder<EnglishSonkhaBloc, EnglishSonkhaState>(
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
                                  state.answerStatus ==
                                      EnglishSonkhaAnswerStatus.wrong
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
                                      style: TextStyle(
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
                                  .read<EnglishSonkhaBloc>()
                                  .add(EnglishSonkhaPrevious()),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesRetryButton,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<EnglishSonkhaBloc>()
                                  .add(EnglishSonkhaRetry()),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesArrowRight,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<EnglishSonkhaBloc>()
                                  .add(EnglishSonkhaNext()),
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
                                  .read<EnglishSonkhaBloc>()
                                  .add(EnglishSonkhaStartListening()),
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
                          context.read<EnglishSonkhaBloc>().add(
                            EnglishSonkhaStop(),
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
