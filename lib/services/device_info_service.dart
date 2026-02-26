import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kids_learning/services/logger_service.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  static DeviceInfoService get instance => _instance;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'osVersion': 'Android ${androidInfo.version.release}',
          'platform': 'android',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'model': iosInfo.utsname.machine,
          'brand': 'Apple',
          'osVersion': 'iOS ${iosInfo.systemVersion}',
          'platform': 'ios',
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      LoggerService.logError('Error getting device info: $e');
      return {'platform': 'unknown'};
    }
  }

  Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      LoggerService.logError('Error getting app version: $e');
      return 'unknown';
    }
  }
}
