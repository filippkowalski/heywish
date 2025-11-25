import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'friends_service.dart';
import 'wishlist_service.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;
  String? _lastSentToken; // Track last token sent to prevent duplicates
  StreamSubscription<String>? _tokenRefreshSubscription; // Track subscription to avoid multiple listeners
  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _foregroundNotificationController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get notificationTapStream =>
      _notificationTapController.stream;

  Stream<RemoteMessage> get foregroundNotificationStream =>
      _foregroundNotificationController.stream;

  /// Initialize FCM (setup handlers only, don't request permissions)
  Future<void> initialize() async {
    try {
      debugPrint('FCM: Initializing (not requesting permissions yet)');

      // Setup message handlers regardless of permission status
      // This allows us to handle messages if permission is granted later
      _setupMessageHandlers();

      // DON'T check or register token on initialization
      // This prevents any accidental permission prompts on iOS
      // Token registration will happen explicitly after permission is granted
      debugPrint('FCM: Initialization complete (waiting for permission grant)');
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

        // Only subscribe ONCE to token refresh to avoid duplicate listeners
        if (_tokenRefreshSubscription == null) {
          _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(_sendTokenToBackend);
          debugPrint('FCM: Subscribed to token refresh');
        }
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

      // Check if this token was already sent to avoid duplicates
      if (_lastSentToken == token) {
        debugPrint('FCM: Token unchanged, skipping duplicate registration');
        return;
      }

      await apiService.updateFCMToken(token);
      _lastSentToken = token; // Remember the last sent token
      debugPrint('FCM: Token registered with backend');
    } catch (e) {
      debugPrint('FCM: Error sending token to backend: $e');
      // Store token to retry later
      _currentToken = token;
    }
  }

  /// Retry sending token after authentication
  Future<void> retryTokenRegistration() async {
    if (_currentToken != null && _lastSentToken != _currentToken) {
      debugPrint('FCM: Retrying token registration after auth');
      await _sendTokenToBackend(_currentToken!);
    } else if (_lastSentToken == _currentToken) {
      debugPrint('FCM: Token already registered, skipping retry');
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
    // Emit message to stream for UI to display banner
    _foregroundNotificationController.add(message);

    // Trigger data refresh based on notification type
    final type = message.data['type'];

    switch (type) {
      case 'friend_request':
      case 'friend_accepted':
        // Refresh friends data
        FriendsService().loadAllData(forceRefresh: true);
        break;
      case 'wish_reserved':
      case 'wish_purchased':
        // Refresh wishlist data
        WishlistService().fetchWishlists();
        break;
    }
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'];
    final screen = message.data['screen'];

    debugPrint('FCM: Navigate to screen: $screen (type: $type)');

    // Emit to stream for navigation handling in main.dart
    _notificationTapController.add(message);
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
