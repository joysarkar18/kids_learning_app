import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/audio/audio_key.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_bloc.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_event.dart';
import 'package:kids_learning/modules/onboarding/bloc/onboarding_state.dart';
import 'package:kids_learning/modules/onboarding/data/models/character_model.dart';
import 'package:kids_learning/modules/onboarding/screen/widgets/character_card.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/snackbar_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_button.dart';

class CharacterSelectorScreen extends StatefulWidget {
  const CharacterSelectorScreen({super.key});

  @override
  State<CharacterSelectorScreen> createState() =>
      _CharacterSelectorScreenState();
}

class _CharacterSelectorScreenState extends State<CharacterSelectorScreen> {
  int? selectedCharacterIndex;
  late final List<CharacterModel> characters;
  Timer? _audioTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final l10n = AppLocalizations.of(context)!;

    characters = [
      CharacterModel(
        key: "chintu ",
        name: l10n.chintu,
        imagePath: Assets.imagesCharBird,
        backgroundColor: const Color(0xFFFFE5E5),
        audioKey: AudioKey.chintu,
      ),
      CharacterModel(
        key: "gauri",
        name: l10n.gauri,
        imagePath: Assets.imagesCharCow,
        backgroundColor: const Color(0xFFE5F3FF),
        audioKey: AudioKey.gauri,
      ),
      CharacterModel(
        key: "moti",
        name: l10n.moti,
        imagePath: Assets.imagesCharDog,
        backgroundColor: const Color(0xFFFFF5E5),
        audioKey: AudioKey.moti,
      ),
      CharacterModel(
        key: "gudiya",
        name: l10n.gudiya,
        imagePath: Assets.imagesCharDonkey,
        backgroundColor: const Color(0xFFE5FFE5),
        audioKey: AudioKey.gudiya,
      ),
      CharacterModel(
        key: "gajaraj",
        name: l10n.gajraj,
        imagePath: Assets.imagesCharElephant,
        backgroundColor: const Color(0xFFFBE5FF),
        audioKey: AudioKey.gajraj,
      ),
      CharacterModel(
        key: "chiku",
        name: l10n.chiku,
        imagePath: Assets.imagesCharFox,
        backgroundColor: const Color(0xFFE9E5FF),
        audioKey: AudioKey.chiku,
      ),
    ];

    // Play audio on first load
    _playChooseYourFriendAudio();
    // Start timer for repeating audio every 5 seconds
    _startAudioTimer();
  }

  void _playChooseYourFriendAudio() {
    AudioPlayerService.instance.playLocalized(
      context: context,
      key: AudioKey.choose_your_friend,
    );
  }

  void _startAudioTimer() {
    // Cancel existing timer if any
    _audioTimer?.cancel();

    // Play audio every 5 seconds only if no character is selected
    _audioTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Only play audio if no character is selected
      if (selectedCharacterIndex == null && mounted) {
        _playChooseYourFriendAudio();
      } else {
        // Stop timer if character is selected
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9E6), Color(0xFFE6F4FF), Color(0xFFFFE6F0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              children: [
                _buildHeader(l10n),
                SizedBox(height: 30.h),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      return CharacterCard(
                        character: characters[index],
                        isSelected: selectedCharacterIndex == index,
                        onTap: () {
                          setState(() {
                            selectedCharacterIndex = index;
                          });
                          // Cancel timer when character is selected
                          _audioTimer?.cancel();
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                AnimatedOpacity(
                  opacity: selectedCharacterIndex != null ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: BlocListener<OnboardingBloc, OnboardingState>(
                    listener: (context, state) {
                      if (state is OnboardingErrorState) {
                        LoggerService.logError(
                          'Error during friend selection: ${state.message}',
                        );
                        SnackbarService().showError(
                          message: l10n.somethingWentWrong,
                        );
                      }

                      if (state is FriendSelectionState) {
                        context.pushNamed(Names.home);
                      }
                    },
                    child: UniversalGamingButton(
                      width: 320.w,
                      height: 50,
                      onPressed: () {
                        context.read<OnboardingBloc>().add(
                          FriendSelectionEvent(
                            selectedFriend:
                                characters[selectedCharacterIndex ?? 0].key,
                          ),
                        );
                      },
                      text: l10n.letsGo,
                      textStyle: GoogleFonts.bubblegumSans(
                        color: AppColors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.chooseYourFriend,
          style: GoogleFonts.bubblegumSans(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5C4BDB),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.pickFavorite,
          style: GoogleFonts.bubblegumSans(
            fontSize: 16.sp,
            color: const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    super.dispose();
  }
}
