import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../common/navigation/native_page_route.dart';

/// Feed wish detail screen - displays wish details from feed items
class FeedWishDetailScreen extends StatelessWidget {
  final String wishTitle;
  final String? wishImage;
  final double? wishPrice;
  final String? wishCurrency;
  final String? wishUrl;
  final String? wishDescription;
  final String friendName;
  final String friendUsername;
  final String? friendAvatar;

  const FeedWishDetailScreen({
    super.key,
    required this.wishTitle,
    this.wishImage,
    this.wishPrice,
    this.wishCurrency,
    this.wishUrl,
    this.wishDescription,
    required this.friendName,
    required this.friendUsername,
    this.friendAvatar,
  });

  /// Show the wish detail screen as a modal bottom sheet
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
    await NativeTransitions.showNativeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      child: FeedWishDetailScreen(
        wishTitle: wishTitle,
        wishImage: wishImage,
        wishPrice: wishPrice,
        wishCurrency: wishCurrency,
        wishUrl: wishUrl,
        wishDescription: wishDescription,
        friendName: friendName,
        friendUsername: friendUsername,
        friendAvatar: friendAvatar,
      ),
    );
  }

  Future<void> _openUrl() async {
    if (wishUrl == null) return;

    final uri = Uri.parse(wishUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with handle bar and close button
            GestureDetector(
              onVerticalDragUpdate: (details) {
                // If dragging down, dismiss the sheet
                if (details.primaryDelta! > 0) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                color: Colors.transparent,
                child: Row(
                  children: [
                    // Handle bar
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if available
                    if (wishImage != null && wishImage!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            wishImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Friend info
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Friend avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                            backgroundImage: friendAvatar != null && friendAvatar!.isNotEmpty
                                ? NetworkImage(friendAvatar!)
                                : null,
                            child: friendAvatar == null || friendAvatar!.isEmpty
                                ? Text(
                                    friendName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Friend name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'On $friendName\'s wishlist',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '@$friendUsername',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Title
                    Text(
                      wishTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Price badge
                    if (wishPrice != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${wishCurrency ?? 'USD'} ${wishPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),

                    // Description
                    if (wishDescription != null && wishDescription!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        wishDescription!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],

                    // URL as a compact link
                    if (wishUrl != null && wishUrl!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _openUrl,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  wishUrl!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.primaryAccent,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
