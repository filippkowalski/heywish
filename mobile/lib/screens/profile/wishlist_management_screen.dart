import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/wishlist_service.dart';
import '../../models/wishlist.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';

class WishlistManagementScreen extends StatefulWidget {
  const WishlistManagementScreen({super.key});

  @override
  State<WishlistManagementScreen> createState() => _WishlistManagementScreenState();
}

class _WishlistManagementScreenState extends State<WishlistManagementScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Schedule the load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlists();
    });
  }

  Future<void> _loadWishlists() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final wishlistService = context.read<WishlistService>();
      await wishlistService.fetchWishlists(preloadItems: true);
    } catch (e) {
      debugPrint('Error loading wishlists: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteWishlist(Wishlist wishlist) async {
    final confirmed = await ConfirmationBottomSheet.show(
      context: context,
      title: 'wishlist.delete_confirmation'.tr(),
      message: 'wishlist.delete_warning'.tr(),
      confirmText: 'app.delete'.tr(),
      cancelText: 'app.cancel'.tr(),
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        final wishlistService = context.read<WishlistService>();
        await wishlistService.deleteWishlist(wishlist.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('wishlist.deleted_successfully'.tr()),
              backgroundColor: AppTheme.primaryAccent,
            ),
          );
          await _loadWishlists();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete wishlist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.watch<WishlistService>();
    final wishlists = wishlistService.wishlists;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'profile.wishlist_management'.tr(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
            onPressed: () {
              context.push('/wishlists/new');
            },
            tooltip: 'wishlist.create_new'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : wishlists.isEmpty
              ? _buildEmptyState()
              : _buildWishlistsList(wishlists),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return const SkeletonWishlistCard();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.list_alt_outlined,
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'home.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'home.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/wishlists/new');
              },
              icon: const Icon(Icons.add),
              label: Text('wishlist.create_new'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistsList(List<Wishlist> wishlists) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: wishlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final wishlist = wishlists[index];
        return _WishlistManagementCard(
          wishlist: wishlist,
          onEdit: () {
            context.push('/wishlists/${wishlist.id}/edit');
          },
          onDelete: () {
            _deleteWishlist(wishlist);
          },
        );
      },
    );
  }
}

class _WishlistManagementCard extends StatelessWidget {
  final Wishlist wishlist;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WishlistManagementCard({
    required this.wishlist,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image or placeholder
          if (wishlist.coverImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedImageWidget(
                imageUrl: wishlist.coverImageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorWidget: _buildPlaceholderHeader(),
              ),
            )
          else
            _buildPlaceholderHeader(),

          // Wishlist info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wishlist.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (wishlist.description != null && wishlist.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              wishlist.description!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildVisibilityBadge(wishlist.visibility),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${wishlist.wishCount} items',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(wishlist.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('app.edit'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('app.delete'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildVisibilityBadge(String visibility) {
    IconData icon;
    String label;
    Color color;

    switch (visibility) {
      case 'public':
        icon = Icons.public;
        label = 'Public';
        color = Colors.green;
        break;
      case 'friends':
        icon = Icons.people;
        label = 'Friends';
        color = Colors.blue;
        break;
      case 'private':
      default:
        icon = Icons.lock;
        label = 'Private';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
}
