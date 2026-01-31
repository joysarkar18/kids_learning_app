import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/english_sonkha/bloc/english_sonkha_bloc.dart';
import 'package:kids_learning/modules/english_sonkha/bloc/english_sonkha_event.dart';
import 'package:kids_learning/modules/english_sonkha/screen/english_sonkha_view.dart';

class EnglishSonkhaScreenWrapper extends StatelessWidget {
  const EnglishSonkhaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EnglishSonkhaBloc()..add(EnglishSonkhaInit()),
      child: const EnglishSonkhaScreen(),
    );
  }
}
