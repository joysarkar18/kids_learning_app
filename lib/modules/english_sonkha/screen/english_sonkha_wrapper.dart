import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/english_sonkha/bloc/english_sonkha_bloc.dart';
import 'package:kids_learning/modules/english_sonkha/bloc/english_sonkha_event.dart';
import 'package:kids_learning/modules/english_sonkha/screen/english_sonkha_view.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/widgets/daily_challenge_snackbar_listener.dart';

class EnglishSonkhaScreenWrapper extends StatelessWidget {
  const EnglishSonkhaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final startingIndex =
        DailyChallengeService.instance.consumeStartIndex('english_sonkha');
    LoggerService.logInfo('[EnglishSonkhaWrapper] build() → consumeStartIndex returned: ${startingIndex ?? "NULL"}');
    LoggerService.logInfo('[EnglishSonkhaWrapper] Firing EnglishSonkhaInit(startingIndex: $startingIndex)');
    return DailyChallengeSnackbarListener(
      enabled: startingIndex != null,
      child: BlocProvider(
        create: (_) => EnglishSonkhaBloc()
          ..add(EnglishSonkhaInit(startingIndex: startingIndex)),
        child: const EnglishSonkhaScreen(),
      ),
    );
  }
}
