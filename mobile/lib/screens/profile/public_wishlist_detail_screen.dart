import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import '../../widgets/cached_image.dart';
import '../wishlists/add_wish_screen.dart';

class PublicWishlistDetailScreen extends StatefulWidget {
  final String username;
  final String wishlistId;

  const PublicWishlistDetailScreen({
    super.key,
    required this.username,
    required this.wishlistId,
  });

  @override
  State<PublicWishlistDetailScreen> createState() => _PublicWishlistDetailScreenState();
}

class _PublicWishlistDetailScreenState extends State<PublicWishlistDetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _wishlistData;
  List<dynamic> _items = [];
  String? _reservingWishId; // Track which wish is currently being reserved/unreserved

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch the public profile which includes wishlists
      final response = await _api.get('/public/users/${widget.username}');

      if (response == null) {
        setState(() {
          _error = 'errors.not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      // Find the specific wishlist
      final wishlists = response['wishlists'] as List?;
      if (wishlists == null) {
        setState(() {
          _error = 'errors.not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      final wishlist = wishlists.firstWhere(
        (w) => w['id'] == widget.wishlistId,
        orElse: () => null,
      );

      if (wishlist == null) {
        setState(() {
          _error = 'errors.not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _wishlistData = wishlist;
        _items = wishlist['items'] ?? [];
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _copyItemToMyWishlist(Map<String, dynamic> item) async {
    // Parse price from the item
    double? price;
    final priceValue = item['price'];
    if (priceValue != null) {
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue);
      }
    }

    // Get first image
    String? imageUrl;
    final images = item['images'];
    if (images != null) {
      if (images is List && images.isNotEmpty) {
        imageUrl = images[0];
      } else if (images is String && images.isNotEmpty) {
        imageUrl = images;
      }
    }

    await AddWishScreen.show(
      context,
      prefilledData: {
        'title': item['title'],
        'description': item['description'],
        'price': price,
        'currency': item['currency'],
        'url': item['url'],
        'image': imageUrl,
        'category': item['category'],
      },
    );
  }

  Future<void> _reserveWish(String wishId) async {
    final confirmed = await ConfirmationBottomSheet.show(
      context: context,
      title: 'wish.reserve_confirmation_title'.tr(),
      message: 'wish.reserve_confirmation_message'.tr(),
      confirmText: 'wish.reserve'.tr(),
      cancelText: 'app.cancel'.tr(),
    );

    if (confirmed != true) return;

    setState(() {
      _reservingWishId = wishId;
    });

    try {
      await _api.post('/wishes/$wishId/reserve', {});

      // Reload wishlist to get updated reservation state
      await _loadWishlist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.reserved_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('409')
                  ? 'wish.already_reserved'.tr()
                  : 'wish.reservation_error'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reservingWishId = null;
        });
      }
    }
  }

  Future<void> _cancelReservation(String wishId) async {
    final confirmed = await ConfirmationBottomSheet.show(
      context: context,
      title: 'wish.unreserve_confirmation_title'.tr(),
      message: 'wish.unreserve_confirmation_message'.tr(),
      confirmText: 'wish.cancel_reservation'.tr(),
      cancelText: 'app.cancel'.tr(),
    );

    if (confirmed != true) return;

    setState(() {
      _reservingWishId = wishId;
    });

    try {
      await _api.delete('/wishes/$wishId/reserve');

      // Reload wishlist to get updated reservation state
      await _loadWishlist();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.unreserved_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('wish.reservation_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reservingWishId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        // Let Flutter/GoRouter handle back navigation automatically
        title: _wishlistData != null
            ? Text(
                _wishlistData!['name'] ?? 'wishlist.title'.tr(),
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => SkeletonLoading(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'errors.unknown'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadWishlist,
              icon: const Icon(Icons.refresh),
              label: Text('app.retry'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'wishlist.no_items'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return NativeRefreshIndicator(
      onRefresh: _loadWishlist,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final isReserved = item['status'] == 'reserved';

    // Parse price
    double? price;
    final priceValue = item['price'];
    if (priceValue != null) {
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue);
      }
    }

    final currency = item['currency'] ?? 'USD';

    // Get first image
    String? imageUrl;
    final images = item['images'];
    if (images != null) {
      if (images is List && images.isNotEmpty) {
        imageUrl = images[0];
      } else if (images is String && images.isNotEmpty) {
        imageUrl = images;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: imageUrl != null
                          ? CachedImageWidget(
                              imageUrl: imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: Icon(
                                Icons.card_giftcard,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                    // Reserved badge
                    if (isReserved)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'wish.reserved'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$currency${price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetail(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailSheet(item),
    );
  }

  Widget _buildItemDetailSheet(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final description = item['description'];
    final isReserved = item['status'] == 'reserved';
    final reservedByUid = item['reserved_by_uid'];
    final wishId = item['id'];
    final url = item['url'];

    // Get current user's Firebase UID to check if they reserved this item
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserUid = authService.firebaseUser?.uid;
    final isReservedByMe = isReserved && reservedByUid == currentUserUid;
    final isReservedByOther = isReserved && !isReservedByMe;
    final isReserving = _reservingWishId == wishId;

    // Parse price
    double? price;
    final priceValue = item['price'];
    if (priceValue != null) {
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue);
      }
    }

    final currency = item['currency'] ?? 'USD';

    // Get first image
    String? imageUrl;
    final images = item['images'];
    if (images != null) {
      if (images is List && images.isNotEmpty) {
        imageUrl = images[0];
      } else if (images is String && images.isNotEmpty) {
        imageUrl = images;
      }
    }

    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

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
            // Header with handle bar
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! > 0) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                color: Colors.transparent,
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
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if available
                    if (imageUrl != null) ...[
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
                          child: CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],

                    // Title
                    Text(
                      title,
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
                        if (price != null)
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
                              '$currency ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primaryAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        if (isReserved)
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
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],

                    // URL as a compact link
                    if (url != null && url.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          // Open URL - already imported url_launcher
                        },
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
                                  url,
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

            // Bottom action buttons
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reserve/Cancel Reservation button (only show if not reserved by others)
                  if (!isReservedByOther) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: isReservedByMe
                          ? OutlinedButton.icon(
                              onPressed: isReserving
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _cancelReservation(wishId);
                                    },
                              icon: isReserving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.bookmark_remove, size: 18),
                              label: Text('wish.cancel_reservation'.tr()),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryAccent,
                                side: const BorderSide(color: AppTheme.primaryAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: isReserving
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _reserveWish(wishId);
                                    },
                              icon: isReserving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.bookmark_add, size: 18),
                              label: Text('wish.reserve'.tr()),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add to My Wishlist button (always visible)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyItemToMyWishlist(item);
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text('wish.add_to_my_wishlist'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
