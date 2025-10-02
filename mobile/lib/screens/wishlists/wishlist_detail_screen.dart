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
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import '../../common/navigation/native_page_route.dart';

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

  Future<void> _onReorder(wishlist, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    // Adjust newIndex if moving down the list
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Get the wishes list
    final wishes = List<Wish>.from(wishlist.wishes!);

    // Reorder locally for immediate feedback
    final movedWish = wishes.removeAt(oldIndex);
    wishes.insert(newIndex, movedWish);

    // Update positions based on new order
    final positions = wishes.asMap().entries.map((entry) {
      return {'id': entry.value.id, 'position': entry.key};
    }).toList();

    // Update on backend
    await context.read<WishlistService>().updateWishPositions(
      widget.wishlistId,
      positions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.watch<WishlistService>();
    final wishlist = wishlistService.currentWishlist;

    return Scaffold(
      appBar: AppBar(
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
              : NativeRefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: CustomScrollView(
                    slivers: [
                      // Cover image section (display only - edit in Edit Wishlist screen)
                      if (wishlist.coverImageUrl != null && wishlist.coverImageUrl!.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: WishlistCoverImage(
                              coverImageUrl: wishlist.coverImageUrl,
                              wishlistId: widget.wishlistId,
                              canEdit: false, // Editing only available in Edit Wishlist screen
                              height: 200,
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
                          sliver: SliverReorderableList(
                            onReorder: (oldIndex, newIndex) => _onReorder(wishlist, oldIndex, newIndex),
                            itemBuilder: (context, index) {
                              final wish = wishlist.wishes![index];
                              return _WishCard(
                                key: ValueKey(wish.id),
                                wish: wish,
                                wishlistId: widget.wishlistId,
                                index: index,
                              );
                            },
                            itemCount: wishlist.wishes!.length,
                          ),
                        ),
                      // Add Item button at the bottom
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: FilledButton.icon(
                            onPressed: _showAddWishDialog,
                            icon: const Icon(Icons.add),
                            label: Text('wish.add_item'.tr()),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 56),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
    final success = await ConfirmationBottomSheet.show<bool>(
      context: context,
      title: 'wishlist.delete_confirmation'.tr(),
      message: 'wishlist.delete_warning'.tr(),
      confirmText: 'app.delete'.tr(),
      cancelText: 'app.cancel'.tr(),
      icon: Icons.delete_outline,
      isDestructive: true,
      onConfirm: () async {
        return await context
            .read<WishlistService>()
            .deleteWishlist(widget.wishlistId);
      },
    );
    
    if (success == true && mounted) {
      context.pop();
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
      await _showShareOptions(context, shareText, shareUrl, wishlist);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.unknown'.tr())),
      );
    }
  }

  Future<void> _showShareOptions(BuildContext context, String shareText, String? shareUrl, dynamic wishlist) async {
    return await NativeTransitions.showNativeModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      child: _ShareOptionsBottomSheet(
        shareText: shareText,
        shareUrl: shareUrl,
        wishlist: wishlist,
        onLaunchUrl: _launchUrl,
      ),
    );
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
  final int index;

  const _WishCard({
    super.key,
    required this.wish,
    required this.wishlistId,
    required this.index,
  });

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
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                ),
              ),
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

class _ShareOptionsBottomSheet extends StatelessWidget {
  final String shareText;
  final String? shareUrl;
  final dynamic wishlist;
  final Function(String) onLaunchUrl;

  const _ShareOptionsBottomSheet({
    required this.shareText,
    required this.shareUrl,
    required this.wishlist,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.6,
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.share,
                  size: 32,
                  color: AppTheme.primaryAccent,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                'app.share'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                wishlist.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Share options
              Column(
                children: [
                  _ShareOptionTile(
                    icon: Icons.share,
                    title: 'Share',
                    onTap: () async {
                      Navigator.pop(context);
                      if (shareUrl != null) {
                        await Share.share(shareUrl!, subject: 'Check out my wishlist: ${wishlist.name}');
                      } else {
                        await Share.share(shareText, subject: 'Check out my wishlist: ${wishlist.name}');
                      }
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _ShareOptionTile(
                    icon: Icons.copy,
                    title: 'Copy Link',
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

                  if (shareUrl != null) ...[
                    const SizedBox(height: 12),
                    
                    _ShareOptionTile(
                      icon: Icons.open_in_new,
                      title: 'Open in Browser',
                      onTap: () {
                        Navigator.pop(context);
                        onLaunchUrl(shareUrl!);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}