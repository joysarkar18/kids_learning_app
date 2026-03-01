import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/bornomala/bloc/bornomala_bloc.dart';
import 'package:kids_learning/modules/bornomala/bloc/bornomala_event.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_view.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/widgets/daily_challenge_snackbar_listener.dart';

class BornomalaScreenWrapper extends StatelessWidget {
  const BornomalaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final startingIndex =
        DailyChallengeService.instance.consumeStartIndex('bornomala');
    LoggerService.logInfo('[BornomalaWrapper] build() → consumeStartIndex returned: ${startingIndex ?? "NULL"}');
    LoggerService.logInfo('[BornomalaWrapper] Firing BornomalaInit(startingIndex: $startingIndex)');
    return DailyChallengeSnackbarListener(
      enabled: startingIndex != null,
      child: BlocProvider(
        create: (_) =>
            BornomalaBloc()..add(BornomalaInit(startingIndex: startingIndex)),
        child: const BornomalaScreen(),
      ),
    );
  }
}
