class ChallengeProgress {
  final int totalStars;
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate;

  const ChallengeProgress({
    this.totalStars = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate = '',
  });

  Map<String, dynamic> toMap() => {
        'totalStars': totalStars,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate,
      };

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) =>
      ChallengeProgress(
        totalStars: map['totalStars'] ?? 0,
        currentStreak: map['currentStreak'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        lastCompletedDate: map['lastCompletedDate'] ?? '',
      );

  ChallengeProgress copyWith({
    int? totalStars,
    int? currentStreak,
    int? longestStreak,
    String? lastCompletedDate,
  }) =>
      ChallengeProgress(
        totalStars: totalStars ?? this.totalStars,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      );
}
