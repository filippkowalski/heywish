import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/wishlists/wishlists_screen.dart';
import 'screens/wishlists/wishlist_detail_screen.dart';
import 'screens/public_wishlist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HeyWishApp());
}

class HeyWishApp extends StatelessWidget {
  const HeyWishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeyWish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF8B5CF6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const AppWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/wishlists': (context) => const WishlistsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/wishlist/')) {
          final wishlistId = settings.name!.substring('/wishlist/'.length);
          return MaterialPageRoute(
            builder: (context) => WishlistDetailScreen(wishlistId: wishlistId),
          );
        } else if (settings.name != null && settings.name!.startsWith('/w/')) {
          // Public wishlist deep link
          final shareToken = settings.name!.substring('/w/'.length);
          return MaterialPageRoute(
            builder: (context) => PublicWishlistScreen(shareToken: shareToken),
          );
        }
        return null;
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late final AuthService _authService;
  late final ApiService _apiService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _apiService = ApiService(_authService);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _authService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const HomeScreen();
        } else if (user.isAnonymous) {
          return HomeScreen(authService: _authService, apiService: _apiService);
        } else {
          return DashboardScreen(authService: _authService, apiService: _apiService);
        }
      },
    );
  }
}