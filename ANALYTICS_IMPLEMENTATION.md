# Firebase Analytics Implementation

## Overview
Basic Firebase Analytics has been added to track user interactions and app usage.

## What's Included

### 1. Analytics Service (`lib/services/analytics_service.dart`)
A centralized service for tracking various events:

- **Screen Views**: Automatically tracked via router observer
- **Button Taps**: Track specific button interactions
- **Activity Completion**: Track learning activities
- **Audio Playback**: Track audio interactions
- **Story Reading**: Track story engagement
- **User Interactions**: General interaction tracking
- **Onboarding**: Track onboarding funnel
- **Language Selection**: Track language preferences
- **Daily Challenges**: Track challenge engagement
- **Authentication**: Track sign-up/login events
- **Achievements**: Track gamification events
- **User Properties**: Set user segments

### 2. Automatic Screen Tracking
The router is configured with `FirebaseAnalyticsObserver` to automatically track screen views.

## Usage Examples

### Import the Service
```dart
import 'package:kids_learning/services/analytics_service.dart';
```

### Track Button Taps
```dart
// In your widget
ElevatedButton(
  onPressed: () {
    AnalyticsService().logButtonTap(
      'start_learning',
      screenName: 'home',
    );
    // Navigate or perform action
  },
  child: Text('Start Learning'),
)
```

### Track Activity Completion
```dart
// When user completes a learning activity
AnalyticsService().logActivityCompletion(
  'alphabet_matching',
  language: 'en',
);
```

### Track Audio Playback
```dart
// When audio starts playing
AnalyticsService().logAudioPlayback(
  'narration',
  audioId: 'story_001',
);
```

### Track Story Reading
```dart
// When user finishes a story
AnalyticsService().logStoryRead(
  'story_001',
  language: 'bn',
  duration: 180, // seconds
);
```

### Track Language Selection
```dart
// When user selects a language
AnalyticsService().logLanguageSelected('en');
```

### Track Onboarding Completion
```dart
// When user completes onboarding
AnalyticsService().logOnboardingCompleted();
```

### Track Daily Challenge Completion
```dart
// When user completes daily challenge
AnalyticsService().logDailyChallengeCompleted('math_quiz');
```

### Track Achievements
```dart
// When user unlocks an achievement
AnalyticsService().logAchievementUnlocked(
  'first_story',
  achievementName: 'Story Explorer',
);
```

### Set User ID (After Login)
```dart
// After user logs in
final userId = AuthService.instance.currentUser?.uid;
if (userId != null) {
  await AnalyticsService().setUserId(userId);
}
```

### Set User Properties
```dart
// Set user preferences for segmentation
AnalyticsService().setUserProperty(
  name: 'preferred_language',
  value: 'bn',
);

AnalyticsService().setUserProperty(
  name: 'subscription_tier',
  value: 'free',
);
```

## Automatic Tracking

The following are tracked automatically:

1. **Screen Views**: Every screen navigation is logged with the screen name
2. **Session Duration**: Firebase automatically tracks session length

## Debug Mode

Analytics is **disabled in debug mode** by default. It will only be enabled in release builds.

To test analytics in debug mode, modify the service:
```dart
bool get isEnabled => true; // Force enable for testing
```

## Viewing Analytics Data

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Analytics > Dashboard**
4. View events in **Realtime** (for testing) or **Event reports** (processed data)

## Custom Event Parameters

All custom events support additional parameters:
- Strings
- Numbers (int, double)
- Null values are automatically filtered

Example:
```dart
AnalyticsService().logInteraction(
  'game_play',
  extraParams: {
    'level': 5,
    'score': 1000,
    'difficulty': 'hard',
  },
);
```

## Best Practices

1. **Consistent Naming**: Use snake_case for event names
2. **Meaningful Parameters**: Add context to events with parameters
3. **Don't Over-Track**: Focus on meaningful interactions
4. **Privacy**: Don't track sensitive user information
5. **Test**: Use Firebase DebugView during development

## Events Summary

| Event Name | Description | Parameters |
|------------|-------------|------------|
| `screen_view` | Automatic screen tracking | `screen_name` |
| `button_tap` | Button interactions | `button_name`, `screen_name` |
| `activity_completed` | Learning activity completion | `activity_type`, `language` |
| `audio_playback` | Audio played | `audio_type`, `audio_id` |
| `story_read` | Story reading session | `story_id`, `language`, `duration_seconds` |
| `user_interaction` | General interactions | `interaction_type`, ...extra |
| `onboarding_completed` | Onboarding finished | - |
| `language_selected` | Language choice | `language` |
| `daily_challenge_completed` | Challenge completion | `challenge_type` |
| `achievement_unlocked` | Achievement earned | `achievement_id`, `achievement_name` |
| `session_duration` | Session length | `duration_seconds` |
