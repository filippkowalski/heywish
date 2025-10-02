import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/wish.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';

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

  @override
  void initState() {
    super.initState();
    _loadWish();
  }

  void _loadWish() {
    final wishlistService = context.read<WishlistService>();

    // First check if it's in the current wishlist
    final currentWishlist = wishlistService.currentWishlist;
    if (currentWishlist?.wishes != null) {
      wish = currentWishlist!.wishes!
          .where((w) => w.id == widget.wishId)
          .firstOrNull;
    }

    // If not found, check uncategorized wishes
    if (wish == null) {
      wish = wishlistService.uncategorizedWishes
          .where((w) => w.id == widget.wishId)
          .firstOrNull;
    }

    // If still not found, search through all wishlists
    if (wish == null) {
      for (final wl in wishlistService.wishlists) {
        if (wl.wishes != null) {
          final found = wl.wishes!.where((w) => w.id == widget.wishId).firstOrNull;
          if (found != null) {
            wish = found;
            break;
          }
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (wish == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item Details')),
        body: Center(
          child: Text('Item not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(wish!.title),
        actions: [
          PopupMenuButton<String>(
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
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reserve',
                child: Row(
                  children: [
                    Icon(wish!.isReserved ? Icons.remove_circle : Icons.bookmark),
                    SizedBox(width: 8),
                    Text(wish!.isReserved ? 'Unreserve' : 'Reserve'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (wish!.imageUrl != null) ...[
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: CachedImageWidget(
                  imageUrl: wish!.imageUrl,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                  errorWidget: Center(
                    child: Icon(
                      Icons.card_giftcard,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title and Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish!.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (wish!.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        wish!.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (wish!.price != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${wish!.currency ?? 'USD'} ${wish!.price!.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (wish!.isReserved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reserved',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Colors.blue,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.priority_high,
                      label: 'Priority',
                      value: _getPriorityText(wish!.priority),
                    ),
                    _DetailRow(
                      icon: Icons.numbers,
                      label: 'Quantity',
                      value: wish!.quantity.toString(),
                    ),
                    if (wish!.brand != null)
                      _DetailRow(
                        icon: Icons.branding_watermark,
                        label: 'Brand',
                        value: wish!.brand!,
                      ),
                    if (wish!.category != null)
                      _DetailRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: wish!.category!,
                      ),
                    if (wish!.notes != null)
                      _DetailRow(
                        icon: Icons.note,
                        label: 'Notes',
                        value: wish!.notes!,
                      ),
                    _DetailRow(
                      icon: Icons.schedule,
                      label: 'Added',
                      value: _formatDate(wish!.createdAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            if (wish!.url != null) ...[
              FilledButton.icon(
                onPressed: () => _openUrl(),
                icon: Icon(Icons.open_in_new),
                label: const Text('View Product'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () => _shareWish(),
              icon: Icon(Icons.share),
              label: const Text('Share Item'),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Medium';
    }
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

  void _editWish() {
    context.push('/wishlists/${widget.wishlistId}/items/${widget.wishId}/edit');
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
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade300,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}