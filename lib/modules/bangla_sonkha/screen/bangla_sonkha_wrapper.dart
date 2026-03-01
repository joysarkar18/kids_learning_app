import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/bangla_sonkha/bloc/bangla_sonkha_bloc.dart';
import 'package:kids_learning/modules/bangla_sonkha/bloc/bangla_sonkha_event.dart';
import 'package:kids_learning/modules/bangla_sonkha/screen/bangla_sonkha_view.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/widgets/daily_challenge_snackbar_listener.dart';

class BanglaSonkhaScreenWrapper extends StatelessWidget {
  const BanglaSonkhaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final startingIndex =
        DailyChallengeService.instance.consumeStartIndex('bangla_sonkha');
    LoggerService.logInfo('[BanglaSonkhaWrapper] build() → consumeStartIndex returned: ${startingIndex ?? "NULL"}');
    LoggerService.logInfo('[BanglaSonkhaWrapper] Firing BanglaSonkhaInit(startingIndex: $startingIndex)');
    return DailyChallengeSnackbarListener(
      enabled: startingIndex != null,
      child: BlocProvider(
        create: (_) => BanglaSonkhaBloc()
          ..add(BanglaSonkhaInit(startingIndex: startingIndex)),
        child: const BanglaSonkhaScreen(),
      ),
    );
  }
}
