import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:io';
import 'wishlists/wishlists_screen.dart';
import 'feed_screen.dart';
import 'profile/profile_screen.dart';
import '../services/clipboard_service.dart';
import '../services/share_handler_service.dart';
import '../common/widgets/url_detected_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _hasCheckedClipboardOnLaunch = false;
  final ShareHandlerService _shareHandler = ShareHandlerService();
  StreamSubscription<SharedContent>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize share handler
    _shareHandler.initialize();

    // Listen for shared content
    _shareSubscription = _shareHandler.sharedContentStream.listen((content) {
      _handleSharedContent(content);
    });

    // Check clipboard on initial launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboardForUrl();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareSubscription?.cancel();
    _shareHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check clipboard when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForUrl();
    }
  }

  Future<void> _checkClipboardForUrl() async {
    if (!_hasCheckedClipboardOnLaunch) {
      _hasCheckedClipboardOnLaunch = true;
      // Small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final url = await ClipboardService.checkForUrl();

    if (url != null && mounted) {
      final shouldAdd = await UrlDetectedBottomSheet.show(
        context: context,
        url: url,
      );

      if (shouldAdd == true && mounted) {
        // Navigate to add wish screen with pre-filled URL
        context.push(
          '/add-wish',
          extra: {'initialUrl': url},
        );
      }
    }
  }

  Future<void> _handleSharedContent(SharedContent content) async {
    // Wait for UI to be ready
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    switch (content.type) {
      case SharedContentType.url:
        if (content.url != null) {
          // Navigate to add wish screen with pre-filled URL
          context.push(
            '/add-wish',
            extra: {'initialUrl': content.url},
          );
        }
        break;

      case SharedContentType.image:
        if (content.imagePath != null) {
          // Navigate to add wish screen with pre-filled image
          context.push(
            '/add-wish',
            extra: {'initialImagePath': content.imagePath},
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
      bottomNavigationBar: NavigationBar(
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
    );
  }
}