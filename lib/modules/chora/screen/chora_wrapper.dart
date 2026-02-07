import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/chora/bloc/chora_bloc.dart';
import 'package:kids_learning/modules/chora/screen/chora_list_view.dart';

class ChoraScreenWrapper extends StatelessWidget {
  const ChoraScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChoraBloc(),
      child: const ChoraListScreen(),
    );
  }
}
