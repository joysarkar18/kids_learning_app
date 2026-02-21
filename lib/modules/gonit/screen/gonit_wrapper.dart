import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/gonit/bloc/gonit_bloc.dart';
import 'package:kids_learning/modules/gonit/bloc/gonit_event.dart';
import 'package:kids_learning/modules/gonit/screen/gonit_problem_view.dart';

class GanitScreenWrapper extends StatelessWidget {
  final String? type;

  const GanitScreenWrapper({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GanitBloc()..add(GanitInit(type: type)),
      child: const GanitProblemScreen(),
    );
  }
}
