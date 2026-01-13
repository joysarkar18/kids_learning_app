import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_bloc.dart';
import 'package:kids_learning/modules/alphabate/bloc/alphabate_event.dart';
import 'package:kids_learning/modules/alphabate/screen/alphabate_view.dart';

class AlphabetScreenWrapper extends StatelessWidget {
  const AlphabetScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlphabetBloc()..add(AlphabetInit()),
      child: const AlphabetScreen(),
    );
  }
}
