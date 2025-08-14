import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../services/wishlist_service.dart';
import '../../models/wish.dart';
import '../../theme/app_theme.dart';

class WishlistDetailScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailScreen({
    super.key,
    required this.wishlistId,
  });

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlist();
    });
  }

  Future<void> _loadWishlist() async {
    await context.read<WishlistService>().fetchWishlist(widget.wishlistId);
  }

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.watch<WishlistService>();
    final wishlist = wishlistService.currentWishlist;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(wishlist?.name ?? 'Loading...'),
        actions: [
          if (wishlist != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareWishlist(wishlist),
            ),
          if (wishlist != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/wishlists/${widget.wishlistId}/edit');
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
      body: wishlistService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlist == null
              ? const Center(child: Text('Wishlist not found'))
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: CustomScrollView(
                    slivers: [
                      if (wishlist.description != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wishlist.description!,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    if (wishlist.eventDate != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: AppTheme.gray400,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(wishlist.eventDate!),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (wishlist.wishes?.isEmpty ?? true)
                        SliverFillRemaining(
                          child: _buildEmptyState(context),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final wish = wishlist.wishes![index];
                                return _WishCard(
                                  wish: wish,
                                  wishlistId: widget.wishlistId,
                                );
                              },
                              childCount: wishlist.wishes!.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddWishDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding items to your wishlist',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddWishDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWishDialog() {
    context.push('/wishlists/${widget.wishlistId}/add-item');
  }

  void _showDeleteConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wishlist'),
        content: const Text(
          'Are you sure you want to delete this wishlist? This action cannot be undone.',
        ),
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
          .deleteWishlist(widget.wishlistId);
      
      if (success && mounted) {
        context.pop();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _shareWishlist(dynamic wishlist) async {
    try {
      // For now, we'll create a simple sharing message
      // In a full implementation, you'd generate a proper public URL
      final shareText = '''
Check out my wishlist: ${wishlist.name}

${wishlist.description ?? 'A collection of things I\'d love to have!'}

Items: ${wishlist.wishes?.length ?? 0}

Created with HeyWish 🎁
''';

      // Show sharing options
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share via...'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.share(shareText, subject: 'Check out my wishlist: ${wishlist.name}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy to clipboard'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wishlist details copied to clipboard')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Generate share link'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Generate and copy actual share link
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share link generation coming soon!')),
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
}

class _WishCard extends StatelessWidget {
  final Wish wish;
  final String wishlistId;

  const _WishCard({required this.wish, required this.wishlistId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/wishlists/$wishlistId/items/${wish.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: wish.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          wish.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.card_giftcard,
                              color: AppTheme.gray400,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.card_giftcard,
                        color: AppTheme.gray400,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (wish.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        wish.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (wish.price != null) ...[
                          Text(
                            '\$${wish.price!.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (wish.isReserved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.mintColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Reserved',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.mintColor,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (wish.url != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(wish.url!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open URL')),
                        );
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}