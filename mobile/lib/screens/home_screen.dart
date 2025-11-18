import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'wishlists/wishlists_screen.dart';
import 'wishlists/add_wish_screen.dart';
import 'feed_screen.dart';
import 'profile/profile_screen.dart';
import '../services/share_handler_service.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ShareHandlerService _shareHandler = ShareHandlerService();
  StreamSubscription<SharedContent>? _shareSubscription;
  bool _friendsDataLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize share handler
    _shareHandler.initialize();

    // Listen for shared content
    _shareSubscription = _shareHandler.sharedContentStream.listen((content) {
      _handleSharedContent(content);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      // Only load friends data if authenticated AND auth token is set
      if (authService.isAuthenticated && authService.apiService.hasAuthToken) {
        _friendsDataLoaded = true;
        context.read<FriendsService>().loadAllData();
      }
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _shareHandler.dispose();
    super.dispose();
  }

  Future<void> _handleSharedContent(SharedContent content) async {
    // Wait for UI to be ready
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    switch (content.type) {
      case SharedContentType.url:
        if (content.url != null) {
          // Show add wish bottom sheet with pre-filled URL
          await AddWishScreen.show(
            context,
            initialUrl: content.url,
          );
        }
        break;

      case SharedContentType.image:
        if (content.imagePath != null) {
          // Show add wish bottom sheet with pre-filled image
          await AddWishScreen.show(
            context,
            // Note: initialImagePath is not currently supported in AddWishScreen
            // This will need to be added to the AddWishScreen constructor
          );
        }
        break;

      case SharedContentType.text:
        // Handle plain text if needed
        break;
    }

    // Clear the shared content after handling
    _shareHandler.clearSharedContent();
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildProfileIcon({
    required bool selected,
    required int badgeCount,
  }) {
    final baseIcon = Icon(selected ? Icons.person : Icons.person_outline);

    if (badgeCount <= 0) {
      return baseIcon;
    }

    final displayText = badgeCount > 9 ? '9+' : badgeCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthService>().isAuthenticated;

    // Reset flag when user logs out
    if (!isAuthenticated && _friendsDataLoaded) {
      _friendsDataLoaded = false;
    }

    // Note: We don't call loadAllData() here anymore to prevent duplicate calls.
    // Data loading is handled by:
    // 1. initState() on initial mount (if authenticated)
    // 2. App lifecycle resume handler in main.dart
    // 3. Individual screens when needed with forceRefresh flag
    // The FriendsService cache prevents redundant API calls.

    final pendingRequestsCount =
        context.watch<FriendsService>().pendingRequestsCount;

    final screens = [
      const WishlistsScreen(),
      const FeedScreen(),
      ProfileScreen(onNavigateToSearch: () => _navigateToTab(1)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'navigation.home'.tr(),
            ),
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: 'navigation.feed'.tr(),
            ),
            NavigationDestination(
              icon: _buildProfileIcon(
                selected: false,
                badgeCount: pendingRequestsCount,
              ),
              selectedIcon: _buildProfileIcon(
                selected: true,
                badgeCount: pendingRequestsCount,
              ),
              label: 'navigation.profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
