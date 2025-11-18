import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:screenshot/screenshot.dart';
import 'package:quick_actions/quick_actions.dart';
import 'dart:async';
import 'dart:io';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/wishlist_service.dart';
import 'services/offline_wishlist_service.dart';
import 'services/friends_service.dart';
import 'services/preferences_service.dart';
import 'services/sync_manager.dart';
import 'services/onboarding_service.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'services/screenshot_detection_service.dart';
import 'services/deep_link_service.dart';
import 'services/review_service.dart';
import 'services/analytics_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wishlists/wishlist_new_screen.dart';
import 'screens/wishlists/add_wish_screen.dart';
import 'screens/wishlists/wish_detail_screen.dart';
import 'screens/wishlists/edit_wishlist_screen.dart';
import 'screens/wishlists/edit_wish_screen.dart';
import 'screens/feedback/feedback_sheet_page.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/profile/public_profile_screen.dart';
import 'screens/profile/public_wishlist_detail_screen.dart';
import 'common/navigation/native_page_route.dart';

void main() async {
  // Wrap everything in runZonedGuarded to ensure all initialization
  // and app startup happens in the same zone
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set system UI overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Initialize localization
    await EasyLocalization.ensureInitialized();

    // Load environment variables (optional in development)
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file: $e');
    }

    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Crashlytics
    // Pass all uncaught "fatal" errors from the Flutter framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Initialize FCM background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize preferences
    await PreferencesService().initialize();

    // Initialize review service
    await ReviewService().initialize();

    // Initialize analytics service
    await AnalyticsService().initialize();

    // Initialize singleton services
    await SyncManager().initialize();

    // Initialize FCM service (will register token after auth)
    FCMService().initialize();

    // Run the app
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'), // English
          Locale('de'), // German
          Locale('es'), // Spanish
          Locale('fr'), // French
          Locale('pt', 'BR'), // Portuguese (Brazilian)
          Locale('pl'), // Polish
          Locale('it'), // Italian
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const JinnieApp(),
      ),
    );
  }, (error, stack) {
    // Catch errors that occur outside of Flutter's error handling
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class JinnieApp extends StatefulWidget {
  const JinnieApp({super.key});

  @override
  State<JinnieApp> createState() => _JinnieAppState();
}

class _JinnieAppState extends State<JinnieApp> with WidgetsBindingObserver {
  final ScreenshotController _screenshotController = ScreenshotController();
  final QuickActions _quickActions = const QuickActions();
  final DeepLinkService _deepLinkService = DeepLinkService();
  static const platform = MethodChannel('com.wishlists.gifts/share');
  StreamSubscription<RemoteMessage>? _fcmTapSubscription;

  // Store initial deep link that was intercepted by GoRouter redirect
  static String? _pendingDeepLink;

  // Track if DeepLinkService has initialized (to prevent double-handling)
  static bool _deepLinkServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer to handle app resume
    WidgetsBinding.instance.addObserver(this);

    // Initialize screenshot detection after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      ScreenshotDetectionService.instance.initialize(
        screenshotController: _screenshotController,
      );
    });

    // Initialize deep link service immediately to handle cold-start deep links
    debugPrint('🔗 Initializing DeepLinkService...');
    _deepLinkService.initialize(_router);
    _deepLinkServiceInitialized = true; // Mark as initialized
    debugPrint('🔗 DeepLinkService initialized');

    // Handle any pending deep link that was intercepted by GoRouter
    debugPrint('🔗 Checking for pending deep link...');
    debugPrint('🔗 _pendingDeepLink value: $_pendingDeepLink');

    if (_pendingDeepLink != null) {
      final link = _pendingDeepLink!;
      _pendingDeepLink = null; // Clear it
      debugPrint('🔗 ✅ Found pending deep link! Processing: $link');
      // Parse and handle the stored deep link
      try {
        final uri = Uri.parse(link);
        debugPrint('🔗 Parsed URI: $uri');
        debugPrint('🔗 Calling handleDeepLinkUri...');
        _deepLinkService.handleDeepLinkUri(uri);
        debugPrint('🔗 handleDeepLinkUri completed');
      } catch (e) {
        debugPrint('❌ Error parsing pending deep link: $e');
      }
    } else {
      debugPrint('🔗 ❌ No pending deep link found');
    }

    // Initialize quick actions (iOS and Android only)
    if (Platform.isIOS || Platform.isAndroid) {
      _initializeQuickActions();
    }

    // Initialize share extension handler (iOS only)
    if (Platform.isIOS) {
      _initializeShareHandler();
      // Check for shared content on startup
      _checkForSharedContent();
    }

    _fcmTapSubscription =
        FCMService().notificationTapStream.listen(_handleNotificationTap);
  }

  void _initializeShareHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'handleSharedContent') {
        debugPrint('📱 Received shared content: ${call.arguments}');
        _handleSharedContent(call.arguments);
      }
    });
  }

  Future<void> _checkForSharedContent() async {
    // Wait a bit for the app to fully initialize
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final result = await platform.invokeMethod('getSharedContent');
      if (result != null) {
        debugPrint('📱 Found shared content on startup: $result');
        _handleSharedContent(result);
      }
    } catch (e) {
      debugPrint('Error checking for shared content: $e');
    }
  }

  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    final type = data['type'] as String?;
    if (type == null) {
      return;
    }

    final rootContext = _router.routerDelegate.navigatorKey.currentContext;
    if (rootContext == null) {
      return;
    }

    final navigator = Navigator.of(rootContext);

    int tabIndexFor(String? tabKey) {
      switch (tabKey) {
        case 'requests':
          return 1;
        case 'sent':
          return 2;
        default:
          return 0;
      }
    }

    if (type == 'friend_request' || type == 'friend_accepted') {
      final tabKey = data['tab'] as String? ??
          (type == 'friend_request' ? 'requests' : 'friends');
      final tabIndex = tabIndexFor(tabKey);
      navigator.push(
        NativePageRoute(
          child: FriendsScreen(initialTabIndex: tabIndex),
        ),
      );
      return;
    }

    if (type == 'wish_reserved' || type == 'wish_purchased') {
      final wishId =
          data['wishId'] as String? ?? data['wish_id'] as String?;
      final wishlistIdRaw =
          data['wishlistId'] as String? ?? data['wishlist_id'] as String?;

      if (wishId == null) {
        debugPrint('FCM: Missing wishId for wish notification');
        return;
      }

      final wishlistId = (wishlistIdRaw == null ||
              wishlistIdRaw.isEmpty ||
              wishlistIdRaw == 'null')
          ? 'unsorted'
          : wishlistIdRaw;

      final wishlistService =
          Provider.of<WishlistService>(rootContext, listen: false);

      if (wishlistService.findWishById(wishId) == null) {
        await wishlistService.fetchWishlists();
      }

      if (!navigator.mounted) {
        return;
      }

      await WishDetailScreen.show(
        navigator.context,
        wishId: wishId,
        wishlistId: wishlistId,
      );
      return;
    }
  }

  void _handleSharedContent(dynamic arguments) {
    if (arguments is! Map) {
      debugPrint('⚠️ Invalid shared content format');
      return;
    }

    final sharedData = Map<String, dynamic>.from(arguments);
    final type = sharedData['type'] as String?;
    final value = sharedData['value'] as String?;

    if (type == null || value == null) {
      debugPrint('⚠️ Missing type or value in shared content');
      return;
    }

    // Ignore jinnie.app URLs - these should be handled by deep linking
    if (type == 'url') {
      try {
        final uri = Uri.parse(value);
        final host = uri.host.toLowerCase();
        if (host == 'jinnie.app' || host == 'www.jinnie.app') {
          debugPrint('🔗 Ignoring jinnie.app URL in iOS share handler (deep link): $value');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing shared URL: $e');
      }
    }

    debugPrint('✅ Processing shared $type: $value');

    // Navigate to add wish screen with the shared URL
    // Wait a moment to ensure home screen is loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;

      if (type == 'url') {
        Navigator.of(context).push(
          NativePageRoute(
            child: AddWishScreen(
              initialUrl: value,
            ),
          ),
        );
      } else if (type == 'image') {
        // Handle image sharing - use prefilledData for image path
        Navigator.of(context).push(
          NativePageRoute(
            child: AddWishScreen(
              prefilledData: {
                'image': value,
              },
            ),
          ),
        );
      } else if (type == 'text') {
        // Handle text sharing - use prefilledData for title
        Navigator.of(context).push(
          NativePageRoute(
            child: AddWishScreen(
              prefilledData: {
                'title': value,
              },
            ),
          ),
        );
      }
    });
  }

  void _initializeQuickActions() {
    _quickActions.initialize((shortcutType) {
      if (shortcutType == 'feedback') {
        _handleFeedbackAction();
      }
    });

    // Set quick action items with localized strings
    Future.delayed(const Duration(milliseconds: 500), () {
      _quickActions.setShortcutItems([
        ShortcutItem(
          type: 'feedback',
          localizedTitle: 'quick_actions.feedback'.tr(),
          localizedSubtitle: 'quick_actions.feedback_subtitle'.tr(),
          icon: 'ic_feedback',
        ),
      ]);
    });
  }

  void _handleFeedbackAction() {
    // Navigate to feedback screen
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        NativePageRoute(
          child: const FeedbackSheetPage(
            clickSource: 'quick_action',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmTapSubscription?.cancel();
    _deepLinkService.dispose();
    ScreenshotDetectionService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared ApiService for dependency injection
        Provider<ApiService>(create: (_) => ApiService()),
        
        // Services with dependency injection
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider<WishlistService>(
          create: (context) => WishlistService(
            apiService: context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider<OnboardingService>(
          create: (context) => OnboardingService(
            apiService: context.read<ApiService>(),
          ),
        ),
        
        // Singleton services (already initialized)
        ChangeNotifierProvider<OfflineWishlistService>(
          create: (_) {
            final service = OfflineWishlistService();
            service.initialize();
            return service;
          },
        ),
        ChangeNotifierProvider<FriendsService>(
          create: (context) => FriendsService(
            apiService: context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider.value(value: PreferencesService()),
        ChangeNotifierProvider.value(value: ReviewService()),
        ChangeNotifierProvider.value(value: SyncManager()),
      ],
      child: Screenshot(
        controller: _screenshotController,
        child: _AppLifecycleWrapper(
          child: MaterialApp.router(
            title: 'Jinnie',
            theme: AppTheme.lightTheme(),
            themeMode: ThemeMode.light,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Check if this is a deep link by examining state.uri
    // For cold-start deep links, state.matchedLocation is '/' but state.uri contains the full URL
    final uriString = state.uri.toString();
    final path = state.uri.path;
    final scheme = state.uri.scheme;

    debugPrint('🔍 GoRouter redirect called:');
    debugPrint('   - state.uri: $uriString');
    debugPrint('   - state.uri.scheme: $scheme');
    debugPrint('   - state.uri.path: $path');
    debugPrint('   - state.matchedLocation: ${state.matchedLocation}');
    debugPrint('   - DeepLinkService initialized: ${_JinnieAppState._deepLinkServiceInitialized}');

    // Handle iOS universal links and Android App Links (https://jinnie.app/...)
    if ((scheme == 'https' || scheme == 'http') &&
        (state.uri.host == 'jinnie.app' || state.uri.host == 'www.jinnie.app')) {
      debugPrint('🔗 ✅ Universal link detected: $uriString');

      // Parse the path to extract username
      final segments = state.uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final firstSegment = segments.first;
        if (firstSegment.startsWith('@')) {
          final username = firstSegment.substring(1);
          if (username.isNotEmpty) {
            // Handle /@username or /@username/follow
            if (segments.length == 1 || (segments.length == 2 && segments[1] == 'follow')) {
              debugPrint('🔗 Redirecting to profile: $username');
              return '/profile/$username';
            }
          }
        }
      }
      debugPrint('🔗 ⚠️ Could not parse universal link, continuing');
    }

    // Handle custom schemes (jinnie:// or com.wishlists.gifts://)
    if (scheme.isNotEmpty && scheme != 'http' && scheme != 'https') {
      // Only store pending deep links for cold start (before DeepLinkService initialized)
      // Warm-start deep links are handled by the stream listener
      if (!_JinnieAppState._deepLinkServiceInitialized) {
        debugPrint('🔗 ✅ Cold-start custom scheme deep link detected! Storing for later: $uriString');
        _JinnieAppState._pendingDeepLink = uriString;
        return '/';
      } else {
        debugPrint('🔗 🔄 Warm-start custom scheme deep link detected - already handled by stream, ignoring');
        return null; // Let the stream handler deal with it
      }
    }

    debugPrint('🔗 ❌ Not a deep link, continuing normally');
    return null; // No redirect needed
  },
  errorBuilder: (context, state) {
    // Handle unmatched routes (like deep link URLs that weren't caught by redirect)
    debugPrint('❌ Unmatched route: ${state.matchedLocation}');
    return const SplashScreen();
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => NativeTransitions.page(
        child: const SplashScreen(),
        key: state.pageKey,
        name: state.name,
        arguments: state.extra,
        restorationId: state.pageKey.value,
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => NativeTransitions.page(
        child: const OnboardingFlowScreen(),
        key: state.pageKey,
        name: state.name,
        arguments: state.extra,
        restorationId: state.pageKey.value,
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => NativeTransitions.page(
        child: const HomeScreen(),
        key: state.pageKey,
        name: state.name,
        arguments: state.extra,
        restorationId: state.pageKey.value,
      ),
    ),
    GoRoute(
      path: '/profile/:username',
      pageBuilder: (context, state) {
        final username = state.pathParameters['username']!;
        return NativeTransitions.page(
          child: PublicProfileScreen(username: username),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/profile/:username/wishlist/:wishlistId',
      pageBuilder: (context, state) {
        final username = state.pathParameters['username']!;
        final wishlistId = state.pathParameters['wishlistId']!;
        return NativeTransitions.page(
          child: PublicWishlistDetailScreen(
            username: username,
            wishlistId: wishlistId,
          ),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/new',
      pageBuilder: (context, state) => NativeTransitions.page(
        child: const WishlistNewScreen(),
        key: state.pageKey,
        name: state.name,
        arguments: state.extra,
        restorationId: state.pageKey.value,
      ),
    ),
    GoRoute(
      path: '/add-wish',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialUrl = extra?['initialUrl'] as String?;
        final prefilledData = extra?['prefilledData'] as Map<String, dynamic>?;
        return NativeTransitions.page(
          child: AddWishScreen(
            initialUrl: initialUrl,
            prefilledData: prefilledData,
          ),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/:id/add-item',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final extra = state.extra as Map<String, dynamic>?;
        final initialUrl = extra?['initialUrl'] as String?;
        return NativeTransitions.page(
          child: AddWishScreen(
            wishlistId: id,
            initialUrl: initialUrl,
          ),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/:wishlistId/items/:wishId',
      pageBuilder: (context, state) {
        final wishlistId = state.pathParameters['wishlistId']!;
        final wishId = state.pathParameters['wishId']!;
        return NativeTransitions.page(
          child: WishDetailScreen(
            wishlistId: wishlistId,
            wishId: wishId,
          ),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/:id/edit',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return NativeTransitions.page(
          child: EditWishlistScreen(wishlistId: id),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/:wishlistId/items/:wishId/edit',
      pageBuilder: (context, state) {
        final wishlistId = state.pathParameters['wishlistId']!;
        final wishId = state.pathParameters['wishId']!;
        return NativeTransitions.page(
          child: EditWishScreen(
            wishlistId: wishlistId,
            wishId: wishId,
          ),
          key: state.pageKey,
          name: state.name,
          arguments: state.extra,
          restorationId: state.pageKey.value,
        );
      },
    ),
  ],
);

/// Wrapper widget that handles app lifecycle and has access to Provider context
class _AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const _AppLifecycleWrapper({required this.child});

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  DateTime? _lastResumeRefreshTime;
  static const _resumeRefreshThreshold = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came to foreground - refresh friends data to update notification badge
      debugPrint('🔄 App resumed - refreshing friends data for notification badge');
      _refreshFriendsDataOnResume();
    }
  }

  Future<void> _refreshFriendsDataOnResume() async {
    try {
      // Check if enough time has passed since last resume refresh
      if (_lastResumeRefreshTime != null) {
        final timeSinceLastRefresh = DateTime.now().difference(_lastResumeRefreshTime!);
        if (timeSinceLastRefresh < _resumeRefreshThreshold) {
          debugPrint('⏭️  App resume: Skipping refresh, last refresh was ${timeSinceLastRefresh.inSeconds}s ago (threshold: ${_resumeRefreshThreshold.inSeconds}s)');
          return;
        }
        debugPrint('🔄 App resume: Refreshing (${timeSinceLastRefresh.inSeconds}s since last refresh)');
      } else {
        debugPrint('🔄 App resume: First refresh since app start');
      }

      // We need to use a delay to ensure the widget tree is built
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Check if user is authenticated with valid token before refreshing
      final authService = context.read<AuthService>();
      if (!authService.isAuthenticated || !authService.apiService.hasAuthToken) {
        debugPrint('⏭️  App resume: Skipping friends refresh, not authenticated or missing auth token');
        return;
      }

      // Now we have proper access to Provider context!
      final friendsService = context.read<FriendsService>();

      // Force refresh to bypass the 30-second cache and get latest data
      await friendsService.loadAllData(forceRefresh: true);

      _lastResumeRefreshTime = DateTime.now();
      debugPrint('✅ App resume: Friends data refreshed successfully');
    } catch (e) {
      debugPrint('❌ App resume: Error refreshing friends data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
