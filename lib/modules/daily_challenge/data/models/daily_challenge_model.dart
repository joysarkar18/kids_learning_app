import 'package:kids_learning/modules/daily_challenge/data/models/daily_mission_model.dart';

class DailyChallenge {
  final String date;
  final List<DailyMission> missions;

  DailyChallenge({
    required this.date,
    required this.missions,
  });

  int get starsEarned => missions.where((m) => m.isCompleted).length;

  bool get isAllCompleted => missions.every((m) => m.isCompleted);

  Map<String, dynamic> toMap() => {
        'date': date,
        'missions': missions.map((m) => m.toMap()).toList(),
        'starsEarned': starsEarned,
      };

  factory DailyChallenge.fromMap(Map<String, dynamic> map) => DailyChallenge(
        date: map['date'] ?? '',
        missions: (map['missions'] as List?)
                ?.map((m) => DailyMission.fromMap(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
