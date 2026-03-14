# Notification System Implementation

This document describes the comprehensive notification system implementation using `flutter_local_notifications` and Firebase Cloud Messaging (FCM).

## Features Implemented

### 1. Firebase Cloud Messaging (FCM) Integration
- **Automatic token generation** on app startup
- **FCM token storage** in Firestore when user logs in
- **Token cleanup** on user logout
- **Foreground message handling** with custom notifications
- **Background notification tap handling**

### 2. Local Notifications
- **Custom notification sound** (`notification_sound.wav`)
- **Persistent sound file** via `keep.xml` to prevent removal during build
- **High priority notifications** with sound, vibration, and lights
- **Custom notification channel** for daily challenges

### 3. Daily Challenge Notifications
- **Two scheduled notifications per day**:
  - **Morning reminder**: 9:00 AM - "Complete Your Daily Challenge! 🌟"
  - **Evening reminder**: 7:00 PM - "Don't Miss Your Stars! ⭐"
- **Automatic scheduling** on app initialization
- **User controllable** via settings (enable/disable)
- **Persistent across reboots** via BOOT_COMPLETED receiver

## Files Created/Modified

### New Files

1. **`lib/services/notification_service.dart`**
   - Core notification service handling FCM and local notifications
   - Methods for showing, scheduling, and canceling notifications
   - Permission management

2. **`lib/services/daily_notification_scheduler.dart`**
   - Manages daily challenge notification scheduling
   - Provides methods to enable/disable specific notifications
   - Stores user preferences in SharedPreferences

3. **`android/app/src/main/res/raw/keep.xml`**
   - Preserves notification sound file during build optimization

### Modified Files

1. **`pubspec.yaml`**
   - Added dependencies:
     - `firebase_messaging: ^16.1.2`
     - `flutter_local_notifications: ^18.0.1`
     - `timezone: ^0.10.1`

2. **`android/app/src/main/AndroidManifest.xml`**
   - Added notification permissions:
     - `POST_NOTIFICATIONS`
     - `RECEIVE_BOOT_COMPLETED`
     - `VIBRATE`
     - `WAKE_LOCK`
     - `SCHEDULE_EXACT_ALARM`
     - `USE_EXACT_ALARM`
   - Added Firebase Messaging Service
   - Added Boot Receiver for notification rescheduling

3. **`lib/services/user_service.dart`**
   - Added FCM token saving to Firestore on login
   - Added methods to update/delete FCM tokens
   - Stores token in both user document and devices subcollection

4. **`lib/services/auth_service.dart`**
   - Integrated FCM token saving on sign-in
   - Added token cleanup on sign-out

5. **`lib/main.dart`**
   - Initialize NotificationService on app startup
   - Initialize DailyNotificationScheduler on app startup
   - Request notification permissions

## Usage

### Initialize Notifications (Already done in main.dart)

```dart
await NotificationService.instance.initialize();
await DailyNotificationScheduler.instance.initialize();
```

### Get FCM Token

```dart
String? token = await NotificationService.instance.getFCMToken();
```

### Show Immediate Notification

```dart
await NotificationService.instance.showDailyChallengeNotification(
  id: 1,
  title: 'Challenge Available!',
  body: 'Complete your daily challenge now!',
);
```

### Schedule Daily Notifications

```dart
await DailyNotificationScheduler.instance.scheduleAllNotifications();
```

### Enable/Disable Notifications

```dart
// Morning notifications
await DailyNotificationScheduler.instance.setMorningNotificationEnabled(true);

// Evening notifications
await DailyNotificationScheduler.instance.setEveningNotificationEnabled(false);

// Check status
bool isEnabled = await DailyNotificationScheduler.instance.isMorningNotificationEnabled();
```

### Cancel All Notifications

```dart
await DailyNotificationScheduler.instance.cancelAllNotifications();
```

## Firestore Structure

FCM tokens are stored in two locations:

1. **User Document**: `users/{userId}`
   ```
   {
     fcmToken: "token_string",
     fcmTokenUpdatedAt: Timestamp
   }
   ```

2. **Device Subcollection**: `users/{userId}/devices/{deviceId}`
   ```
   {
     fcmToken: "token_string",
     fcmTokenUpdatedAt: Timestamp
   }
   ```

## Testing

### Test Immediate Notification
```dart
await DailyNotificationScheduler.instance.showImmediateChallengeNotification();
```

### Check Pending Notifications
```dart
int count = await DailyNotificationScheduler.instance.getPendingNotificationCount();
List<String> titles = await DailyNotificationScheduler.instance.getPendingNotificationTitles();
```

## Important Notes

1. **iOS Configuration**: For iOS, you need to:
   - Enable Push Notifications capability in Xcode
   - Upload APNs certificate to Firebase Console
   - Test on physical device (simulator doesn't support push notifications)

2. **Android Configuration**: 
   - For Android 13+ (API 33+), POST_NOTIFICATIONS permission is required
   - For exact alarms, SCHEDULE_EXACT_ALARM permission may need user approval

3. **Custom Sound**: 
   - Sound file is located at `android/app/src/main/res/raw/notification_sound.wav`
   - File is preserved via `keep.xml` during build optimization
   - Format should be WAV or MP3 for best compatibility

4. **Firebase Setup**:
   - Ensure `google-services.json` is in `android/app/`
   - Ensure `GoogleService-Info.plist` is in `ios/Runner/`
   - Configure Firebase Cloud Messaging in Firebase Console

## Sending FCM Notifications from Server

Example curl command to send a test notification:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Daily Challenge",
      "body": "Complete your challenge now!",
      "sound": "notification_sound"
    },
    "data": {
      "type": "daily_challenge"
    }
  }'
```

## Troubleshooting

1. **Notifications not showing**: Check notification permissions in device settings
2. **Sound not playing**: Verify sound file exists in `res/raw/` and is referenced correctly
3. **FCM token not saving**: Ensure user is logged in and Firestore rules allow writes
4. **Scheduled notifications not firing**: Check that exact alarm permissions are granted
