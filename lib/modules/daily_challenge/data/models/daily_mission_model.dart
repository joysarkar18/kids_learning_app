class DailyMission {
  final String id;
  final String moduleKey;
  final String titleEn;
  final String titleBn;
  final int targetCount;
  int currentCount;

  DailyMission({
    required this.id,
    required this.moduleKey,
    required this.titleEn,
    required this.titleBn,
    required this.targetCount,
    this.currentCount = 0,
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
      };

  factory DailyMission.fromMap(Map<String, dynamic> map) => DailyMission(
        id: map['id'] ?? '',
        moduleKey: map['moduleKey'] ?? '',
        titleEn: map['titleEn'] ?? '',
        titleBn: map['titleBn'] ?? '',
        targetCount: map['targetCount'] ?? 0,
        currentCount: map['currentCount'] ?? 0,
      );

  DailyMission copyWith({int? currentCount}) => DailyMission(
        id: id,
        moduleKey: moduleKey,
        titleEn: titleEn,
        titleBn: titleBn,
        targetCount: targetCount,
        currentCount: currentCount ?? this.currentCount,
      );
}
