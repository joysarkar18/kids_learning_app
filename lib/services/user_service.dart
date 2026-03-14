import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_learning/services/device_info_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/notification_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static UserService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData(User user) async {
    try {
      final deviceInfo = await DeviceInfoService.instance.getDeviceInfo();
      final appVersion = await DeviceInfoService.instance.getAppVersion();
      final now = FieldValue.serverTimestamp();

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      // Get FCM token
      final fcmToken = await NotificationService.instance.getFCMToken();

      if (userDoc.exists) {
        // Update existing user
        await userRef.update({
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLoginAt': now,
          'appVersion': appVersion,
          'currentDevice': {...deviceInfo, 'lastUsedAt': now},
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        });
        LoggerService.logInfo('User data updated for: ${user.email}');
      } else {
        // Create new user
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': now,
          'lastLoginAt': now,
          'appVersion': appVersion,
          'currentDevice': {...deviceInfo, 'lastUsedAt': now},
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        });
        LoggerService.logInfo('New user created: ${user.email}');
      }

      // Save device to subcollection: users/{uid}/devices/{deviceId}
      final deviceId = deviceInfo['deviceId'] as String? ?? 'unknown';
      await userRef.collection('devices').doc(deviceId).set({
        ...deviceInfo,
        'lastUsedAt': now,
        'appVersion': appVersion,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
      }, SetOptions(merge: true));

      LoggerService.logInfo('Device info saved: $deviceId');
      if (fcmToken != null && fcmToken.isNotEmpty) {
        LoggerService.logInfo('FCM Token saved to Firestore: $fcmToken');
      }
    } catch (e) {
      LoggerService.logError('Error saving user data: $e');
    }
  }

  /// Save or update FCM token for the current user
  Future<void> saveFCMToken(String fcmToken) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        LoggerService.logWarning('No user logged in, cannot save FCM token');
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Also update in user's devices subcollection
      final deviceInfo = await DeviceInfoService.instance.getDeviceInfo();
      final deviceId = deviceInfo['deviceId'] as String? ?? 'unknown';
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .update({
            'fcmToken': fcmToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });

      LoggerService.logInfo('FCM token updated for user: ${user.email}');
    } catch (e) {
      LoggerService.logError('Error saving FCM token: $e');
    }
  }

  /// Delete FCM token from Firestore on logout
  Future<void> deleteFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });

      LoggerService.logInfo('FCM token removed for user: ${user.email}');
    } catch (e) {
      LoggerService.logError('Error deleting FCM token: $e');
    }
  }
}
