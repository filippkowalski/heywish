import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/wish.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/utils/wish_category_detector.dart';
import '../../common/navigation/native_page_route.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import 'edit_wish_screen.dart';

class WishDetailScreen extends StatefulWidget {
  final String wishId;
  final String? wishlistId; // Nullable for unsorted wishes

  const WishDetailScreen({
    super.key,
    required this.wishId,
    this.wishlistId, // Optional for unsorted wishes
  });

  /// Show as bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String wishId,
    String? wishlistId, // Optional for unsorted wishes
  }) {
    return NativeTransitions.showNativeModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      child: WishDetailScreen(
        wishId: wishId,
        wishlistId: wishlistId,
      ),
    );
  }

  @override
  State<WishDetailScreen> createState() => _WishDetailScreenState();
}

class _WishDetailScreenState extends State<WishDetailScreen> {
  Wish? wish;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWish();
  }

  void _loadWish() async {
    final wishlistService = context.read<WishlistService>();
    wish = wishlistService.findWishById(widget.wishId);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    if (_isLoading) {
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (wish == null) {
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
          child: Center(
            child: Text('wish.item_not_found'.tr()),
          ),
        ),
      );
    }

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
                  // Menu button
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editWish();
                      } else if (value == 'delete') {
                        _deleteWish();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text('app.edit'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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
                  if (wish!.imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => _showFullscreenImage(context),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedImageWidget(
                            imageUrl: wish!.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                WishCategoryDetector.getIconFromTitle(wish!.title),
                                size: 64,
                                color: WishCategoryDetector.getColorFromTitle(wish!.title),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Title
                  Text(
                    wish!.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price and Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (wish!.price != null)
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
                            '${wish!.currency ?? 'USD'} ${wish!.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      if (wish!.isReserved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reserved',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Description
                  if (wish!.description != null && wish!.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      wish!.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],

                  // URL as a compact link
                  if (wish!.url != null) ...[
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
                                wish!.url!,
                                style: TextStyle(
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

                  // Additional details
                  if (wish!.brand != null || wish!.category != null) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (wish!.brand != null)
                          _buildDetailChip(Icons.local_offer_outlined, wish!.brand!),
                        if (wish!.category != null)
                          _buildDetailChip(Icons.category_outlined, wish!.category!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action buttons
          if (wish!.url != null)
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _openUrl,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View Product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl() async {
    if (wish?.url == null) return;

    try {
      final uri = Uri.parse(wish!.url!);

      // Check if the URL can be launched
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('wish.could_not_open_url'.tr())),
          );
        }
        return;
      }

      // Launch the URL in external browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wish.could_not_open_url'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wish.could_not_open_url'.tr())),
        );
      }
    }
  }

  void _editWish() async {
    // Close the detail bottom sheet first
    Navigator.of(context).pop();

    // Show edit screen as bottom sheet
    // Use wish's actual wishlistId (may be null for unsorted)
    final result = await EditWishScreen.show(
      context,
      wishId: widget.wishId,
      wishlistId: wish?.wishlistId,
    );

    // If edit was successful, the wishlist screen will refresh automatically
    if (result == true) {
      // Optional: could show a success message
    }
  }

  void _deleteWish() async {
    final shouldDelete = await ConfirmationBottomSheet.show(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete "${wish!.title}"?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
    );

    if (shouldDelete == true && mounted) {
      // Close the detail sheet immediately before starting deletion
      Navigator.of(context).pop(true);

      // Perform deletion (optimistic UI handles removal)
      final success = await context.read<WishlistService>().deleteWish(widget.wishId);

      if (!success && mounted) {
        // Show error if deletion failed (the wish will be restored by the service)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.failed_to_delete'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullscreenImage(BuildContext context) {
    if (wish?.imageUrl == null) return;

    Navigator.of(context).push(
      NativePageRoute(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Stack(
              children: [
                // Full screen image
                Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevents taps on image from closing
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: CachedImageWidget(
                        imageUrl: wish!.imageUrl,
                        fit: BoxFit.contain,
                        errorWidget: Container(
                          color: Colors.black,
                          child: Icon(
                            WishCategoryDetector.getIconFromTitle(wish!.title),
                            size: 64,
                            color: WishCategoryDetector.getColorFromTitle(wish!.title),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Close button
                SafeArea(
                  child: Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
