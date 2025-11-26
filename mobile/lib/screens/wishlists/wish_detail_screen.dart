import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/wish.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/utils/wish_category_detector.dart';
import '../../common/navigation/native_page_route.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import 'edit_wish_screen.dart';
import 'add_wish_screen.dart';

class WishDetailScreen extends StatefulWidget {
  // Original mode: Load from WishlistService
  final String? wishId;
  final String? wishlistId;

  // Feed/Read-only mode: Direct wish data
  final String? directWishTitle;
  final List<String>? directWishImages;
  final double? directWishPrice;
  final String? directWishCurrency;
  final String? directWishUrl;
  final String? directWishDescription;
  final bool? directWishIsReserved;

  // Friend info for feed context
  final String? friendName;
  final String? friendUsername;
  final String? friendAvatar;

  // Control flags
  final bool isReadOnly;

  const WishDetailScreen({
    super.key,
    this.wishId,
    this.wishlistId,
    this.directWishTitle,
    this.directWishImages,
    this.directWishPrice,
    this.directWishCurrency,
    this.directWishUrl,
    this.directWishDescription,
    this.directWishIsReserved,
    this.friendName,
    this.friendUsername,
    this.friendAvatar,
    this.isReadOnly = false,
  });

  /// Show as bottom sheet - Original mode (load from service)
  static Future<bool?> show(
    BuildContext context, {
    required String wishId,
    String? wishlistId,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      child: WishDetailScreen(
        wishId: wishId,
        wishlistId: wishlistId,
        isReadOnly: false,
      ),
    );
  }

  /// Show as bottom sheet - Feed mode (direct data, read-only)
  static Future<void> showFeed(
    BuildContext context, {
    required String wishTitle,
    List<String>? wishImages,
    double? wishPrice,
    String? wishCurrency,
    String? wishUrl,
    String? wishDescription,
    bool? wishIsReserved,
    required String friendName,
    required String friendUsername,
    String? friendAvatar,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      child: WishDetailScreen(
        directWishTitle: wishTitle,
        directWishImages: wishImages,
        directWishPrice: wishPrice,
        directWishCurrency: wishCurrency,
        directWishUrl: wishUrl,
        directWishDescription: wishDescription,
        directWishIsReserved: wishIsReserved,
        friendName: friendName,
        friendUsername: friendUsername,
        friendAvatar: friendAvatar,
        isReadOnly: true,
      ),
    );
  }

  /// Show as bottom sheet - Gift Guide mode (direct data, read-only, for gift guide items)
  static Future<void> showGiftGuideItem(
    BuildContext context, {
    required String title,
    String? image,
    double? price,
    String? currency,
    required String url,
    String? description,
  }) {
    return NativeTransitions.showNativeModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      child: WishDetailScreen(
        directWishTitle: title,
        directWishImages: image != null ? [image] : null,
        directWishPrice: price,
        directWishCurrency: currency ?? 'USD',
        directWishUrl: url,
        directWishDescription: description,
        directWishIsReserved: false,
        isReadOnly: true,
      ),
    );
  }

  @override
  State<WishDetailScreen> createState() => _WishDetailScreenState();
}

class _WishDetailScreenState extends State<WishDetailScreen> {
  Wish? wish;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _loadWish();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _loadWish() async {
    // If using direct data (feed mode), create Wish object from parameters
    if (widget.directWishTitle != null) {
      wish = Wish(
        id: 'feed-wish', // Placeholder ID for feed wishes
        title: widget.directWishTitle!,
        images: widget.directWishImages ?? [],
        price: widget.directWishPrice,
        currency: widget.directWishCurrency ?? 'USD',
        url: widget.directWishUrl,
        description: widget.directWishDescription,
        status: widget.directWishIsReserved == true ? 'reserved' : 'available',
        wishlistId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Otherwise, load from WishlistService (original mode)
    if (widget.wishId != null) {
      final wishlistService = context.read<WishlistService>();
      wish = wishlistService.findWishById(widget.wishId!);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  /// Format price with currency symbol
  String _formatPrice(double price, String currency) {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    if (_isLoading) {
      return Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
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
          width: double.infinity,
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
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Full-width image with overlayed elements
            if (wish!.images.isNotEmpty)
              Stack(
                children: [
                // Image gallery
                GestureDetector(
                  onTap: () => _showFullscreenImage(context),
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: PageView.builder(
                        controller: _imagePageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: wish!.images.length,
                        itemBuilder: (context, index) {
                          return CachedImageWidget(
                            imageUrl: wish!.images[index],
                            fit: BoxFit.contain,
                            errorWidget: Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                WishCategoryDetector.getIconFromTitle(wish!.title),
                                size: 64,
                                color: WishCategoryDetector.getColorFromTitle(wish!.title),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Price and status badges overlay (bottom-left)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Row(
                    children: [
                      if (wish!.price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _formatPrice(wish!.price!, wish!.currency ?? 'USD'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      if (wish!.price != null && wish!.isReserved)
                        const SizedBox(width: 8),
                      if (wish!.isReserved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bookmark,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'wish.reserved'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Image indicators (if multiple images)
                if (wish!.images.length > 1)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: wish!.images.length <= 5
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                wish!.images.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              '${_currentImageIndex + 1} / ${wish!.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

            // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Ensure minimum height when no images (space for buttons)
                  minHeight: wish!.images.isEmpty ? 140 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add top spacing
                    if (wish!.images.isNotEmpty)
                      const SizedBox(height: 16)
                    else
                      const SizedBox(height: 80), // Extra space for close/menu buttons when no image

                  // Product link card preview - moved to top (most important)
                  if (wish!.url != null) ...[
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openUrl();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Favicon container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: CachedNetworkImage(
                                  imageUrl: 'https://www.google.com/s2/favicons?domain=${Uri.parse(wish!.url!).host}&sz=64',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  errorWidget: (context, url, error) {
                                    // Fallback to globe icon if favicon fails
                                    return Icon(
                                      Icons.language,
                                      size: 24,
                                      color: AppTheme.primaryAccent,
                                    );
                                  },
                                  placeholder: (context, url) {
                                    return Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryAccent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Domain name
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _getDomainName(wish!.url!),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Product title
                                  Text(
                                    wish!.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Short URL
                                  Text(
                                    _getShortUrl(wish!.url!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Title
                  Text(
                    wish!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                      height: 1.2,
                    ),
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

                  // Friend info for feed mode - moved to bottom
                  if (widget.isReadOnly && widget.friendName != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Friend avatar
                          CachedAvatarImage(
                            imageUrl: widget.friendAvatar,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          // Friend name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'On ${widget.friendName}\'s wishlist',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '@${widget.friendUsername}',
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
          ),

          // "Add to My Wishlist" button - only show in read-only mode
          if (widget.isReadOnly)
            Container(
              padding: EdgeInsets.fromLTRB(
                24.0,
                12.0,
                24.0,
                MediaQuery.of(context).padding.bottom + 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _addToMyWishlist,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'Add to My Wishlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
              ],
            ),

            // Close button - top left corner
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            // Menu button - top right corner (only show if not read-only)
            if (!widget.isReadOnly)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editWish();
                      } else if (value == 'share') {
                        _shareWish();
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
                        value: 'share',
                        child: Row(
                          children: [
                            const Icon(Icons.share_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text('app.share'.tr()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text('app.delete'.tr(), style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
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

  /// Extract domain name from URL for display
  String _getDomainName(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;

      // Remove www. prefix
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      // Capitalize first letter
      if (domain.isNotEmpty) {
        domain = domain[0].toUpperCase() + domain.substring(1);
      }

      return domain;
    } catch (e) {
      return 'Website';
    }
  }

  /// Get a short display version of the URL
  String _getShortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String shortUrl = uri.host + uri.path;

      // Truncate if too long
      if (shortUrl.length > 50) {
        shortUrl = '${shortUrl.substring(0, 47)}...';
      }

      return shortUrl;
    } catch (e) {
      return url.length > 50 ? '${url.substring(0, 47)}...' : url;
    }
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
    // Guard against read-only mode
    if (widget.isReadOnly || widget.wishId == null) return;

    // Close the detail bottom sheet first
    Navigator.of(context).pop();

    // Show edit screen as bottom sheet
    // Use wish's actual wishlistId (may be null for unsorted)
    final result = await EditWishScreen.show(
      context,
      wishId: widget.wishId!,
      wishlistId: wish?.wishlistId,
    );

    // If edit was successful, the wishlist screen will refresh automatically
    if (result == true) {
      // Optional: could show a success message
    }
  }

  void _deleteWish() async {
    // Guard against read-only mode
    if (widget.isReadOnly || widget.wishId == null) return;

    final shouldDelete = await ConfirmationBottomSheet.show(
      context: context,
      title: 'app.delete'.tr(),
      message: 'wish.delete_confirmation'.tr(),
      confirmText: 'app.delete'.tr(),
      confirmColor: Colors.red,
    );

    if (shouldDelete == true && mounted) {
      // Haptic feedback when delete is confirmed
      HapticFeedback.mediumImpact();

      // Close the detail sheet immediately before starting deletion
      Navigator.of(context).pop(true);

      // Perform deletion (optimistic UI handles removal)
      final success = await context.read<WishlistService>().deleteWish(widget.wishId!);

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
    if (wish?.images.isEmpty ?? true) return;

    Navigator.of(context).push(
      NativePageRoute(
        child: _FullscreenImageGallery(
          images: wish!.images,
          initialIndex: _currentImageIndex,
          title: wish!.title,
        ),
      ),
    );
  }

  Future<void> _addToMyWishlist() async {
    if (wish == null) return;

    // Close the detail sheet first
    Navigator.of(context).pop();

    // Show add wish screen with prefilled data
    await AddWishScreen.show(
      context,
      prefilledData: {
        'title': wish!.title,
        'price': wish!.price,
        'currency': wish!.currency,
        'image': wish!.images.isNotEmpty ? wish!.images.first : null,
        'images': wish!.images,
        'url': wish!.url,
        'description': wish!.description,
      },
    );
  }

  void _shareWish() async {
    if (wish == null) {
      debugPrint('DEBUG: Share failed - wish is null');
      return;
    }

    try {
      // Create share text
      final shareText = StringBuffer();
      shareText.writeln(wish!.title);

      if (wish!.description != null && wish!.description!.isNotEmpty) {
        shareText.writeln('\n${wish!.description}');
      }

      if (wish!.price != null) {
        shareText.writeln('\n${wish!.currency ?? 'USD'} ${wish!.price!.toStringAsFixed(2)}');
      }

      if (wish!.url != null) {
        shareText.writeln('\n${wish!.url}');
      }

      final textToShare = shareText.toString();
      debugPrint('DEBUG: Attempting to share: $textToShare');

      ShareResult? result;

      // Check if there's an image to share
      if (wish!.imageUrl != null && wish!.imageUrl!.isNotEmpty) {
        debugPrint('DEBUG: Downloading image for sharing: ${wish!.imageUrl}');

        // Download image to temporary file
        final imageFile = await _downloadImageForSharing(wish!.imageUrl!);

        if (imageFile != null) {
          debugPrint('DEBUG: Image downloaded successfully, sharing with image');
          // Share with image using shareXFiles
          result = await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: textToShare,
            subject: wish!.title,
          );
        } else {
          debugPrint('DEBUG: Failed to download image, sharing text only');
          // Fall back to text-only share
          result = await Share.share(
            textToShare,
            subject: wish!.title,
          );
        }
      } else {
        debugPrint('DEBUG: No image to share, sharing text only');
        // Share text only
        result = await Share.share(
          textToShare,
          subject: wish!.title,
        );
      }

      debugPrint('DEBUG: Share result: ${result.status}');

      // Success feedback
      HapticFeedback.mediumImpact();

      // Show confirmation
      if (mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('success.shared'.tr()),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download image to temporary directory for sharing
  Future<File?> _downloadImageForSharing(String imageUrl) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();

      // Extract filename from URL or generate one
      final fileName = path.basename(Uri.parse(imageUrl).path);
      final extension = path.extension(fileName).isNotEmpty
          ? path.extension(fileName)
          : '.jpg'; // Default to .jpg if no extension

      final filePath = path.join(
        tempDir.path,
        'share_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      debugPrint('DEBUG: Downloading image from: $imageUrl');
      debugPrint('DEBUG: Saving to: $filePath');

      // Download image
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Write to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('DEBUG: Image downloaded successfully: ${file.lengthSync()} bytes');
        return file;
      } else {
        debugPrint('DEBUG: Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('DEBUG: Error downloading image for sharing: $e');
      return null;
    }
  }
}

/// Fullscreen image gallery widget with swipe support
class _FullscreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const _FullscreenImageGallery({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<_FullscreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Full screen image gallery with swipe
            Center(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {}, // Prevents taps on image from closing
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: CachedImageWidget(
                          imageUrl: widget.images[index],
                          fit: BoxFit.contain,
                          errorWidget: Container(
                            color: Colors.black,
                            child: Icon(
                              WishCategoryDetector.getIconFromTitle(widget.title),
                              size: 64,
                              color: WishCategoryDetector.getColorFromTitle(widget.title),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Image counter (top center)
            if (widget.images.length > 1)
              SafeArea(
                child: Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
    );
  }
}
