import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Builds a comprehensive User-Agent string for API requests
/// Format: Jinnie/1.0.3 (iOS 17.1; iPhone15,2; en-US) Build/456
class UserAgentBuilder {
  static String? _cachedUserAgent;

  /// Get the User-Agent string (cached after first call)
  static Future<String> getUserAgent() async {
    if (_cachedUserAgent != null) {
      return _cachedUserAgent!;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String platform;
      String osVersion;
      String deviceModel;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'Android';
        osVersion = androidInfo.version.release; // e.g., "14"
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}'; // e.g., "Google Pixel 7"
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'iOS';
        osVersion = iosInfo.systemVersion; // e.g., "17.1"
        deviceModel = iosInfo.utsname.machine; // e.g., "iPhone15,2"
      } else {
        // Fallback for other platforms (web, desktop)
        platform = Platform.operatingSystem;
        osVersion = Platform.operatingSystemVersion;
        deviceModel = 'Unknown';
      }

      // Get locale (language-country)
      final locale = Platform.localeName; // e.g., "en_US"

      // Build User-Agent string
      // Format: Jinnie/1.0.3 (iOS 17.1; iPhone15,2; en_US) Build/456
      _cachedUserAgent = 'Jinnie/${packageInfo.version} '
          '($platform $osVersion; $deviceModel; $locale) '
          'Build/${packageInfo.buildNumber}';

      if (kDebugMode) {
        debugPrint('📱 User-Agent: $_cachedUserAgent');
      }

      return _cachedUserAgent!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error building User-Agent: $e');
      }

      // Fallback User-Agent if something goes wrong
      return 'Jinnie/1.0.0 (Unknown)';
    }
  }

  /// Clear cached User-Agent (useful for testing or if app updates)
  static void clearCache() {
    _cachedUserAgent = null;
  }

  /// Get just the platform name (iOS/Android) for quick checks
  static String getPlatformName() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    }
    return Platform.operatingSystem;
  }
}
