import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/wishlist_service.dart';
import 'services/preferences_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/wishlists/wishlist_detail_screen.dart';
import 'screens/wishlists/wishlist_new_screen.dart';
import 'screens/wishlists/add_wish_screen.dart';
import 'screens/wishlists/wish_detail_screen.dart';
import 'screens/wishlists/edit_wishlist_screen.dart';
import 'screens/wishlists/edit_wish_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional in development)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize preferences
  await PreferencesService().initialize();
  
  runApp(const HeyWishApp());
}

class HeyWishApp extends StatelessWidget {
  const HeyWishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => WishlistService()),
        ChangeNotifierProvider.value(value: PreferencesService()),
      ],
      child: MaterialApp.router(
        title: 'HeyWish',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/wishlists/new',
      builder: (context, state) => const WishlistNewScreen(),
    ),
    GoRoute(
      path: '/wishlists/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WishlistDetailScreen(wishlistId: id);
      },
    ),
    GoRoute(
      path: '/wishlists/:id/add-item',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddWishScreen(wishlistId: id);
      },
    ),
    GoRoute(
      path: '/wishlists/:wishlistId/items/:wishId',
      builder: (context, state) {
        final wishlistId = state.pathParameters['wishlistId']!;
        final wishId = state.pathParameters['wishId']!;
        return WishDetailScreen(
          wishlistId: wishlistId,
          wishId: wishId,
        );
      },
    ),
    GoRoute(
      path: '/wishlists/:id/edit',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return EditWishlistScreen(wishlistId: id);
      },
    ),
    GoRoute(
      path: '/wishlists/:wishlistId/items/:wishId/edit',
      builder: (context, state) {
        final wishlistId = state.pathParameters['wishlistId']!;
        final wishId = state.pathParameters['wishId']!;
        return EditWishScreen(
          wishlistId: wishlistId,
          wishId: wishId,
        );
      },
    ),
  ],
);