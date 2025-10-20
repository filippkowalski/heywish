import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenshot_detect/flutter_screenshot_detect.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:heywish/services/telegram_service.dart';

class ScreenshotDetectionService {
  static final ScreenshotDetectionService _instance = ScreenshotDetectionService._internal();
  static ScreenshotDetectionService get instance => _instance;
  ScreenshotDetectionService._internal();

  final FlutterScreenshotDetect _detector = FlutterScreenshotDetect();
  bool _isListening = false;
  ScreenshotController? _screenshotController;
  DateTime? _lastScreenshotTime;

  /// Initialize screenshot detection
  Future<void> initialize({ScreenshotController? screenshotController}) async {
    if (_isListening) {
      print('⚠️ Screenshot detection already initialized');
      return;
    }

    _screenshotController = screenshotController;

    try {
      print('🔄 Initializing screenshot detection...');
      _detector.startListening((event) async {
        print('📸 SCREENSHOT DETECTED: ${event.toString()}');
        await _handleScreenshot(event);
      });

      _isListening = true;
      print('✅ Screenshot detection initialized successfully');
      print('📷 Screenshot controller: ${_screenshotController != null ? "attached" : "not attached"}');
    } catch (e) {
      print('❌ Failed to initialize screenshot detection: $e');
    }
  }

  /// Handle detected screenshot
  Future<void> _handleScreenshot(dynamic event) async {
    try {
      final now = DateTime.now();

      // Debounce: ignore if screenshot was taken less than 2 seconds ago
      if (_lastScreenshotTime != null &&
          now.difference(_lastScreenshotTime!).inSeconds < 2) {
        print('⏭️ Screenshot ignored - too soon after previous screenshot');
        return;
      }

      _lastScreenshotTime = now;
      print('🔄 Processing screenshot event: $event');

      // Try to capture the current app screen using the screenshot controller
      if (_screenshotController != null) {
        print('📷 Capturing screenshot with controller...');
        final Uint8List? imageBytes = await _screenshotController!.capture(
          pixelRatio: 2.0,
        );

        if (imageBytes != null) {
          print('✅ Screenshot captured: ${imageBytes.length} bytes');
          // Save screenshot to temporary file
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/heywish_screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(imageBytes);
          print('💾 Screenshot saved to: ${file.path}');

          // Send the actual screenshot file to Telegram via backend
          print('📤 Sending screenshot to Telegram...');
          await TelegramService.instance.sendScreenshot(file);

          // Clean up the temporary file
          await file.delete();
          print('🗑️ Temporary file cleaned up');
          return;
        } else {
          print('⚠️ Screenshot capture returned null');
        }
      } else {
        print('⚠️ Screenshot controller is null');
      }

      // Fallback: send notification if screenshot capture fails
      print('📨 Sending fallback notification...');
      await TelegramService.instance.sendScreenshotNotification('Screenshot detected: ${event.toString()}');
    } catch (e) {
      print('❌ Error handling screenshot: $e');
      // Fallback: send notification on any error
      try {
        await TelegramService.instance.sendScreenshotNotification('Screenshot detected but could not capture: ${e.toString()}');
      } catch (fallbackError) {
        print('❌ Error sending fallback notification: $fallbackError');
      }
    }
  }

  /// Stop screenshot detection
  void dispose() {
    _detector.dispose();
    _isListening = false;
    print('Screenshot detection stopped');
  }

  /// Check if screenshot detection is active
  bool get isListening => _isListening;
}
