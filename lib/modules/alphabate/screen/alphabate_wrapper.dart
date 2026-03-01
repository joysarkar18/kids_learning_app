import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_event.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_view.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/widgets/daily_challenge_snackbar_listener.dart';

class AlphabetScreenWrapper extends StatelessWidget {
  const AlphabetScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final startingIndex =
        DailyChallengeService.instance.consumeStartIndex('alphabate');
    LoggerService.logInfo('[AlphabetWrapper] build() → consumeStartIndex returned: ${startingIndex ?? "NULL"}');
    LoggerService.logInfo('[AlphabetWrapper] Firing AlphabetInit(startingIndex: $startingIndex)');
    return DailyChallengeSnackbarListener(
      enabled: startingIndex != null,
      child: BlocProvider(
        create: (_) =>
            AlphabetBloc()..add(AlphabetInit(startingIndex: startingIndex)),
        child: const AlphabetScreen(),
      ),
    );
  }
}
