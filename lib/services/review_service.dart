import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  ReviewService._();

  static final ReviewService _instance = ReviewService._();
  static ReviewService get instance => _instance;

  static const String _launchCountKey = 'review_launch_count';
  static const String _featureUsedKey = 'review_feature_used';
  static const String _reviewPromptedKey = 'review_prompted';
  static const String _reviewDismissedKey = 'review_dismissed';
  static const String _reviewCompletedKey = 'review_completed';

  // Minimum app launches before showing review
  static const int _minLaunchCount = 2;

  // Track app launch
  Future<void> incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_launchCountKey) ?? 0;
    await prefs.setInt(_launchCountKey, count + 1);
    print('[ReviewService] Launch count incremented to: ${count + 1}');
  }

  // Get current launch count
  Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_launchCountKey) ?? 0;
    print('[ReviewService] Current launch count: $count');
    return count;
  }

  // Mark a feature as used
  Future<void> markFeatureUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureUsedKey, true);
    print('[ReviewService] Feature marked as used');
  }

  // Check if any feature has been used
  Future<bool> isFeatureUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getBool(_featureUsedKey) ?? false;
    print('[ReviewService] Feature used: $used');
    return used;
  }

  // Check if review should be shown
  Future<bool> shouldShowReview() async {
    print('[ReviewService] Checking shouldShowReview...');
    final prefs = await SharedPreferences.getInstance();

    // Don't show if already prompted and dismissed/completed
    final isDismissed = prefs.getBool(_reviewDismissedKey) ?? false;
    print('[ReviewService] review_dismissed: $isDismissed');
    if (isDismissed) return false;

    final isCompleted = prefs.getBool(_reviewCompletedKey) ?? false;
    print('[ReviewService] review_completed: $isCompleted');
    if (isCompleted) return false;

    final isPrompted = prefs.getBool(_reviewPromptedKey) ?? false;
    print('[ReviewService] review_prompted: $isPrompted');
    if (isPrompted) return false;

    // Check minimum launches
    final launchCount = await getLaunchCount();
    print(
      '[ReviewService] Launch count: $launchCount (minimum required: $_minLaunchCount)',
    );
    if (launchCount < _minLaunchCount) return false;

    // Check if features have been used
    final featureUsed = await isFeatureUsed();
    print('[ReviewService] Feature used: $featureUsed');
    if (!featureUsed) return false;

    print('[ReviewService] All conditions met, should show review: true');
    return true;
  }

  // Mark review as prompted
  Future<void> markAsPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPromptedKey, true);
    print('[ReviewService] Marked as prompted');
  }

  // Mark review as dismissed
  Future<void> markAsDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewDismissedKey, true);
    print('[ReviewService] Marked as dismissed');
  }

  // Mark review as completed
  Future<void> markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewCompletedKey, true);
    print('[ReviewService] Marked as completed');
  }

  // Reset all review data (for testing)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_launchCountKey);
    await prefs.remove(_featureUsedKey);
    await prefs.remove(_reviewPromptedKey);
    await prefs.remove(_reviewDismissedKey);
    await prefs.remove(_reviewCompletedKey);
    print('[ReviewService] All review data reset');
  }
}
