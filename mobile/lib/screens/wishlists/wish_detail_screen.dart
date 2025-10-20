import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/wish.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../utils/image_color_utils.dart';

class WishDetailScreen extends StatefulWidget {
  final String wishId;
  final String wishlistId;

  const WishDetailScreen({
    super.key,
    required this.wishId,
    required this.wishlistId,
  });

  @override
  State<WishDetailScreen> createState() => _WishDetailScreenState();
}

class _WishDetailScreenState extends State<WishDetailScreen> {
  Wish? wish;
  bool _useWhiteIcons = false; // Default to black icons

  @override
  void initState() {
    super.initState();
    _loadWish();
  }

  void _loadWish() async {
    final wishlistService = context.read<WishlistService>();
    wish = wishlistService.findWishById(widget.wishId);

    // Detect icon color based on image
    if (wish?.imageUrl != null) {
      try {
        final imageProvider = CachedNetworkImageProvider(wish!.imageUrl!);
        final shouldUseWhite = await ImageColorUtils.shouldUseWhiteIcons(imageProvider);
        if (mounted) {
          setState(() {
            _useWhiteIcons = shouldUseWhite;
          });
        }
      } catch (e) {
        debugPrint('Error detecting image color: $e');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (wish == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: const Center(
          child: Text('Item not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image background
          SliverAppBar(
            expandedHeight: wish!.imageUrl != null ? 300.0 : 120.0,
            pinned: true,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(
              color: _useWhiteIcons ? Colors.white : Colors.black,
            ),
            actionsIconTheme: IconThemeData(
              color: _useWhiteIcons ? Colors.white : Colors.black,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                  color: Colors.black,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: wish!.imageUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedImageWidget(
                          imageUrl: wish!.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.card_giftcard,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        // Gradient overlay for better text readability
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editWish();
                      } else if (value == 'delete') {
                        _deleteWish();
                      } else if (value == 'reserve') {
                        _toggleReservation();
                      }
                    },
                    itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reserve',
                    child: Row(
                      children: [
                        Icon(wish!.isReserved ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined),
                        const SizedBox(width: 12),
                        Text(wish!.isReserved ? 'Unreserve' : 'Reserve'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    wish!.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price and Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (wish!.price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${wish!.currency ?? 'USD'} ${wish!.price!.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (wish!.isReserved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reserved',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (wish!.description != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      wish!.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Additional details
                  if (wish!.brand != null || wish!.category != null || wish!.notes != null) ...[
                    const SizedBox(height: 32),
                    ...[
                      if (wish!.brand != null)
                        _DetailItem(
                          icon: Icons.local_offer_outlined,
                          label: 'Brand',
                          value: wish!.brand!,
                        ),
                      if (wish!.category != null)
                        _DetailItem(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: wish!.category!,
                        ),
                      if (wish!.notes != null)
                        _DetailItem(
                          icon: Icons.note_outlined,
                          label: 'Notes',
                          value: wish!.notes!,
                        ),
                      _DetailItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Added',
                        value: _formatDate(wish!.createdAt),
                      ),
                    ],
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  if (wish!.url != null) ...[
                    FilledButton.icon(
                      onPressed: _openUrl,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('View Product'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _shareWish,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Item'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _openUrl() async {
    if (wish?.url != null) {
      final uri = Uri.parse(wish!.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open URL')),
          );
        }
      }
    }
  }

  void _shareWish() async {
    if (wish == null) return;
    
    try {
      final shareText = '''
${wish!.title}

${wish!.description ?? 'An item from my wishlist'}

${wish!.price != null ? '${wish!.currency ?? 'USD'} ${wish!.price!.toStringAsFixed(2)}' : ''}

${wish!.url != null ? 'Product link: ${wish!.url}' : ''}

From my HeyWish wishlist 🎁
''';

      // Show sharing options
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.share),
                  title: const Text('Share via...'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.share(shareText, subject: 'Check out this item: ${wish!.title}');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy),
                  title: const Text('Copy details to clipboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item details copied to clipboard')),
                    );
                  },
                ),
                if (wish!.url != null)
                  ListTile(
                    leading: Icon(Icons.link),
                    title: const Text('Copy product URL'),
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(ClipboardData(text: wish!.url!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product URL copied to clipboard')),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }

  void _editWish() async {
    final result = await context.push('/wishlists/${widget.wishlistId}/items/${widget.wishId}/edit');

    // Refresh the wish details if the edit was successful
    if (result == true && mounted) {
      _loadWish();
    }
  }

  void _toggleReservation() async {
    if (wish == null) return;
    
    bool success = false;
    if (wish!.isReserved) {
      success = await context.read<WishlistService>().unreserveWish(widget.wishId);
    } else {
      // For now, just use anonymous reservation - could prompt for name later
      success = await context.read<WishlistService>().reserveWish(widget.wishId, null);
    }
    
    if (success && mounted) {
      _loadWish(); // Refresh the wish details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wish!.isReserved ? 'Item reserved successfully' : 'Item unreserved successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${wish!.isReserved ? 'unreserve' : 'reserve'} item',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteWish() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${wish!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final success = await context
          .read<WishlistService>()
          .deleteWish(widget.wishId);

      if (success && mounted) {
        // Navigate back and trigger refresh
        context.pop(true); // Pass true to signal that refresh is needed

        // Show success message after navigation
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}