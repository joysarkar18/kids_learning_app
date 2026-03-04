import 'package:equatable/equatable.dart';

abstract class BananEvent extends Equatable {
  const BananEvent();

  @override
  List<Object?> get props => [];
}

class BananInit extends BananEvent {
  const BananInit();
}

/// Player dragged a tile into a slot
class BananTilePlaced extends BananEvent {
  final String tileId;
  final int slotIndex;

  const BananTilePlaced(this.tileId, this.slotIndex);

  @override
  List<Object?> get props => [tileId, slotIndex];
}

/// Player tapped a filled slot to remove the tile
class BananTileRemoved extends BananEvent {
  final int slotIndex;

  const BananTileRemoved(this.slotIndex);

  @override
  List<Object?> get props => [slotIndex];
}

class BananNextProblem extends BananEvent {
  const BananNextProblem();
}

class BananSkipProblem extends BananEvent {
  const BananSkipProblem();
}

class BananRetry extends BananEvent {
  const BananRetry();
}

class BananReadQuestion extends BananEvent {
  const BananReadQuestion();
}

class BananStop extends BananEvent {
  const BananStop();
}

/// Internal: triggered when running low on problems
class BananLoadMoreProblems extends BananEvent {
  const BananLoadMoreProblems();
}

class BananPlayAgain extends BananEvent {
  const BananPlayAgain();
}
