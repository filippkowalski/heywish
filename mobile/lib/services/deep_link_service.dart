import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service for handling deep links and universal links
///
/// Supports:
/// - Universal links: https://jinnie.co/@username/follow
/// - Custom scheme: jinnie://profile/username
///
/// Usage:
/// ```dart
/// final deepLinkService = DeepLinkService();
/// await deepLinkService.initialize(router);
/// ```
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;

  /// Initialize the deep link service
  ///
  /// Call this once in main.dart after GoRouter is created
  Future<void> initialize(GoRouter router) async {
    _router = router;

    // Handle initial link when app is opened from terminated state
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Deep link (initial): $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('❌ Error getting initial deep link: $e');
    }

    // Listen for links when app is in background or foreground
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 Deep link (stream): $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('❌ Error listening to deep links: $err');
      },
    );
  }

  /// Public method to handle a deep link URI (for external use)
  void handleDeepLinkUri(Uri uri) {
    _handleDeepLink(uri);
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Handling deep link: $uri');
    debugPrint('   Scheme: ${uri.scheme}');
    debugPrint('   Host: ${uri.host}');
    debugPrint('   Path: ${uri.path}');
    debugPrint('   Query: ${uri.queryParameters}');

    if (_router == null) {
      debugPrint('❌ Router not initialized, cannot handle deep link');
      return;
    }

    // Handle universal links: https://jinnie.co/@username/follow
    if (uri.scheme == 'https' && uri.host == 'jinnie.co') {
      _handleUniversalLink(uri);
      return;
    }

    // Handle custom scheme: jinnie://profile/username
    if (uri.scheme == 'jinnie' || uri.scheme == 'com.wishlists.gifts') {
      _handleCustomScheme(uri);
      return;
    }

    debugPrint('⚠️ Unhandled deep link scheme: ${uri.scheme}');
  }

  /// Handle universal links (https://jinnie.co/...)
  void _handleUniversalLink(Uri uri) {
    final path = uri.path;

    // Pattern: /@username/follow
    final followMatch = RegExp(r'^/@([^/]+)/follow$').firstMatch(path);
    if (followMatch != null) {
      final username = followMatch.group(1)!;
      debugPrint('✅ Deep link: Follow user @$username');
      _navigateToProfile(username, highlightFollow: true);
      return;
    }

    // Pattern: /@username (public profile)
    final profileMatch = RegExp(r'^/@([^/]+)$').firstMatch(path);
    if (profileMatch != null) {
      final username = profileMatch.group(1)!;
      debugPrint('✅ Deep link: View profile @$username');
      _navigateToProfile(username);
      return;
    }

    // Pattern: /username (fallback without @)
    final profileFallbackMatch = RegExp(r'^/([^/]+)$').firstMatch(path);
    if (profileFallbackMatch != null) {
      final username = profileFallbackMatch.group(1)!;
      // Skip special routes
      if (!['home', 'discover', 'profile', 'settings', 'onboarding'].contains(username)) {
        debugPrint('✅ Deep link: View profile $username (fallback)');
        _navigateToProfile(username);
        return;
      }
    }

    debugPrint('⚠️ Unhandled universal link path: $path');
  }

  /// Handle custom scheme links (jinnie://...)
  void _handleCustomScheme(Uri uri) {
    final path = uri.path.replaceFirst('/', '');

    // Pattern: jinnie://profile/username
    if (uri.host == 'profile' || path.startsWith('profile/')) {
      final username = uri.host == 'profile' ? path : path.replaceFirst('profile/', '');
      if (username.isNotEmpty) {
        debugPrint('✅ Deep link: View profile $username (custom scheme)');
        _navigateToProfile(username, highlightFollow: uri.queryParameters['action'] == 'follow');
        return;
      }
    }

    debugPrint('⚠️ Unhandled custom scheme path: ${uri.host}/$path');
  }

  /// Navigate to public profile screen
  void _navigateToProfile(String username, {bool highlightFollow = false}) {
    if (_router == null) {
      debugPrint('❌ Router not initialized');
      return;
    }

    // Navigate to public profile with optional follow highlight
    final route = '/profile/$username${highlightFollow ? '?highlight=follow' : ''}';
    debugPrint('📱 Navigating to: $route');

    // Use go() to navigate, which will replace current route if already on a profile
    _router!.go(route);
  }

  /// Dispose and clean up subscriptions
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
