import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/remote_config_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  static const _channel = MethodChannel('com.byteberg.kids_learning/update');

  /// Check if an update is required based on Firebase Remote Config.
  /// Returns a result with update status and whether it should be forced.
  Future<UpdateCheckResult> checkUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final remoteConfig = RemoteConfigService();
      final minVersion = remoteConfig.remoteConfig.getString(
        'minimum_required_version',
      );
      final forceUpdate = remoteConfig.remoteConfig.getBool('force_update');

      LoggerService.logInfo(
        '[AppUpdate] current=$currentVersion, min=$minVersion, force=$forceUpdate',
      );

      if (minVersion.isEmpty) {
        return UpdateCheckResult(status: UpdateStatus.upToDate);
      }

      final needsUpdate = _isVersionLower(currentVersion, minVersion);
      if (!needsUpdate) {
        return UpdateCheckResult(status: UpdateStatus.upToDate);
      }

      return UpdateCheckResult(
        status: forceUpdate
            ? UpdateStatus.forceUpdateRequired
            : UpdateStatus.updateAvailable,
        availableVersion: minVersion,
      );
    } catch (e) {
      LoggerService.logError('[AppUpdate] Error checking update: $e');
      return UpdateCheckResult(status: UpdateStatus.error);
    }
  }

  /// Trigger the native Google Play immediate (blocking) update flow.
  /// Only works on Android.
  Future<bool> triggerImmediateUpdate() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'triggerImmediateUpdate',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      LoggerService.logError('[AppUpdate] Immediate update failed: $e');
      return false;
    }
  }

  /// Trigger the native Google Play flexible (background) update flow.
  /// Only works on Android.
  Future<bool> triggerFlexibleUpdate() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('triggerFlexibleUpdate');
      return result ?? false;
    } on PlatformException catch (e) {
      LoggerService.logError('[AppUpdate] Flexible update failed: $e');
      return false;
    }
  }

  /// Complete a previously downloaded flexible update.
  Future<bool> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'completeFlexibleUpdate',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      LoggerService.logError('[AppUpdate] Complete update failed: $e');
      return false;
    }
  }

  /// Returns true if [current] is lower than [minimum].
  bool _isVersionLower(String current, String minimum) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final m = minimum.split('.').map(int.parse).toList();

      for (var i = 0; i < m.length && i < c.length; i++) {
        if (c[i] < m[i]) return true;
        if (c[i] > m[i]) return false;
      }
      return m.length > c.length;
    } catch (e) {
      return false;
    }
  }
}

enum UpdateStatus { upToDate, updateAvailable, forceUpdateRequired, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final String? availableVersion;

  UpdateCheckResult({required this.status, this.availableVersion});
}
