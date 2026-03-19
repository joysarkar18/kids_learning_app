import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Request permission
      await requestPermission();

      // Initialize Firebase Messaging
      await _initFirebaseMessaging();

      // Initialize local notifications
      await _initLocalNotifications();

      // Get FCM token
      await _getAndSaveToken();

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        _fcmToken = token;
        LoggerService.logInfo('FCM Token refreshed: $token');
        // Token refresh event can be listened to save updated token to Firestore
      });

      LoggerService.logInfo('NotificationService initialized successfully');
    } catch (e) {
      LoggerService.logError('Error initializing NotificationService: $e');
    }
  }

  Future<void> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      LoggerService.logInfo(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    } catch (e) {
      LoggerService.logError('Error requesting notification permission: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerService.logInfo(
        'Received foreground message: ${message.messageId}',
      );
      _showForegroundNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LoggerService.logInfo('Notification tapped: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      LoggerService.logInfo(
        'App opened from notification: ${initialMessage.messageId}',
      );
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotification,
    );

    // Create Android notification channel
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    // Default notification channel (for general notifications)
    const defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'Default notification channel for general notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      showBadge: true,
    );

    // Daily challenge notification channel
    const dailyChallengeChannel = AndroidNotificationChannel(
      'daily_challenge_channel',
      'Daily Challenge Reminders',
      description: 'Notifications for daily challenges and star earnings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      showBadge: true,
    );

    // Firebase messaging channel
    const firebaseChannel = AndroidNotificationChannel(
      'firebase_messaging_channel',
      'Firebase Notifications',
      description: 'Notifications from Firebase Cloud Messaging',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      showBadge: true,
    );

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Create all channels
    await androidImplementation?.createNotificationChannel(defaultChannel);
    await androidImplementation?.createNotificationChannel(
      dailyChallengeChannel,
    );
    await androidImplementation?.createNotificationChannel(firebaseChannel);

    // iOS permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      LoggerService.logInfo('FCM Token obtained: $_fcmToken');
    } catch (e) {
      LoggerService.logError('Error getting FCM token: $e');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      return _fcmToken;
    } catch (e) {
      LoggerService.logError('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      LoggerService.logInfo('FCM Token deleted');
    } catch (e) {
      LoggerService.logError('Error deleting FCM token: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final androidNotification = AndroidNotificationDetails(
      'firebase_messaging_channel',
      'Firebase Notifications',
      channelDescription: 'Notifications from Firebase Cloud Messaging',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
    );

    final iosNotification = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
    );

    final details = NotificationDetails(
      android: androidNotification,
      iOS: iosNotification,
    );

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - can navigate to specific screen
    LoggerService.logInfo('Notification tapped with data: ${message.data}');
    // You can add navigation logic here based on message.data
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    LoggerService.logInfo('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotification(NotificationResponse response) {
    LoggerService.logInfo(
      'Background notification tapped: ${response.payload}',
    );
  }

  // Local Notification Methods

  /// Show a notification using the default channel
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription:
          'Default notification channel for general notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload != null ? _mapToString(payload) : null,
    );

    LoggerService.logInfo('Notification shown: $title');
  }

  Future<void> showDailyChallengeNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'daily_challenge_channel',
      'Daily Challenge Reminders',
      channelDescription:
          'Notifications for daily challenges and star earnings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
      autoCancel: false,
      ongoing: false,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload != null ? _mapToString(payload) : null,
    );

    LoggerService.logInfo('Daily challenge notification shown: $title');
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required Time scheduledTime,
    Map<String, dynamic>? payload,
  }) async {
    // Cancel existing notification with this ID first to prevent duplicates
    await _localNotifications.cancel(id);

    final androidDetails = AndroidNotificationDetails(
      'daily_challenge_channel',
      'Daily Challenge Reminders',
      channelDescription:
          'Notifications for daily challenges and star earnings',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.wav',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();
    var scheduledDateTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload != null ? _mapToString(payload) : null,
    );

    LoggerService.logInfo(
      'Daily notification scheduled for $scheduledDateTime: $title',
    );
  }

  Future<void> scheduleDailyNotifications({
    required int morningId,
    required String morningTitle,
    required String morningBody,
    required Time morningTime,
    required int eveningId,
    required String eveningTitle,
    required String eveningBody,
    required Time eveningTime,
  }) async {
    // Schedule morning notification
    await scheduleDailyNotification(
      id: morningId,
      title: morningTitle,
      body: morningBody,
      scheduledTime: morningTime,
      payload: {'type': 'morning_challenge'},
    );

    // Schedule evening notification
    await scheduleDailyNotification(
      id: eveningId,
      title: eveningTitle,
      body: eveningBody,
      scheduledTime: eveningTime,
      payload: {'type': 'evening_challenge'},
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    LoggerService.logInfo('Notification cancelled: $id');
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    LoggerService.logInfo('All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>?> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  String _mapToString(Map<String, dynamic> payload) {
    return payload.entries.map((e) => '${e.key}=${e.value}').join(',');
  }
}

class Time {
  final int hour;
  final int minute;
  final int second;

  const Time({this.hour = 0, this.minute = 0, this.second = 0});
}
