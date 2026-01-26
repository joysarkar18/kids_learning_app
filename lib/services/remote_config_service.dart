import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'dart:convert';

import 'package:kids_learning/services/logger_service.dart';

class RemoteConfigService {
  // Singleton instance
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // Cached data
  List<String>? _drawingImages;
  List<String>? _filledImages;

  /// Initialize Remote Config - Call this at app startup
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1), // Adjust as needed
        ),
      );

      // Set default values (optional - fallback if fetch fails)
      await _remoteConfig.setDefaults({
        'drawing_images': '[]',
        'filled_images': '[]',
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();

      // Load all data into cache
      _loadAllData();

      _initialized = true;
      LoggerService.logInfo('✅ Remote Config initialized successfully');
    } catch (e) {
      LoggerService.logError('❌ Failed to initialize Remote Config: $e');
      // Still mark as initialized to prevent repeated attempts
      _initialized = true;
    }
  }

  /// Force refresh data from Remote Config
  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _loadAllData();
      LoggerService.logInfo('✅ Remote Config refreshed successfully');
    } catch (e) {
      LoggerService.logError('❌ Failed to refresh Remote Config: $e');
    }
  }

  /// Load all data into cache
  void _loadAllData() {
    _drawingImages = _getStringList('drawing_images');
    _filledImages = _getStringList('filled_images');
  }

  /// Helper to parse JSON string list
  List<String> _getStringList(String key) {
    try {
      String jsonString = _remoteConfig.getString(key);
      if (jsonString.isEmpty) return [];
      List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      LoggerService.logError('❌ Error parsing $key: $e');
      return [];
    }
  }

  // ============================================
  // Getters for your config data
  // ============================================

  /// Get drawing images (outline/coloring images)
  List<String> get drawingImages {
    if (!_initialized) {
      LoggerService.logInfo(
        '⚠️ Remote Config not initialized. Call initialize() first.',
      );
      return [];
    }
    return _drawingImages ?? [];
  }

  /// Get filled images (colored reference images)
  List<String> get filledImages {
    if (!_initialized) {
      LoggerService.logInfo(
        '⚠️ Remote Config not initialized. Call initialize() first.',
      );
      return [];
    }
    return _filledImages ?? [];
  }

  // ============================================
  // Easy to add more fields - Examples:
  // ============================================

  // Example: Add a string config
  // String get appVersion => _remoteConfig.getString('app_version');

  // Example: Add a boolean config
  // bool get isFeatureEnabled => _remoteConfig.getBool('feature_enabled');

  // Example: Add an int config
  // int get maxDrawings => _remoteConfig.getInt('max_drawings');

  // Example: Add another string list
  // List<String> get categoryImages => _getStringList('category_images');

  // Example: Add a JSON object
  // Map<String, dynamic> get appSettings {
  //   try {
  //     String jsonString = _remoteConfig.getString('app_settings');
  //     return json.decode(jsonString);
  //   } catch (e) {
  //     return {};
  //   }
  // }
}
