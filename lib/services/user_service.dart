import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kids_learning/services/device_info_service.dart';
import 'package:kids_learning/services/logger_service.dart';

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

      if (userDoc.exists) {
        // Update existing user
        await userRef.update({
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastLoginAt': now,
          'appVersion': appVersion,
          'currentDevice': {...deviceInfo, 'lastUsedAt': now},
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
        });
        LoggerService.logInfo('New user created: ${user.email}');
      }

      // Save device to subcollection: users/{uid}/devices/{deviceId}
      final deviceId = deviceInfo['deviceId'] as String? ?? 'unknown';
      await userRef.collection('devices').doc(deviceId).set({
        ...deviceInfo,
        'lastUsedAt': now,
        'appVersion': appVersion,
      }, SetOptions(merge: true));

      LoggerService.logInfo('Device info saved: $deviceId');
    } catch (e) {
      LoggerService.logError('Error saving user data: $e');
    }
  }
}
