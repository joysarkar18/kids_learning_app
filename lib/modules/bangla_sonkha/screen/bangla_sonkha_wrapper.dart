import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/bangla_sonkha/bloc/bangla_sonkha_bloc.dart';
import 'package:kids_learning/modules/bangla_sonkha/bloc/bangla_sonkha_event.dart';
import 'package:kids_learning/modules/bangla_sonkha/screen/bangla_sonkha_view.dart';

class BanglaSonkhaScreenWrapper extends StatelessWidget {
  const BanglaSonkhaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BanglaSonkhaBloc()..add(BanglaSonkhaInit()),
      child: const BanglaSonkhaScreen(),
    );
  }
}
