import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

/// Centralized analytics service using Mixpanel
///
/// Usage:
/// ```dart
/// await AnalyticsService().initialize();
/// AnalyticsService().track('Event Name', properties: {'key': 'value'});
/// AnalyticsService().identify(userId);
/// ```
class AnalyticsService {
  // Singleton instance
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Mixpanel? _mixpanel;
  bool _isInitialized = false;

  /// Mixpanel project token
  static const String _mixpanelToken = '103481a31325fb8226ac6c2d7b377658';

  /// Initialize Mixpanel
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📊 AnalyticsService: Already initialized');
      return;
    }

    try {
      // Skip analytics in debug mode if desired
      // Uncomment the following lines to disable analytics in debug mode:
      // if (kDebugMode) {
      //   debugPrint('📊 AnalyticsService: Skipping initialization in debug mode');
      //   return;
      // }

      _mixpanel = await Mixpanel.init(
        _mixpanelToken,
        trackAutomaticEvents: true,
      );

      _isInitialized = true;
      debugPrint('✅ AnalyticsService: Initialized successfully');

      // Track app opened
      track('App Opened');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Initialization failed: $e');
    }
  }

  /// Track an event with optional properties
  void track(String eventName, {Map<String, dynamic>? properties}) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping event: $eventName');
      return;
    }

    try {
      _mixpanel!.track(eventName, properties: properties);
      debugPrint('📊 AnalyticsService: Tracked "$eventName" ${properties != null ? "with properties: $properties" : ""}');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error tracking event "$eventName": $e');
    }
  }

  /// Identify a user
  void identify(String userId) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping identify');
      return;
    }

    try {
      _mixpanel!.identify(userId);
      debugPrint('📊 AnalyticsService: Identified user: $userId');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error identifying user: $e');
    }
  }

  /// Set user properties
  void setUserProperties(Map<String, dynamic> properties) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping set user properties');
      return;
    }

    try {
      final people = _mixpanel!.getPeople();
      people.set('\$name', properties['name']);
      people.set('\$email', properties['email']);

      // Set custom properties
      properties.forEach((key, value) {
        if (key != 'name' && key != 'email') {
          people.set(key, value);
        }
      });

      debugPrint('📊 AnalyticsService: Set user properties: $properties');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error setting user properties: $e');
    }
  }

  /// Increment a user property (useful for counters)
  void incrementUserProperty(String property, [double value = 1.0]) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping increment');
      return;
    }

    try {
      final people = _mixpanel!.getPeople();
      people.increment(property, value);
      debugPrint('📊 AnalyticsService: Incremented "$property" by $value');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error incrementing property: $e');
    }
  }

  /// Set super properties (sent with every event)
  void setSuperProperties(Map<String, dynamic> properties) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping super properties');
      return;
    }

    try {
      _mixpanel!.registerSuperProperties(properties);
      debugPrint('📊 AnalyticsService: Set super properties: $properties');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error setting super properties: $e');
    }
  }

  /// Reset (logout)
  void reset() {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping reset');
      return;
    }

    try {
      _mixpanel!.reset();
      debugPrint('📊 AnalyticsService: Reset user identity');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error resetting: $e');
    }
  }

  /// Time an event (start)
  void timeEvent(String eventName) {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('⚠️  AnalyticsService: Not initialized, skipping time event');
      return;
    }

    try {
      _mixpanel!.timeEvent(eventName);
      debugPrint('📊 AnalyticsService: Started timing "$eventName"');
    } catch (e) {
      debugPrint('❌ AnalyticsService: Error timing event: $e');
    }
  }

  // ========================================================================
  // ONBOARDING FUNNEL EVENTS
  // ========================================================================

  /// Track onboarding started
  void trackOnboardingStarted() {
    track('Onboarding Started');
    timeEvent('Onboarding Completed'); // Start timing the full onboarding
  }

  /// Track onboarding step viewed
  void trackOnboardingStepViewed(String stepName, int stepIndex) {
    track('Onboarding Step Viewed', properties: {
      'step_name': stepName,
      'step_index': stepIndex,
      'step_total': 8, // Total number of steps
    });

    // Start timing this specific step
    timeEvent('Onboarding Step Completed');
  }

  /// Track onboarding step completed
  void trackOnboardingStepCompleted(String stepName, int stepIndex, {Map<String, dynamic>? additionalProperties}) {
    final properties = <String, dynamic>{
      'step_name': stepName,
      'step_index': stepIndex,
      'step_total': 8,
    };

    if (additionalProperties != null) {
      properties.addAll(additionalProperties);
    }

    track('Onboarding Step Completed', properties: properties);
  }

  /// Track onboarding completed successfully
  void trackOnboardingCompleted({
    required String username,
    required String authMethod,
    bool hasFullName = false,
    bool hasBirthday = false,
    bool hasGender = false,
    int shoppingInterestsCount = 0,
  }) {
    track('Onboarding Completed', properties: {
      'username': username,
      'auth_method': authMethod,
      'has_full_name': hasFullName,
      'has_birthday': hasBirthday,
      'has_gender': hasGender,
      'shopping_interests_count': shoppingInterestsCount,
      'profile_completion': _calculateProfileCompletion(
        hasFullName: hasFullName,
        hasBirthday: hasBirthday,
        hasGender: hasGender,
        shoppingInterestsCount: shoppingInterestsCount,
      ),
    });

    // Increment user's onboarding completion counter
    incrementUserProperty('onboardings_completed');
  }

  /// Track onboarding abandoned
  void trackOnboardingAbandoned(String stepName, int stepIndex) {
    track('Onboarding Abandoned', properties: {
      'step_name': stepName,
      'step_index': stepIndex,
      'step_total': 8,
    });
  }

  /// Calculate profile completion percentage
  int _calculateProfileCompletion({
    required bool hasFullName,
    required bool hasBirthday,
    required bool hasGender,
    required int shoppingInterestsCount,
  }) {
    int completed = 0;
    int total = 4;

    if (hasFullName) completed++;
    if (hasBirthday) completed++;
    if (hasGender) completed++;
    if (shoppingInterestsCount > 0) completed++;

    return ((completed / total) * 100).round();
  }

  // ========================================================================
  // AUTHENTICATION EVENTS
  // ========================================================================

  /// Track sign up attempt
  void trackSignUpAttempt(String method) {
    track('Sign Up Attempt', properties: {
      'method': method, // 'email', 'google', 'apple'
    });
  }

  /// Track sign up success
  void trackSignUpSuccess(String method) {
    track('Sign Up Success', properties: {
      'method': method,
    });
  }

  /// Track sign up failure
  void trackSignUpFailure(String method, String error) {
    track('Sign Up Failure', properties: {
      'method': method,
      'error': error,
    });
  }

  /// Track sign in attempt
  void trackSignInAttempt(String method) {
    track('Sign In Attempt', properties: {
      'method': method,
    });
  }

  /// Track sign in success
  void trackSignInSuccess(String method) {
    track('Sign In Success', properties: {
      'method': method,
    });
  }

  /// Track sign in failure
  void trackSignInFailure(String method, String error) {
    track('Sign In Failure', properties: {
      'method': method,
      'error': error,
    });
  }

  // ========================================================================
  // USERNAME EVENTS
  // ========================================================================

  /// Track username check
  void trackUsernameCheck(String username, bool available) {
    track('Username Checked', properties: {
      'username_length': username.length,
      'available': available,
    });
  }

  /// Track username selected
  void trackUsernameSelected(String username, bool wasGenerated) {
    track('Username Selected', properties: {
      'username': username,
      'username_length': username.length,
      'was_generated': wasGenerated,
    });
  }

  // ========================================================================
  // PROFILE EVENTS
  // ========================================================================

  /// Track profile info added
  void trackProfileInfoAdded({
    bool hasFullName = false,
    bool hasBirthday = false,
    bool hasGender = false,
  }) {
    track('Profile Info Added', properties: {
      'has_full_name': hasFullName,
      'has_birthday': hasBirthday,
      'has_gender': hasGender,
    });
  }

  /// Track shopping interests selected
  void trackShoppingInterestsSelected(List<String> interests) {
    track('Shopping Interests Selected', properties: {
      'interests_count': interests.length,
      'interests': interests,
    });
  }

  /// Track notification preferences set
  void trackNotificationPreferencesSet(Map<String, bool> preferences) {
    final enabledCount = preferences.values.where((v) => v).length;
    track('Notification Preferences Set', properties: {
      'enabled_count': enabledCount,
      'total_count': preferences.length,
      'preferences': preferences,
    });
  }
}
