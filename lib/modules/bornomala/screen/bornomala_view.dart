import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/bornomala/screen/writing_screen.dart';
import 'package:kids_learning/services/audio_service.dart';

// Imports for your project structure
import '../bloc/bornomala_bloc.dart';
import '../bloc/bornomala_event.dart';
import '../bloc/bornomala_state.dart';
import '../../../utils/assets.dart';
import '../../../widgets/gaming_image_button.dart';

class BornomalaScreen extends StatefulWidget {
  const BornomalaScreen({super.key});

  @override
  State<BornomalaScreen> createState() => _BornomalaScreenState();
}

class _BornomalaScreenState extends State<BornomalaScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 1. Pause background music when entering this game
    AudioService().pause();

    // 2. Setup Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 3. Initialize Bloc
    context.read<BornomalaBloc>().add(BornomalaInit());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // 4. Resume background music when leaving
    AudioService().resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 5. PopScope disables the Android system back button/gesture
    return PopScope(
      canPop: false,
      child: BlocConsumer<BornomalaBloc, BornomalaState>(
        listener: (context, state) async {
          // --- SUCCESS LOGIC ---
          if (state.answerStatus == AnswerStatus.correct) {
            // A. Play Visuals
            _confettiController.play();

            // B. Wait for "Yay" audio to finish (approx 2s)
            await Future.delayed(const Duration(seconds: 2));

            if (!context.mounted) return;

            // C. Navigate to Writing Screen
            // We wait for the result: true = success, false/null = skipped/backed out
            final bool? writtenSuccessfully = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChalkBoardScreen(alphabet: state.currentAlphabet),
              ),
            );

            if (!context.mounted) return;

            // D. Handle Return
            if (writtenSuccessfully == true) {
              // User wrote the letter -> Go to Next
              context.read<BornomalaBloc>().add(BornomalaNext());
            } else {
              // User backed out of writing -> Just retry current state
              context.read<BornomalaBloc>().add(BornomalaRetry());
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
                  // -------------------------
                  // 1. BACKGROUND
                  // -------------------------
                  Image.asset(
                    Assets.imagesBornomalaBg,
                    fit: BoxFit.cover,
                    height: 1.sh,
                    width: 1.sw,
                  ),

                  // -------------------------
                  // 2. ALPHABET IMAGE
                  // -------------------------
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0.19.sh),
                      child: BlocBuilder<BornomalaBloc, BornomalaState>(
                        buildWhen: (prev, curr) =>
                            prev.index != curr.index ||
                            prev.answerStatus != curr.answerStatus,
                        builder: (context, state) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            // Red tint if wrong, transparent otherwise
                            decoration: BoxDecoration(
                              color: state.answerStatus == AnswerStatus.wrong
                                  ? Colors.red.withOpacity(0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              "assets/bengali_images/${state.currentAlphabet}.png",
                              key: ValueKey(state.currentAlphabet),
                              width: 0.8.sw,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // -------------------------
                  // 3. NAVIGATION BUTTONS (Bottom Row)
                  // -------------------------
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: IgnorePointer(
                        // Disable buttons while validating to prevent spam
                        ignoring: state.isValidating,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // PREVIOUS
                            GamingImageButton(
                              imagePath: Assets.imagesArrowLeft,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BornomalaBloc>()
                                  .add(BornomalaPrevious()),
                            ),
                            // RETRY / REPLAY AUDIO
                            GamingImageButton(
                              imagePath: Assets.imagesRetryButton,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BornomalaBloc>()
                                  .add(BornomalaRetry()),
                            ),
                            // NEXT
                            GamingImageButton(
                              imagePath: Assets.imagesArrowRight,
                              width: 0.32.sw,
                              onPressed: () => context
                                  .read<BornomalaBloc>()
                                  .add(BornomalaNext()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // -------------------------
                  // 4. MIC BUTTON (Center)
                  // -------------------------
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
                                  .read<BornomalaBloc>()
                                  .add(BornomalaStartListening()),
                            ),

                            // Optional: Visual indicator that mic is active
                          ],
                        ),
                      ),
                    ),
                  ),

                  // -------------------------
                  // 5. CLOSE BUTTON (Top Left)
                  // -------------------------
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10.w, top: 15.h),
                      child: GamingImageButton(
                        width: 0.2.sw,
                        imagePath: Assets.imagesCrossIcon,
                        onPressed: () {
                          // Stop everything properly before leaving
                          context.read<BornomalaBloc>().add(BornomalaStop());
                          context.pop();
                        },
                      ),
                    ),
                  ),

                  // -------------------------
                  // 6. CONFETTI OVERLAY
                  // -------------------------
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2, // Down
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

                  // -------------------------
                  // 7. LOADING OVERLAY (Validation State)
                  // -------------------------
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
