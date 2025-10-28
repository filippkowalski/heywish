import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';
import 'screens/home_screen.dart';
import 'screens/wishlists/wishlist_new_screen.dart';
import 'screens/wishlists/add_wish_screen.dart';
import 'screens/wishlists/wish_detail_screen.dart';
import 'screens/wishlists/edit_wishlist_screen.dart';
import 'screens/wishlists/edit_wish_screen.dart';
import 'screens/feedback/feedback_sheet_page.dart';
import 'screens/profile/public_profile_screen.dart';
import 'screens/profile/public_wishlist_detail_screen.dart';
import 'common/navigation/native_page_route.dart';

void main() async {
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

  // Initialize FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize preferences
  await PreferencesService().initialize();

  // Initialize singleton services
  await SyncManager().initialize();

  // Initialize FCM service (will register token after auth)
  FCMService().initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('de'), // German
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('pt', 'BR'), // Portuguese (Brazilian)
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const JinnieApp(),
    ),
  );
}

class JinnieApp extends StatefulWidget {
  const JinnieApp({super.key});

  @override
  State<JinnieApp> createState() => _JinnieAppState();
}

class _JinnieAppState extends State<JinnieApp> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final QuickActions _quickActions = const QuickActions();
  static const platform = MethodChannel('com.wishlists.gifts/share');

  @override
  void initState() {
    super.initState();
    // Initialize screenshot detection after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      ScreenshotDetectionService.instance.initialize(
        screenshotController: _screenshotController,
      );
    });

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

    debugPrint('✅ Processing shared $type: $value');

    // Navigate to add wish screen with the shared URL
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      // Wait a moment to ensure home screen is loaded
      Future.delayed(const Duration(milliseconds: 500), () {
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
        ChangeNotifierProvider.value(value: FriendsService()),
        ChangeNotifierProvider.value(value: PreferencesService()),
        ChangeNotifierProvider.value(value: SyncManager()),
      ],
      child: Screenshot(
        controller: _screenshotController,
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
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
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
