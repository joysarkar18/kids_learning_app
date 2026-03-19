import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages daily notifications for challenge reminders
/// Sends 2 notifications per day: morning and evening
class DailyNotificationScheduler {
  static final DailyNotificationScheduler _instance =
      DailyNotificationScheduler._internal();
  factory DailyNotificationScheduler() => _instance;
  DailyNotificationScheduler._internal();

  static DailyNotificationScheduler get instance => _instance;

  final NotificationService _notificationService = NotificationService.instance;

  // Default notification times
  static const Time morningTime = Time(hour: 9, minute: 0); // 9:00 AM
  static const Time eveningTime = Time(hour: 19, minute: 0); // 7:00 PM

  // Notification IDs
  static const int morningNotificationId = 1001;
  static const int eveningNotificationId = 1002;

  // SharedPreferences keys
  static const String _morningEnabledKey = 'morning_notification_enabled';
  static const String _eveningEnabledKey = 'evening_notification_enabled';
  static const String _notificationsInitializedKey =
      'notifications_initialized';

  /// Initialize and schedule daily notifications
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if already initialized
      final isInitialized =
          prefs.getBool(_notificationsInitializedKey) ?? false;

      if (!isInitialized) {
        // First time initialization - enable both notifications by default
        await prefs.setBool(_morningEnabledKey, true);
        await prefs.setBool(_eveningEnabledKey, true);
        await prefs.setBool(_notificationsInitializedKey, true);
      }

      // Schedule notifications
      await scheduleAllNotifications();

      LoggerService.logInfo('DailyNotificationScheduler initialized');
    } catch (e) {
      LoggerService.logError(
        'Error initializing DailyNotificationScheduler: $e',
      );
    }
  }

  /// Schedule both morning and evening notifications
  Future<void> scheduleAllNotifications() async {
    await scheduleMorningNotification();
    await scheduleEveningNotification();
  }

  /// Schedule morning notification (9:00 AM)
  Future<void> scheduleMorningNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_morningEnabledKey) ?? true;

    if (!isEnabled) {
      await _notificationService.cancelNotification(morningNotificationId);
      LoggerService.logInfo('Morning notification is disabled');
      return;
    }

    await _notificationService.scheduleDailyNotification(
      id: morningNotificationId,
      title: 'Complete Your Daily Challenge! 🌟',
      body:
          'Good morning! Time to complete your daily challenge and earn stars. Don\'t miss out!',
      scheduledTime: morningTime,
      payload: {'type': 'morning_challenge', 'reminder': 'daily_challenge'},
    );
  }

  /// Schedule evening notification (7:00 PM)
  Future<void> scheduleEveningNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_eveningEnabledKey) ?? true;

    if (!isEnabled) {
      await _notificationService.cancelNotification(eveningNotificationId);
      LoggerService.logInfo('Evening notification is disabled');
      return;
    }

    await _notificationService.scheduleDailyNotification(
      id: eveningNotificationId,
      title: 'Don\'t Miss Your Stars! ⭐',
      body:
          'Evening reminder! Complete your daily challenge before the day ends to earn your stars!',
      scheduledTime: eveningTime,
      payload: {'type': 'evening_challenge', 'reminder': 'daily_challenge'},
    );
  }

  /// Enable or disable morning notifications
  Future<void> setMorningNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_morningEnabledKey, enabled);

    if (enabled) {
      await scheduleMorningNotification();
      LoggerService.logInfo('Morning notification enabled');
    } else {
      await _notificationService.cancelNotification(morningNotificationId);
      LoggerService.logInfo('Morning notification disabled');
    }
  }

  /// Enable or disable evening notifications
  Future<void> setEveningNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eveningEnabledKey, enabled);

    if (enabled) {
      await scheduleEveningNotification();
      LoggerService.logInfo('Evening notification enabled');
    } else {
      await _notificationService.cancelNotification(eveningNotificationId);
      LoggerService.logInfo('Evening notification disabled');
    }
  }

  /// Check if morning notifications are enabled
  Future<bool> isMorningNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_morningEnabledKey) ?? true;
  }

  /// Check if evening notifications are enabled
  Future<bool> isEveningNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_eveningEnabledKey) ?? true;
  }

  /// Cancel all daily challenge notifications
  Future<void> cancelAllNotifications() async {
    await _notificationService.cancelNotification(morningNotificationId);
    await _notificationService.cancelNotification(eveningNotificationId);
    LoggerService.logInfo('All daily challenge notifications cancelled');
  }

  /// Reschedule all notifications (useful after app update or language change)
  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    await scheduleAllNotifications();
    LoggerService.logInfo('All daily challenge notifications rescheduled');
  }

  /// Show immediate notification (for testing or manual trigger)
  Future<void> showImmediateChallengeNotification({
    String title = 'Time for Your Daily Challenge!',
    String body = 'Complete your challenge now and earn stars!',
  }) async {
    await _notificationService.showDailyChallengeNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: {'type': 'immediate_challenge'},
    );
  }

  /// Get pending notification count
  Future<int> getPendingNotificationCount() async {
    final pendingNotifications = await _notificationService
        .getPendingNotifications();
    return pendingNotifications?.length ?? 0;
  }

  /// Get list of pending notifications
  Future<List<String>> getPendingNotificationTitles() async {
    final pendingNotifications = await _notificationService
        .getPendingNotifications();
    if (pendingNotifications == null) return [];

    return pendingNotifications.map((n) => n.title ?? '').toList();
  }
}
