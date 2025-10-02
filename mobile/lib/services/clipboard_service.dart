import 'dart:io';
import 'package:flutter/services.dart';

class ClipboardService {
  static String? _lastCheckedUrl;

  /// Checks clipboard for URLs (iOS only)
  /// Returns the URL if found and it's different from the last checked URL
  static Future<String?> checkForUrl() async {
    // Only check on iOS
    if (!Platform.isIOS) {
      return null;
    }

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text?.trim();

      if (text == null || text.isEmpty) {
        return null;
      }

      // Check if it's a URL
      if (!_isValidUrl(text)) {
        return null;
      }

      // Check if we've already shown this URL
      if (text == _lastCheckedUrl) {
        return null;
      }

      // Store this URL as the last checked
      _lastCheckedUrl = text;
      return text;
    } catch (e) {
      // Silently fail - clipboard access issues shouldn't break the app
      return null;
    }
  }

  /// Validates if a string is a valid URL
  static bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme &&
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Resets the last checked URL (useful for testing or clearing state)
  static void resetLastChecked() {
    _lastCheckedUrl = null;
  }
}
