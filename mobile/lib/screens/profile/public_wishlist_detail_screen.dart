import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primary,
          ),
          onPressed: () => context.pop(),
        ),
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
    final isReserved = item['is_reserved'] == true;

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

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showItemDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
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
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailSheet(item),
    );
  }

  Widget _buildItemDetailSheet(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final description = item['description'];
    final isReserved = item['is_reserved'] == true;
    final url = item['url'];

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

    // Get images
    final List<String> imageUrls = [];
    final images = item['images'];
    if (images != null) {
      if (images is List) {
        imageUrls.addAll(images.map((e) => e.toString()));
      } else if (images is String && images.isNotEmpty) {
        imageUrls.add(images);
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedImageWidget(
                                  imageUrl: imageUrls[index],
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Reserved badge
                      if (isReserved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'wish.reserved'.tr(),
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isReserved) const SizedBox(height: 16),
                      // Title
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Price
                      if (price != null)
                        Text(
                          '$currency${price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      const SizedBox(height: 16),
                      // Description
                      if (description != null && description.isNotEmpty) ...[
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Actions
                      Row(
                        children: [
                          if (url != null && url.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Open URL in browser
                                  // You'll need to add url_launcher package
                                },
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Text('wish.url'.tr()),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          if (url != null && url.isNotEmpty) const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _copyItemToMyWishlist(item);
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: Text('feed.add_to_wishlist'.tr()),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
