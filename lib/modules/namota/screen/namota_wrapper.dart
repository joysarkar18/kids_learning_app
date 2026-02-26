import 'package:flutter/material.dart'
    show StatelessWidget, BuildContext, Widget;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_learning/modules/namota/bloc/namota_bloc.dart';
import 'package:kids_learning/modules/namota/bloc/namota_event.dart';
import 'package:kids_learning/modules/namota/screen/namota_view.dart';

class NamotaScreenWrapper extends StatelessWidget {
  final int tableNumber;

  const NamotaScreenWrapper({super.key, required this.tableNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NamotaBloc()..add(NamotaInit(tableNumber)),
      child: const NamotaScreen(),
    );
  }
}
