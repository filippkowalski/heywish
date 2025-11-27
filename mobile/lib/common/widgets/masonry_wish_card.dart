import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../common/utils/wish_category_detector.dart';

/// Masonry grid card widget for displaying wish items
/// Used in both user's own wishlists and public profile views
class MasonryWishCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? imageUrl;
  final double? price;
  final String? currency;
  final String? url;
  final bool isReserved;
  final VoidCallback onTap;

  const MasonryWishCard({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    this.price,
    this.currency,
    this.url,
    this.isReserved = false,
    required this.onTap,
  });

  String _formatPrice(double price, String? currency) {
    // Currency symbol mapping
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'PLN': 'zł',
      'CAD': 'CA\$',
      'AUD': 'A\$',
    };

    final symbol = currencySymbols[currency] ?? currency ?? '\$';
    final formattedPrice = price.toStringAsFixed(0);

    // For currencies without symbols, show currency code
    if (!currencySymbols.containsKey(currency)) {
      return '$currency $formattedPrice';
    }

    return '$symbol$formattedPrice';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section - only show if image exists
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Stack(
                children: [
                  _MasonryImageCard(
                    imageUrl: imageUrl,
                    wishTitle: title,
                  ),
                  // Price overlay (bottom-left)
                  if (price != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatPrice(price!, currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Link indicator with favicon (top-left)
                  if (url != null && url!.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _FaviconIndicator(url: url!),
                    ),
                  // Reserved star indicator (top-right)
                  if (isReserved)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          color: AppTheme.primaryAccent,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Metadata row for cards without images
                  if (imageUrl == null || imageUrl!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // URL indicator
                          if (url != null && url!.isNotEmpty)
                            _FaviconIndicator(url: url!),
                          if (url != null && url!.isNotEmpty && (price != null || isReserved))
                            const SizedBox(width: 8),
                          // Price badge
                          if (price != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatPrice(price!, currency),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (price != null && isReserved)
                            const SizedBox(width: 8),
                          // Reserved indicator
                          if (isReserved)
                            Icon(
                              Icons.star,
                              color: AppTheme.primaryAccent,
                              size: 16,
                            ),
                        ],
                      ),
                    ),

                  // Title (max 2 lines)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description preview (only if description exists)
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for masonry grid image cards with dynamic aspect ratios
class _MasonryImageCard extends StatelessWidget {
  final String? imageUrl;
  final String wishTitle;

  const _MasonryImageCard({
    required this.imageUrl,
    required this.wishTitle,
  });

  @override
  Widget build(BuildContext context) {
    // This widget should only be called when imageUrl is not null/empty
    // but keep a safety check just in case
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) {
        return FutureBuilder<ImageInfo>(
          future: _getImageInfo(imageProvider),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              // Loading - show square placeholder
              return AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
              );
            }

            final imageInfo = snapshot.data!;
            final imageWidth = imageInfo.image.width.toDouble();
            final imageHeight = imageInfo.image.height.toDouble();
            var aspectRatio = imageWidth / imageHeight;

            // Constrain aspect ratio for masonry grid
            // Min: 0.6 (tall/portrait), Max: 1.5 (wide/landscape)
            aspectRatio = aspectRatio.clamp(0.6, 1.5);

            // Landscape images (wider than tall) should always use contain to show full object
            final isLandscape = imageWidth >= imageHeight;
            // Only crop very tall portrait images (aspect ratio < 0.6)
            final shouldCrop = !isLandscape && (imageWidth / imageHeight) < 0.6;

            return AspectRatio(
              aspectRatio: aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image(
                    image: imageProvider,
                    fit: shouldCrop ? BoxFit.cover : BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            );
          },
        );
      },
      placeholder: (context, url) => AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Center(
            child: Icon(
              WishCategoryDetector.getIconFromTitle(wishTitle),
              size: 48,
              color: WishCategoryDetector.getColorFromTitle(wishTitle),
            ),
          ),
        ),
      ),
    );
  }

  Future<ImageInfo> _getImageInfo(ImageProvider imageProvider) {
    final completer = Completer<ImageInfo>();
    final stream = imageProvider.resolve(const ImageConfiguration());

    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) {
            completer.complete(info);
          }
        },
        onError: (exception, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(exception, stackTrace);
          }
        },
      ),
    );

    return completer.future;
  }
}

/// Widget that displays a favicon for a URL or a fallback link icon
class _FaviconIndicator extends StatelessWidget {
  final String url;

  const _FaviconIndicator({required this.url});

  /// Extract domain from URL
  String? _extractDomain(String url) {
    try {
      final uri = Uri.tryParse(url.contains('://') ? url : 'https://$url');
      return uri?.host;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _extractDomain(url);

    if (domain == null) {
      // Fallback to link icon if we can't parse the domain
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.link,
          color: Colors.grey.shade700,
          size: 14,
        ),
      );
    }

    // Use Google's favicon service
    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=32';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CachedNetworkImage(
        imageUrl: faviconUrl,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        placeholder: (context, url) => SizedBox(
          width: 18,
          height: 18,
          child: Icon(
            Icons.link,
            color: Colors.grey.shade400,
            size: 14,
          ),
        ),
        errorWidget: (context, url, error) => Icon(
          Icons.link,
          color: Colors.grey.shade700,
          size: 14,
        ),
      ),
    );
  }
}
