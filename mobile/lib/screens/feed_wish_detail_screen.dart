import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder screen - work in progress
/// This file exists to prevent import errors in feed_screen.dart
class FeedWishDetailScreen extends StatelessWidget {
  final String wishId;

  const FeedWishDetailScreen({super.key, required this.wishId});

  /// Show the wish detail screen
  static Future<void> show(
    BuildContext context, {
    required String wishTitle,
    String? wishImage,
    double? wishPrice,
    String? wishCurrency,
    String? wishUrl,
    String? wishDescription,
    required String friendName,
    required String friendUsername,
    String? friendAvatar,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedWishDetailScreen(wishId: wishTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Wish Detail', style: TextStyle(color: Colors.black)),
        ),
        body: const Center(
          child: Text('Feed Wish Detail - Coming Soon'),
        ),
      ),
    );
  }
}
