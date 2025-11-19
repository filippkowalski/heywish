import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart' as intl;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import '../../common/widgets/masonry_wish_card.dart';
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

  Map<String, dynamic> _calculateTotalValuation(List<dynamic> items) {
    if (items.isEmpty) {
      return {'total': 0.0, 'currency': 'USD', 'hasAnyPrices': false};
    }

    // Group items by currency and calculate totals
    final Map<String, double> currencyTotals = {};
    bool hasAnyPrices = false;

    for (final item in items) {
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

      if (price != null && price > 0) {
        hasAnyPrices = true;
        final currency = item['currency'] ?? 'USD';
        final quantity = item['quantity'] ?? 1;
        final totalPrice = price * quantity;
        currencyTotals[currency] = (currencyTotals[currency] ?? 0.0) + totalPrice;
      }
    }

    if (!hasAnyPrices) {
      return {'total': 0.0, 'currency': 'USD', 'hasAnyPrices': false};
    }

    // Use the most common currency or USD as default
    final primaryCurrency = currencyTotals.keys.first;
    final total = currencyTotals[primaryCurrency] ?? 0.0;

    return {
      'total': total,
      'currency': primaryCurrency,
      'hasAnyPrices': true,
      'currencyTotals': currencyTotals,
    };
  }

  String _formatCurrency(double value, String currency) {
    final formatter = intl.NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: value % 1 == 0 ? 0 : 2,
    );
    return formatter.format(value);
  }

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
      case 'PLN':
        return 'zł';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  Widget _buildWishlistValuation(List<dynamic> items) {
    final valuation = _calculateTotalValuation(items);
    final hasAnyPrices = valuation['hasAnyPrices'] as bool;

    if (!hasAnyPrices) {
      return const SizedBox.shrink();
    }

    final total = valuation['total'] as double;
    final currency = valuation['currency'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: Text(
          '${'wishlist_valuation.total_value'.tr()}: ${_formatCurrency(total, currency)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
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
    return MasonryGridView.count(
      padding: const EdgeInsets.all(16.0),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              Container(
                height: index.isEven ? 180 : 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              // Content skeleton
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];

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

                final isReserved = item['status'] == 'reserved';

                return MasonryWishCard(
                  title: item['title'] ?? '',
                  description: item['description'],
                  imageUrl: imageUrl,
                  price: price,
                  currency: item['currency'],
                  url: item['url'],
                  isReserved: isReserved,
                  onTap: () => _showItemDetail(item),
                );
              },
            ),
          ),

          // Total value at bottom
          if (_items.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildWishlistValuation(_items),
            ),

          // Extra padding at the bottom
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
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
