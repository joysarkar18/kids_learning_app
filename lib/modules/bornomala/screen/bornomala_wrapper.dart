import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/bornomala/bloc/bornomala_bloc.dart';
import 'package:kids_learning/modules/bornomala/bloc/bornomala_event.dart';
import 'package:kids_learning/modules/bornomala/screen/bornomala_view.dart';

class BornomalaScreenWrapper extends StatelessWidget {
  const BornomalaScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BornomalaBloc()..add(BornomalaInit()),
      child: const BornomalaScreen(),
    );
  }
}
