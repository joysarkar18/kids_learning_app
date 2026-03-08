class ChallengeProgress {
  final int totalStars;
  final int currentStreak;
  final int longestStreak;
  final String lastCompletedDate;
  final List<String> completedDates; // Track all completion dates for calendar

  const ChallengeProgress({
    this.totalStars = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate = '',
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() => {
        'totalStars': totalStars,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate,
        'completedDates': completedDates,
      };

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) =>
      ChallengeProgress(
        totalStars: map['totalStars'] ?? 0,
        currentStreak: map['currentStreak'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        lastCompletedDate: map['lastCompletedDate'] ?? '',
        completedDates: map['completedDates'] != null
            ? List<String>.from(map['completedDates'] as List)
            : [],
      );

  ChallengeProgress copyWith({
    int? totalStars,
    int? currentStreak,
    int? longestStreak,
    String? lastCompletedDate,
    List<String>? completedDates,
  }) =>
      ChallengeProgress(
        totalStars: totalStars ?? this.totalStars,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        completedDates: completedDates ?? this.completedDates,
      );
}
