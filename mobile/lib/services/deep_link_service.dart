import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

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
  final ApiService _apiService = ApiService();

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
    debugPrint('🔗 [PUBLIC] handleDeepLinkUri called with: $uri');
    _handleDeepLink(uri);
    debugPrint('🔗 [PUBLIC] handleDeepLinkUri finished');
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
    if (uri.scheme == 'https' &&
        (uri.host == 'jinnie.co' || uri.host == 'www.jinnie.co')) {
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
    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    if (segments.isEmpty) {
      debugPrint('🌐 Universal link points to root, opening externally: $uri');
      _openExternally(uri);
      return;
    }

    final firstSegment = segments.first;
    final hasAtSymbol = firstSegment.startsWith('@');
    final username = hasAtSymbol ? firstSegment.substring(1) : firstSegment;

    if (username.isEmpty) {
      debugPrint(
        '⚠️ Universal link missing username, opening externally: $uri',
      );
      _openExternally(uri);
      return;
    }

    final queryWishlistSlug = uri.queryParameters['w'];
    final isReservedRoot = _isReservedTopLevelPath(username);

    if (hasAtSymbol) {
      if (segments.length == 1) {
        if (queryWishlistSlug != null && queryWishlistSlug.isNotEmpty) {
          _handleWishlistSlugNavigation(
            username,
            queryWishlistSlug,
            originalUri: uri,
          );
          return;
        }

        debugPrint('✅ Deep link: View profile @$username');
        _navigateToProfile(username);
        return;
      }

      final secondSegment = segments.length > 1 ? segments[1] : null;

      if (secondSegment == 'follow') {
        debugPrint('✅ Deep link: Follow user @$username');
        _navigateToProfile(username, highlightFollow: true);
        return;
      }

      if (secondSegment != null && secondSegment.isNotEmpty) {
        debugPrint(
          '✅ Deep link: Wishlist slug for @$username → $secondSegment',
        );
        _handleWishlistSlugNavigation(
          username,
          secondSegment,
          originalUri: uri,
        );
        return;
      }
    } else {
      if (segments.length == 1) {
        if (isReservedRoot) {
          debugPrint(
            '🌐 Reserved root path detected for $username, opening externally: $uri',
          );
          _openExternally(uri);
          return;
        }

        if (queryWishlistSlug != null && queryWishlistSlug.isNotEmpty) {
          debugPrint(
            '✅ Deep link: Wishlist slug via query for $username → $queryWishlistSlug',
          );
          _handleWishlistSlugNavigation(
            username,
            queryWishlistSlug,
            originalUri: uri,
          );
          return;
        }

        debugPrint('✅ Deep link: View profile $username (fallback)');
        _navigateToProfile(username);
        return;
      }

      if (segments.length >= 2) {
        final slug = segments[1];
        if (slug.isNotEmpty) {
          debugPrint('✅ Deep link: Wishlist slug for $username → $slug');
          _handleWishlistSlugNavigation(username, slug, originalUri: uri);
          return;
        }
      }
    }

    debugPrint('⚠️ Unhandled universal link path: $path - opening externally');
    _openExternally(uri);
  }

  /// Handle custom scheme links (jinnie://... or com.wishlists.gifts://...)
  void _handleCustomScheme(Uri uri) {
    debugPrint('🔗 _handleCustomScheme called');
    debugPrint('   - uri.host: ${uri.host}');
    debugPrint('   - uri.path: ${uri.path}');
    debugPrint('   - uri.queryParameters: ${uri.queryParameters}');

    final path = uri.path.replaceFirst('/', '');
    debugPrint('   - path (after removing /): $path');

    // Pattern: jinnie://profile/username or com.wishlists.gifts://profile/username
    if (uri.host == 'profile' || path.startsWith('profile/')) {
      debugPrint('🔗 Detected profile pattern');
      final username =
          uri.host == 'profile' ? path : path.replaceFirst('profile/', '');
      debugPrint('🔗 Extracted username: $username');
      debugPrint('🔗 action query param: ${uri.queryParameters['action']}');

      if (username.isNotEmpty) {
        final highlightFollow = uri.queryParameters['action'] == 'follow';
        debugPrint(
          '✅ Deep link: View profile $username (custom scheme, highlightFollow: $highlightFollow)',
        );
        _navigateToProfile(username, highlightFollow: highlightFollow);
        return;
      } else {
        debugPrint('⚠️ Username is empty!');
      }
    }

    debugPrint('⚠️ Unhandled custom scheme path: ${uri.host}/$path');
  }

  /// Navigate to public profile screen
  void _navigateToProfile(String username, {bool highlightFollow = false}) {
    debugPrint('🔗 _navigateToProfile called');
    debugPrint('   - username: $username');
    debugPrint('   - highlightFollow: $highlightFollow');
    debugPrint('   - _router is null: ${_router == null}');

    if (_router == null) {
      debugPrint('❌ Router not initialized');
      return;
    }

    // Navigate to public profile with optional follow highlight
    final route =
        '/profile/$username${highlightFollow ? '?highlight=follow' : ''}';
    debugPrint('📱 Navigating to route: $route');

    try {
      // Build a proper navigation stack: home -> profile
      // This allows users to navigate back to home
      debugPrint('📱 Building navigation stack: home -> profile');
      _router!.go('/home');

      // Wait a frame for home to render, then push profile on top
      Future.delayed(const Duration(milliseconds: 100), () {
        debugPrint('📱 Pushing profile on top of home');
        _router!.push(route);
      });

      debugPrint('📱 ✅ Navigation initiated');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
    }
  }

  /// Navigate directly to a public wishlist detail screen
  void _navigateToWishlist(String username, String wishlistId) {
    debugPrint('🔗 _navigateToWishlist called');
    debugPrint('   - username: $username');
    debugPrint('   - wishlistId: $wishlistId');

    if (_router == null) {
      debugPrint('❌ Router not initialized');
      return;
    }

    try {
      // Navigate to profile first to ensure proper back stack
      _navigateToProfile(username);

      final detailRoute = '/profile/$username/wishlist/$wishlistId';
      debugPrint('📱 Scheduling navigation to wishlist detail: $detailRoute');

      Future.delayed(const Duration(milliseconds: 250), () {
        try {
          _router!.push(detailRoute);
          debugPrint('📱 ✅ Wishlist detail navigation initiated');
        } catch (e) {
          debugPrint('❌ Wishlist detail navigation error: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ Error during wishlist navigation: $e');
    }
  }

  /// Handle wishlist slug by resolving to an ID before navigation
  void _handleWishlistSlugNavigation(
    String username,
    String slug, {
    required Uri originalUri,
  }) {
    if (username.isEmpty || slug.isEmpty) {
      debugPrint(
        '⚠️ Invalid wishlist navigation parameters. Opening externally.',
      );
      _openExternally(originalUri);
      return;
    }

    debugPrint('🔎 Resolving wishlist slug "$slug" for user "$username"');

    unawaited(() async {
      try {
        final response = await _apiService.get('/public/users/$username');
        if (response is! Map<String, dynamic>) {
          debugPrint('⚠️ Unexpected API response type for wishlist slug');
          _navigateToProfile(username);
          return;
        }

        final wishlists = response['wishlists'];
        if (wishlists is! List) {
          debugPrint('⚠️ No wishlists found in response for $username');
          _navigateToProfile(username);
          return;
        }

        Map<String, dynamic>? matchedWishlist;
        for (final item in wishlists) {
          if (item is Map<String, dynamic> &&
              _matchesWishlistSlug(item, slug)) {
            matchedWishlist = item;
            break;
          }
        }

        if (matchedWishlist == null) {
          debugPrint('⚠️ No matching wishlist slug found for $slug');
          _navigateToProfile(username);
          return;
        }

        final wishlistId = _stringValue(matchedWishlist['id']);
        if (wishlistId == null || wishlistId.isEmpty) {
          debugPrint('⚠️ Matched wishlist missing ID, opening profile instead');
          _navigateToProfile(username);
          return;
        }

        _navigateToWishlist(username, wishlistId);
      } catch (error) {
        debugPrint('❌ Error resolving wishlist slug: $error');
        _openExternally(originalUri);
      }
    }());
  }

  /// Decide whether to open a URL in the system browser
  void _openExternally(Uri uri) {
    unawaited(() async {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          debugPrint('❌ Failed to launch $uri externally');
        }
      } catch (e) {
        debugPrint('❌ Exception while launching $uri externally: $e');
      }
    }());
  }

  bool _matchesWishlistSlug(Map<String, dynamic> data, String slugParam) {
    final normalizedParam = slugParam.toLowerCase();

    final slug = _stringValue(data['slug']);
    if (slug != null && slug.toLowerCase() == normalizedParam) {
      return true;
    }

    final name = _stringValue(data['name']);
    if (name != null && _slugify(name) == normalizedParam) {
      return true;
    }

    final shareToken = _stringValue(data['shareToken'] ?? data['share_token']);
    if (shareToken != null && shareToken.toLowerCase() == normalizedParam) {
      return true;
    }

    final id = _stringValue(data['id']);
    if (id != null && id.toLowerCase() == normalizedParam) {
      return true;
    }

    return false;
  }

  String _slugify(String value) {
    final lower = value.toLowerCase();
    final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = sanitized.replaceAll(RegExp(r'-{2,}'), '-');
    return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  bool _isReservedTopLevelPath(String segment) {
    const reserved = {
      'home',
      'discover',
      'profile',
      'settings',
      'onboarding',
      'privacy',
      'terms',
      'dashboard',
      'api',
      'docs',
      'documentation',
      'verify-reservation',
      'delete-account',
      'w',
      'affiliate-disclosure',
    };
    return reserved.contains(segment.toLowerCase());
  }

  /// Dispose and clean up subscriptions
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
