import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Utility class for logging errors and events to Firebase Crashlytics
class CrashlyticsLogger {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Log a non-fatal error to Crashlytics
  /// This is useful for caught exceptions that you want to track
  static Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    try {
      // Add context as custom keys if provided
      if (context != null) {
        for (var entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Log the error
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      // Also print to console in debug mode
      if (kDebugMode) {
        debugPrint('🔥 Crashlytics Error: $exception');
        if (reason != null) debugPrint('   Reason: $reason');
        if (context != null) debugPrint('   Context: $context');
      }
    } catch (e) {
      // Don't let Crashlytics logging errors crash the app
      debugPrint('Failed to log error to Crashlytics: $e');
    }
  }

  /// Log a message to Crashlytics
  /// Useful for tracking key events in your app
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      if (kDebugMode) {
        debugPrint('📝 Crashlytics Log: $message');
      }
    } catch (e) {
      debugPrint('Failed to log message to Crashlytics: $e');
    }
  }

  /// Set user identifier for crash reports
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Failed to set user ID in Crashlytics: $e');
    }
  }

  /// Set custom key-value pair for crash reports
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('Failed to set custom key in Crashlytics: $e');
    }
  }

  /// Clear user data (e.g., on logout)
  static Future<void> clearUserData() async {
    try {
      await _crashlytics.setUserIdentifier('');
    } catch (e) {
      debugPrint('Failed to clear user data in Crashlytics: $e');
    }
  }

  /// Force a test crash (only use for testing Crashlytics setup!)
  static void testCrash() {
    _crashlytics.crash();
  }
}
