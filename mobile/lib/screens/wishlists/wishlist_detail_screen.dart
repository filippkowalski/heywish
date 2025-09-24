import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/wishlist_service.dart';
import '../../models/wish.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/wishlist_cover_image.dart';

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
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(wishlist?.name ?? 'app.loading'.tr()),
        actions: [
          if (wishlist != null)
            IconButton(
              icon: Icon(Icons.share),
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
                PopupMenuItem(
                  value: 'edit',
                  child: Text('app.edit'.tr()),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('app.delete'.tr()),
                ),
              ],
            ),
        ],
      ),
      body: wishlistService.isLoading
          ? Center(child: CircularProgressIndicator())
          : wishlist == null
              ? Center(child: Text('errors.not_found'.tr()))
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: CustomScrollView(
                    slivers: [
                      // Cover image section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: WishlistCoverImage(
                            coverImageUrl: wishlist.coverImageUrl,
                            wishlistId: widget.wishlistId,
                            canEdit: true,
                            height: 120,
                            onImageChanged: () {
                              // Refresh wishlist data when image changes
                              _loadWishlist();
                            },
                            onUpload: (wishlistId, imageFile) async {
                              final wishlistService = context.read<WishlistService>();
                              return await wishlistService.uploadWishlistCoverImage(wishlistId, imageFile);
                            },
                            onRemove: (wishlistId) async {
                              final wishlistService = context.read<WishlistService>();
                              return await wishlistService.removeWishlistCoverImage(wishlistId);
                            },
                          ),
                        ),
                      ),
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
        child: Icon(Icons.add),
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
              'wishlist.no_items'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'wishlist.add_first_item'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showAddWishDialog,
              icon: Icon(Icons.add),
              label: Text('wish.add_item'.tr()),
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
        title: Text('wishlist.delete_confirmation'.tr()),
        content: Text(
          'wishlist.delete_warning'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('app.delete'.tr(), style: const TextStyle(color: Colors.red)),
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
      // Generate the web share URL
      final shareUrl = wishlist.shareToken != null 
          ? 'https://heywish.vercel.app/w/${wishlist.shareToken}'
          : null;
      
      final shareText = '''
Check out my wishlist: ${wishlist.name}

${wishlist.description ?? 'A collection of things I\'d love to have!'}

Items: ${wishlist.wishes?.length ?? 0}

${shareUrl != null ? 'View here: $shareUrl' : ''}

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
                  leading: Icon(Icons.share),
                  title: Text('app.share'.tr()),
                  onTap: () async {
                    Navigator.pop(context);
                    if (shareUrl != null) {
                      await Share.share(shareUrl, subject: 'Check out my wishlist: ${wishlist.name}');
                    } else {
                      await Share.share(shareText, subject: 'Check out my wishlist: ${wishlist.name}');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('success.copied_to_clipboard'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    final textToCopy = shareUrl ?? shareText;
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('success.link_copied'.tr()),
                      ),
                    );
                  },
                ),
                if (shareUrl != null)
                  ListTile(
                    leading: Icon(Icons.web),
                    title: Text('Open in browser'),
                    onTap: () {
                      Navigator.pop(context);
                      _launchUrl(shareUrl);
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.unknown'.tr())),
      );
    }
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('errors.unknown'.tr())),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errors.unknown'.tr())),
        );
      }
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: wish.imageUrl != null
                    ? CachedImageWidget(
                        imageUrl: wish.imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                        errorWidget: Icon(
                          Icons.card_giftcard,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : Icon(
                        Icons.card_giftcard,
                        color: Colors.grey.shade600,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'wish.reserved'.tr(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.blue,
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
                  icon: Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(wish.url!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('errors.unknown'.tr())),
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