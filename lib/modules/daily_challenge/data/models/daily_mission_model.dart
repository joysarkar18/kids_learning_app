class DailyMission {
  final String id;
  final String moduleKey;
  final String titleEn;
  final String titleBn;
  final int targetCount;
  final int currentCount;
  final int? startingIndex;

  DailyMission({
    required this.id,
    required this.moduleKey,
    required this.titleEn,
    required this.titleBn,
    required this.targetCount,
    this.currentCount = 0,
    this.startingIndex,
  });

  bool get isCompleted => currentCount >= targetCount;

  double get progressFraction =>
      targetCount > 0 ? (currentCount / targetCount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'moduleKey': moduleKey,
        'titleEn': titleEn,
        'titleBn': titleBn,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'startingIndex': startingIndex,
      };

  factory DailyMission.fromMap(Map<String, dynamic> map) => DailyMission(
        id: map['id'] ?? '',
        moduleKey: map['moduleKey'] ?? '',
        titleEn: map['titleEn'] ?? '',
        titleBn: map['titleBn'] ?? '',
        targetCount: map['targetCount'] ?? 0,
        currentCount: map['currentCount'] ?? 0,
        startingIndex: map['startingIndex'] as int?,
      );

  DailyMission copyWith({int? currentCount, int? startingIndex}) =>
      DailyMission(
        id: id,
        moduleKey: moduleKey,
        titleEn: titleEn,
        titleBn: titleBn,
        targetCount: targetCount,
        currentCount: currentCount ?? this.currentCount,
        startingIndex: startingIndex ?? this.startingIndex,
      );
}
