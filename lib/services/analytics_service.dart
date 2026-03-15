import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  late final FirebaseAnalyticsObserver _observer;

  bool get isEnabled => !kDebugMode;

  FirebaseAnalyticsObserver get observer => _observer;

  AnalyticsService._internal() {
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  /// Log screen view events
  Future<void> logScreenView(
    String screenName, {
    Map<String, Object>? parameters,
  }) async {
    if (!isEnabled) return;

    await _analytics.logScreenView(
      screenName: screenName,
      parameters: parameters,
    );
  }

  /// Log button tap events
  Future<void> logButtonTap(String buttonName, {String? screenName}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'button_tap',
      parameters: {
        'button_name': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  /// Log learning activity completion
  Future<void> logActivityCompletion(
    String activityType, {
    String? language,
  }) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'activity_completed',
      parameters: {
        'activity_type': activityType,
        if (language != null) 'language': language,
      },
    );
  }

  /// Log audio playback events
  Future<void> logAudioPlayback(String audioType, {String? audioId}) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'audio_playback',
      parameters: {
        'audio_type': audioType,
        if (audioId != null) 'audio_id': audioId,
      },
    );
  }

  /// Log story reading events
  Future<void> logStoryRead(
    String storyId, {
    String? language,
    int? duration,
  }) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'story_read',
      parameters: {
        'story_id': storyId,
        if (language != null) 'language': language,
        if (duration != null) 'duration_seconds': duration,
      },
    );
  }

  /// Log game/play interaction
  Future<void> logInteraction(
    String interactionType, {
    Map<String, Object>? extraParams,
  }) async {
    if (!isEnabled) return;

    final parameters = <String, Object>{
      'interaction_type': interactionType,
      if (extraParams != null) ...extraParams,
    };

    await _analytics.logEvent(name: 'user_interaction', parameters: parameters);
  }

  /// Log onboarding completion
  Future<void> logOnboardingCompleted() async {
    if (!isEnabled) return;

    await _analytics.logEvent(name: 'onboarding_completed');
  }

  /// Log language selection
  Future<void> logLanguageSelected(String language) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'language_selected',
      parameters: {'language': language},
    );
  }

  /// Log daily challenge completion
  Future<void> logDailyChallengeCompleted(String challengeType) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'daily_challenge_completed',
      parameters: {'challenge_type': challengeType},
    );
  }

  /// Log user sign up
  Future<void> logSignUp(String signUpMethod) async {
    if (!isEnabled) return;

    await _analytics.logSignUp(signUpMethod: signUpMethod);
  }

  /// Log user login
  Future<void> logLogin(String loginMethod) async {
    if (!isEnabled) return;

    await _analytics.logLogin(loginMethod: loginMethod);
  }

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    if (!isEnabled) return;

    await _analytics.setUserId(id: userId);
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!isEnabled) return;

    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Log tutorial completion
  Future<void> logTutorialCompleted(String tutorialId) async {
    if (!isEnabled) return;

    await _analytics.logTutorialBegin();
    await _analytics.logEvent(
      name: 'tutorial_completed',
      parameters: {'tutorial_id': tutorialId},
    );
  }

  /// Log achievement unlocked
  Future<void> logAchievementUnlocked(
    String achievementId, {
    String? achievementName,
  }) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_id': achievementId,
        if (achievementName != null) 'achievement_name': achievementName,
      },
    );
  }

  /// Log session duration
  Future<void> logSessionDuration(int durationSeconds) async {
    if (!isEnabled) return;

    await _analytics.logEvent(
      name: 'session_duration',
      parameters: {'duration_seconds': durationSeconds},
    );
  }
}
