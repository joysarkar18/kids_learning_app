import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/sothik_uttor/bloc/sothik_uttor_bloc.dart';
import 'package:kids_learning/modules/sothik_uttor/screen/sothik_uttor_view.dart';

class SothikUttorScreenWrapper extends StatelessWidget {
  const SothikUttorScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SothikUttorBloc(),
      child: const SothikUttorScreen(),
    );
  }
}
