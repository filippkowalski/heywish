import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  /// Initialize FCM (setup handlers, check existing permissions)
  Future<void> initialize() async {
    try {
      // Check if we already have permission (don't request here)
      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('FCM: Notifications already authorized');
        await _registerToken();
      } else {
        debugPrint('FCM: Notifications not authorized yet (will request during onboarding)');
      }

      // Setup message handlers regardless of permission status
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('FCM: Error initializing: $e');
    }
  }

  /// Get FCM token and register it with backend
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        debugPrint('FCM Token: $token');

        // Send token to backend
        await _sendTokenToBackend(token);

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_sendTokenToBackend);
      }
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final apiService = ApiService();

      // Check if we have an auth token before sending
      if (!apiService.hasAuthToken) {
        debugPrint('FCM: No auth token yet, will retry after login');
        // Store token locally to send later
        _currentToken = token;
        return;
      }

      await apiService.updateFCMToken(token);
      debugPrint('FCM: Token registered with backend');
    } catch (e) {
      debugPrint('FCM: Error sending token to backend: $e');
      // Store token to retry later
      _currentToken = token;
    }
  }

  /// Retry sending token after authentication
  Future<void> retryTokenRegistration() async {
    if (_currentToken != null) {
      debugPrint('FCM: Retrying token registration after auth');
      await _sendTokenToBackend(_currentToken!);
    }
  }

  /// Setup handlers for different message states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // TODO: Show in-app notification or update UI
      _handleMessage(message);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Message opened from background');
      _handleMessageTap(message);
    });

    // Handle notification tap when app is terminated
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM: Message opened from terminated state');
        _handleMessageTap(message);
      }
    });
  }

  /// Handle incoming message (foreground)
  void _handleMessage(RemoteMessage message) {
    // TODO: Show local notification or update UI based on message type
    final type = message.data['type'];

    switch (type) {
      case 'friend_request':
        // Could show a snackbar or update friends screen
        break;
      case 'friend_accepted':
        // Update friends list
        break;
      case 'wish_reserved':
      case 'wish_purchased':
        // Update wishlist
        break;
    }
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    // TODO: Navigate to appropriate screen based on message data
    final type = message.data['type'];
    final screen = message.data['screen'];

    debugPrint('FCM: Navigate to screen: $screen (type: $type)');

    // Navigation will be handled by the app's router
    // You can use a stream or callback to notify the app
  }

  /// Get current FCM token
  String? get currentToken => _currentToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
      return true;
    }
    return false;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
