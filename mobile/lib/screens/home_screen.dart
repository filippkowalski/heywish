import 'package:flutter/material.dart';
import 'dart:async';
import 'wishlists/wishlists_screen.dart';
import 'wishlists/add_wish_screen.dart';
import 'feed_screen.dart';
import 'profile/profile_screen.dart';
import '../services/share_handler_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ShareHandlerService _shareHandler = ShareHandlerService();
  StreamSubscription<SharedContent>? _shareSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize share handler
    _shareHandler.initialize();

    // Listen for shared content
    _shareSubscription = _shareHandler.sharedContentStream.listen((content) {
      _handleSharedContent(content);
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

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withOpacity(0.05),
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
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}