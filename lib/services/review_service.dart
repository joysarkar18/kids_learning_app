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
  }

  // Get current launch count
  Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_launchCountKey) ?? 0;
  }

  // Mark a feature as used
  Future<void> markFeatureUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_featureUsedKey, true);
  }

  // Check if any feature has been used
  Future<bool> isFeatureUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_featureUsedKey) ?? false;
  }

  // Check if review should be shown
  Future<bool> shouldShowReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Don't show if already prompted and dismissed/completed
    if (prefs.getBool(_reviewDismissedKey) ?? false) return false;
    if (prefs.getBool(_reviewCompletedKey) ?? false) return false;
    if (prefs.getBool(_reviewPromptedKey) ?? false) return false;

    // Check minimum launches
    final launchCount = await getLaunchCount();
    if (launchCount < _minLaunchCount) return false;

    // Check if features have been used
    final featureUsed = await isFeatureUsed();
    if (!featureUsed) return false;

    return true;
  }

  // Mark review as prompted
  Future<void> markAsPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPromptedKey, true);
  }

  // Mark review as dismissed
  Future<void> markAsDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewDismissedKey, true);
  }

  // Mark review as completed
  Future<void> markAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewCompletedKey, true);
  }

  // Reset all review data (for testing)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_launchCountKey);
    await prefs.remove(_featureUsedKey);
    await prefs.remove(_reviewPromptedKey);
    await prefs.remove(_reviewDismissedKey);
    await prefs.remove(_reviewCompletedKey);
  }
}
