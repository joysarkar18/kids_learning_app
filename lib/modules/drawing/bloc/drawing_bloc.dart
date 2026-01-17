import 'package:bloc/bloc.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_event.dart';
import 'package:kids_learning/modules/drawing/bloc/drawing_state.dart';

class DrawingBloc extends Bloc<DrawingEvent, DrawingState> {
  DrawingBloc() : super(DrawingInitial()) {
    on<DrawingEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
