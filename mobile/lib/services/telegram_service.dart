import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TelegramService {
  static final TelegramService _instance = TelegramService._internal();
  static TelegramService get instance => _instance;
  TelegramService._internal();

  static const String _baseUrl = 'https://openai-rewrite.onrender.com';
  final Dio _dio = Dio();

  /// Send screenshot notification to Telegram via backend
  Future<void> sendScreenshotNotification(String eventDetails) async {
    try {
      // Get device and app information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final timestamp = DateTime.now().toIso8601String();

      // Prepare message
      final message = '''📸 SCREENSHOT DETECTED - HeyWish

📱 DEVICE INFO
${deviceInfo['manufacturer']} ${deviceInfo['model']}
${deviceInfo['osVersion']}
${deviceInfo['deviceType']}

📦 APP INFO
${packageInfo.appName} v${packageInfo.version} (${packageInfo.buildNumber})
Platform: ${Platform.operatingSystem}

🔍 EVENT DETAILS
$eventDetails

🕒 TIMESTAMP
$timestamp''';

      // Send to backend
      print('🔄 Sending screenshot notification to $_baseUrl/telegram/send-message');
      final response = await _dio.post(
        '$_baseUrl/telegram/send-message',
        data: {
          'message': message,
          'channel': 'general',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Screenshot notification sent successfully');
      } else {
        print('❌ Failed to send screenshot notification: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending screenshot notification: $e');
    }
  }

  /// Send screenshot image to Telegram via backend
  Future<void> sendScreenshot(File screenshotFile) async {
    try {
      // Get device and app information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final timestamp = DateTime.now().toIso8601String();

      // Read file as base64
      final bytes = await screenshotFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Prepare caption
      final caption = '''📸 SCREENSHOT - HeyWish

📱 ${deviceInfo['manufacturer']} ${deviceInfo['model']}
${deviceInfo['osVersion']}

📦 ${packageInfo.appName} v${packageInfo.version}

🕒 $timestamp''';

      // Send to backend
      print('🔄 Sending screenshot image to $_baseUrl/telegram/send-image');
      final response = await _dio.post(
        '$_baseUrl/telegram/send-image',
        data: {
          'image': base64Image,
          'caption': caption,
          'channel': 'general',
          'filename': 'heywish_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
          'fallback': true,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Screenshot sent successfully');
      } else {
        print('❌ Failed to send screenshot: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending screenshot: $e');
    }
  }

  /// Send feedback to Telegram via backend
  Future<void> sendFeedback({
    required String message,
    String? contactInfo,
    required String clickSource,
  }) async {
    try {
      // Get device and app information
      final deviceInfo = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();
      final timestamp = DateTime.now().toIso8601String();

      // Prepare feedback message
      final feedbackMessage = '''💬 FEEDBACK - HeyWish

📝 MESSAGE
$message

${contactInfo != null && contactInfo.isNotEmpty ? '📧 CONTACT\n$contactInfo\n' : ''}
📱 DEVICE INFO
${deviceInfo['manufacturer']} ${deviceInfo['model']}
${deviceInfo['osVersion']}
${deviceInfo['deviceType']}

📦 APP INFO
${packageInfo.appName} v${packageInfo.version} (${packageInfo.buildNumber})
Platform: ${Platform.operatingSystem}

📍 SOURCE
$clickSource

🕒 TIMESTAMP
$timestamp''';

      // Send to backend
      print('🔄 Sending feedback to $_baseUrl/telegram/send-message');
      final response = await _dio.post(
        '$_baseUrl/telegram/send-message',
        data: {
          'message': feedbackMessage,
          'channel': 'general',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Feedback sent successfully');
      } else {
        print('❌ Failed to send feedback: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error sending feedback: $e');
      rethrow;
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'osVersion': 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
        'deviceType': androidInfo.isPhysicalDevice ? 'Physical Device' : 'Emulator',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'manufacturer': 'Apple',
        'model': iosInfo.utsname.machine,
        'osVersion': 'iOS ${iosInfo.systemVersion}',
        'deviceType': iosInfo.isPhysicalDevice ? 'Physical Device' : 'Simulator',
      };
    } else {
      return {
        'manufacturer': 'Unknown',
        'model': 'Unknown',
        'osVersion': Platform.operatingSystem,
        'deviceType': 'Unknown',
      };
    }
  }
}
