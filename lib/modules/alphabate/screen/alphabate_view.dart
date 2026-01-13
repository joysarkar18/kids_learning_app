import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_event.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_state.dart';

import 'package:kids_learning/modules/bornomala/screen/writing_screen.dart'; // Reusing writing screen
import 'package:kids_learning/services/audio_service.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    AudioService().pause();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    context.read<AlphabetBloc>().add(AlphabetInit());
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
      child: BlocConsumer<AlphabetBloc, AlphabetState>(
        listener: (context, state) async {
          if (state.answerStatus == AnswerStatus.correct) {
            _confettiController.play();

            await Future.delayed(const Duration(seconds: 2));

            if (!context.mounted) return;

            final bool? writtenSuccessfully = await Navigator.push(
              context,
              MaterialPageRoute(
                // Reusing the same writing screen
                builder: (context) => ChalkBoardScreen(
                  alphabet: state.currentAlphabet,
                  languageCode: "bn",
                ),
              ),
            );

            if (!context.mounted) return;

            if (writtenSuccessfully == true) {
              context.read<AlphabetBloc>().add(AlphabetNext());
            } else {
              context.read<AlphabetBloc>().add(AlphabetRetry());
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
                    // Ensure you have this asset or reuse Assets.imagesBornomalaBg
                    Assets.imagesBornomalaBg,
                    fit: BoxFit.cover,
                    height: 1.sh,
                    width: 1.sw,
                  ),

                  // 2. ALPHABET IMAGE
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.19.sh),
                      child: BlocBuilder<AlphabetBloc, AlphabetState>(
                        buildWhen: (prev, curr) =>
                            prev.index != curr.index ||
                            prev.answerStatus != curr.answerStatus,
                        builder: (context, state) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: state.answerStatus == AnswerStatus.wrong
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            // Assuming English images are in this folder
                            child: Image.asset(
                              "assets/english_images/${state.currentAlphabet}.png",
                              key: ValueKey(state.currentAlphabet),
                              width: 0.8.sw,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. NAVIGATION BUTTONS
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
                              onPressed: () => context.read<AlphabetBloc>().add(
                                AlphabetPrevious(),
                              ),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesRetryButton,
                              width: 0.32.sw,
                              onPressed: () => context.read<AlphabetBloc>().add(
                                AlphabetRetry(),
                              ),
                            ),
                            GamingImageButton(
                              imagePath: Assets.imagesArrowRight,
                              width: 0.32.sw,
                              onPressed: () => context.read<AlphabetBloc>().add(
                                AlphabetNext(),
                              ),
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
                              onPressed: () => context.read<AlphabetBloc>().add(
                                AlphabetStartListening(),
                              ),
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
                          context.read<AlphabetBloc>().add(AlphabetStop());
                          context.pop();
                        },
                      ),
                    ),
                  ),

                  // 6. CONFETTI
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
