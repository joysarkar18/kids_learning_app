import 'package:equatable/equatable.dart';
import 'package:kids_learning/modules/banan/data/models/banan_data_model.dart';

enum BananAnswerStatus { none, correct, wrong }

// ─────────────────────────────────────────────────────────────────
//  Abstract base (keeps screen code simple with .currentProblem etc.)
// ─────────────────────────────────────────────────────────────────
abstract class BananState extends Equatable {
  const BananState();

  BananProblemModel? get currentProblem => null;
  int get currentIndex => 0;
  Map<int, String?> get slotMap => {};
  List<BananLetterTile> get availableTiles => [];
  BananAnswerStatus get answerStatus => BananAnswerStatus.none;
  bool get isPlayingAudio => false;
  bool get isPlayingSkipAudio => false;
  bool get isLoadingMore => false;

  @override
  List<Object?> get props => [];
}

// ─────────────────────────────────────────────────────────────────
//  Concrete states
// ─────────────────────────────────────────────────────────────────
class BananInitial extends BananState {
  const BananInitial();
}

class BananLoading extends BananState {
  const BananLoading();
}

class BananLoaded extends BananState {
  final List<BananProblemModel> problems;

  @override
  final int currentIndex;

  /// slotIndex → tileId (null = empty)
  @override
  final Map<int, String?> slotMap;

  /// All tiles for the current problem (placed + unplaced)
  @override
  final List<BananLetterTile> availableTiles;

  @override
  final BananAnswerStatus answerStatus;

  @override
  final bool isPlayingAudio;

  @override
  final bool isPlayingSkipAudio;

  @override
  final bool isLoadingMore;

  final int roundCorrect;
  final int roundAnswered;

  const BananLoaded({
    required this.problems,
    required this.currentIndex,
    required this.slotMap,
    required this.availableTiles,
    this.answerStatus = BananAnswerStatus.none,
    this.isPlayingAudio = false,
    this.isPlayingSkipAudio = false,
    this.isLoadingMore = false,
    this.roundCorrect = 0,
    this.roundAnswered = 0,
  });

  @override
  BananProblemModel? get currentProblem =>
      currentIndex < problems.length ? problems[currentIndex] : null;

  /// Tiles that have NOT been placed in any slot yet
  List<BananLetterTile> get unusedTiles {
    final placed = slotMap.values.whereType<String>().toSet();
    return availableTiles.where((t) => !placed.contains(t.id)).toList();
  }

  /// True when every slot has a tile in it
  bool get allSlotsFilled {
    final problem = currentProblem;
    if (problem == null) return false;
    return slotMap.values.where((v) => v != null).length ==
        problem.letters.length;
  }

  /// Trigger pre-fetch when 3 or fewer problems remain in the buffer
  bool get shouldLoadMore => problems.length - currentIndex <= 3;

  BananLoaded copyWith({
    List<BananProblemModel>? problems,
    int? currentIndex,
    Map<int, String?>? slotMap,
    List<BananLetterTile>? availableTiles,
    BananAnswerStatus? answerStatus,
    bool? isPlayingAudio,
    bool? isPlayingSkipAudio,
    bool? isLoadingMore,
    int? roundCorrect,
    int? roundAnswered,
  }) {
    return BananLoaded(
      problems: problems ?? this.problems,
      currentIndex: currentIndex ?? this.currentIndex,
      slotMap: slotMap ?? this.slotMap,
      availableTiles: availableTiles ?? this.availableTiles,
      answerStatus: answerStatus ?? this.answerStatus,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
      isPlayingSkipAudio: isPlayingSkipAudio ?? this.isPlayingSkipAudio,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      roundCorrect: roundCorrect ?? this.roundCorrect,
      roundAnswered: roundAnswered ?? this.roundAnswered,
    );
  }

  @override
  List<Object?> get props => [
    problems,
    currentIndex,
    slotMap,
    availableTiles,
    answerStatus,
    isPlayingAudio,
    isPlayingSkipAudio,
    isLoadingMore,
    roundCorrect,
    roundAnswered,
  ];
}

class BananError extends BananState {
  final String? errorMessage;

  const BananError({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class BananRoundCompleted extends BananState {
  final int roundCorrect;
  final int roundAnswered;

  const BananRoundCompleted({
    required this.roundCorrect,
    required this.roundAnswered,
  });

  int get roundStars {
    if (roundAnswered == 0) return 1;
    final pct = roundCorrect / roundAnswered;
    if (pct >= 0.9) return 3;
    if (pct >= 0.6) return 2;
    return 1;
  }

  @override
  List<Object?> get props => [roundCorrect, roundAnswered];
}
