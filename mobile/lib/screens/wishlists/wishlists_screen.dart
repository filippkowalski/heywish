import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/wishlist_service.dart';
import '../../models/wishlist.dart';
import '../../models/wish.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/utils/wish_category_detector.dart';
import 'add_wish_screen.dart';
import 'wish_detail_screen.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> with SingleTickerProviderStateMixin {
  bool _hasLoadedOnce = false;
  bool _hasCompletedInitialLoad = false;
  String? _selectedWishlistFilter;
  bool _isShareBannerDismissed = false;
  static const String _shareBannerDismissedKey = 'share_banner_dismissed';

  @override
  void initState() {
    super.initState();
    _loadShareBannerState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlists();
    });
  }

  Future<void> _loadShareBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShareBannerDismissed = prefs.getBool(_shareBannerDismissedKey) ?? false;
    });
  }

  Future<void> _dismissShareBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareBannerDismissedKey, true);
    setState(() {
      _isShareBannerDismissed = true;
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try loading wishlists when authentication state changes, but only once
    final authService = context.watch<AuthService>();
    if (authService.isAuthenticated && authService.currentUser != null && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWishlists();
      });
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex, List<Wish> filteredWishes) async {
    if (oldIndex == newIndex || _selectedWishlistFilter == null) return;

    // Adjust newIndex if moving down the list
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Get the wishes list
    final wishes = List<Wish>.from(filteredWishes);

    // Reorder locally for immediate feedback
    final movedWish = wishes.removeAt(oldIndex);
    wishes.insert(newIndex, movedWish);

    // Update positions based on new order
    final positions = wishes.asMap().entries.map((entry) {
      return {'id': entry.value.id, 'position': entry.key};
    }).toList();

    // Update on backend
    await context.read<WishlistService>().updateWishPositions(
      _selectedWishlistFilter!,
      positions,
    );
  }

  Future<void> _loadWishlists() async {
    print('🔄 WishlistsScreen: Loading wishlists...');
    final wishlistService = context.read<WishlistService>();
    final authService = context.read<AuthService>();
    
    try {
      // Wait for authentication and user sync to complete first
      if (!authService.isAuthenticated || authService.currentUser == null) {
        print('⏳ WishlistsScreen: Waiting for authentication and user sync...');
        return;
      }
      
      await wishlistService.fetchWishlists();
      print('✅ WishlistsScreen: Wishlists loaded successfully');
    } catch (e) {
      debugPrint('❌ WishlistsScreen: Failed to load wishlists: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasCompletedInitialLoad = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final wishlistService = context.watch<WishlistService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, authService),
              Expanded(
                child: NativeRefreshIndicator(
                  onRefresh: () async {
                    final wishlistService = context.read<WishlistService>();
                    final authService = context.read<AuthService>();

                    if (authService.isAuthenticated && authService.currentUser != null) {
                      await wishlistService.fetchWishlists();
                    }
                  },
                  child: !_hasCompletedInitialLoad
                      ? _buildLoadingShimmer()
                      : wishlistService.isLoading
                          ? _buildLoadingShimmer()
                          : wishlistService.error != null
                              ? _buildErrorState(wishlistService.error!)
                              : (wishlistService.wishlists.isEmpty && wishlistService.allWishes.isEmpty)
                                  ? _buildEmptyState(context)
                                  : _buildContent(wishlistService.wishlists),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_hasCompletedInitialLoad || wishlistService.isLoading
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await AddWishScreen.show(context);
                // Refresh if wish was added successfully
                if (result == true && mounted) {
                  await _loadWishlists();
                }
              },
              backgroundColor: AppTheme.primaryAccent,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    final wishlistService = context.watch<WishlistService>();
    final hasAnyWishes = wishlistService.allWishes.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.title'.tr(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create & share your wish lists',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Share button - only show when user has at least one wish
          if (hasAnyWishes)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showShareBottomSheet(context),
                icon: const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'app.share'.tr(),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return const SkeletonWishlistCard();
      },
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadWishlists,
                icon: Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Wishlist> wishlists) {
    final wishlistService = context.watch<WishlistService>();
    final authService = context.watch<AuthService>();
    final allWishes = wishlistService.allWishes;
    final unsortedWishes = wishlistService.unsortedWishes;

    // Filter wishes by selected wishlist
    final filteredWishes = _selectedWishlistFilter == null
        ? allWishes
        : wishlistService.getWishesForWishlist(_selectedWishlistFilter);

    // Determine if we should show the share banner (3+ items)
    final shouldShowShareBanner = filteredWishes.length >= 3;

    // Get current user's username
    final username = authService.currentUser?.username;

    // Get selected wishlist for URL
    Wishlist? selectedWishlist;
    if (_selectedWishlistFilter != null) {
      try {
        selectedWishlist = wishlists.firstWhere((w) => w.id == _selectedWishlistFilter);
      } catch (e) {
        selectedWishlist = null;
      }
    }

    return Column(
      children: [
        // Share banner (show after 3+ items and if not dismissed)
        if (shouldShowShareBanner && username != null && !_isShareBannerDismissed)
          _ShareBanner(
            username: username,
            wishlistName: selectedWishlist?.name,
            onShareTap: () => _showShareBottomSheet(context),
            onDismiss: _dismissShareBanner,
          ),

        // Tabs for filtering by wishlist
        if (wishlists.isNotEmpty || unsortedWishes.isNotEmpty)
          _buildWishlistTabs(wishlists, unsortedWishes.length),

        // Wishes list
        Expanded(
          child: filteredWishes.isEmpty
              ? _buildEmptyWishesState()
              : _selectedWishlistFilter != null
                  // Reorderable list for specific wishlists
                  ? ReorderableListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: filteredWishes.length,
                      onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, filteredWishes),
                      itemBuilder: (context, index) {
                        final wish = filteredWishes[index];
                        Wishlist? wishlist;
                        if (wish.wishlistId != null) {
                          try {
                            wishlist = wishlists.firstWhere((w) => w.id == wish.wishlistId);
                          } catch (e) {
                            wishlist = null;
                          }
                        }
                        return Padding(
                          key: ValueKey(wish.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WishCard(wish: wish, wishlist: wishlist),
                        );
                      },
                    )
                  // Regular list for "All" view
                  : ListView.separated(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: filteredWishes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final wish = filteredWishes[index];
                        Wishlist? wishlist;
                        if (wish.wishlistId != null) {
                          try {
                            wishlist = wishlists.firstWhere((w) => w.id == wish.wishlistId);
                          } catch (e) {
                            wishlist = null;
                          }
                        }
                        return _WishCard(wish: wish, wishlist: wishlist);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildWishlistTabs(List<Wishlist> wishlists, int unsortedCount) {
    final wishlistService = context.watch<WishlistService>();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" tab (includes unsorted wishes)
          _buildTabChip(
            label: 'All',
            isSelected: _selectedWishlistFilter == null,
            onTap: () {
              setState(() {
                _selectedWishlistFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          // Wishlist tabs
          ...wishlists.map((wishlist) {
            final wishCount = wishlistService.getWishesForWishlist(wishlist.id).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTabChip(
                label: wishlist.name,
                count: wishCount,
                isSelected: _selectedWishlistFilter == wishlist.id,
                onTap: () {
                  setState(() {
                    _selectedWishlistFilter = wishlist.id;
                  });
                },
                onLongPress: () {
                  // Navigate to edit wishlist on long press
                  context.push('/wishlists/${wishlist.id}/edit');
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWishesState() {
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
                Icons.card_giftcard_outlined,
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No items yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedWishlistFilter == null
                  ? 'Add your first item to get started'
                  : 'No items in this wishlist yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AddWishScreen.show(context);
                // Refresh if wish was added successfully
                if (result == true && mounted) {
                  await _loadWishlists();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
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
                  Icons.card_giftcard_outlined,
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
                onPressed: () async {
                  final result = await AddWishScreen.show(context);
                  // Refresh if wish was added successfully
                  if (result == true && mounted) {
                    await _loadWishlists();
                  }
                },
                icon: Icon(Icons.add),
                label: Text('home.create_first_wish'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    final authService = context.read<AuthService>();
    final wishlistService = context.read<WishlistService>();
    final username = authService.currentUser?.username;

    if (username == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ShareBottomSheet(
        username: username,
        wishlists: wishlistService.wishlists,
      ),
    );
  }

}

class _WishCard extends StatefulWidget {
  final Wish wish;
  final Wishlist? wishlist;

  const _WishCard({required this.wish, this.wishlist});

  @override
  State<_WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<_WishCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 120,
      decoration: BoxDecoration(
        color: _isPressed ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPressed ? AppTheme.cardBorderActive : AppTheme.cardBorder,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () async {
            // Show wish detail bottom sheet
            final wishlistId = widget.wishlist?.id ?? 'unsorted';
            final result = await WishDetailScreen.show(
              context,
              wishId: widget.wish.id,
              wishlistId: wishlistId,
            );

            // Refresh if item was deleted
            if (result == true && mounted) {
              // Small delay to ensure backend has processed the deletion
              await Future.delayed(const Duration(milliseconds: 150));

              if (mounted) {
                // Trigger refresh via WishlistService
                await context.read<WishlistService>().fetchWishlists();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          },
          child: Row(
            children: [
              // Item image - larger and touching edges
              SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: widget.wish.imageUrl != null
                      ? AspectRatio(
                          aspectRatio: 1.0,
                          child: CachedImageWidget(
                            imageUrl: widget.wish.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey.shade100,
                              child: Icon(
                                WishCategoryDetector.getIconFromTitle(widget.wish.title),
                                size: 40,
                                color: WishCategoryDetector.getColorFromTitle(widget.wish.title),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            WishCategoryDetector.getIconFromTitle(widget.wish.title),
                            size: 40,
                            color: WishCategoryDetector.getColorFromTitle(widget.wish.title),
                          ),
                        ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.wish.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.wishlist?.name ?? 'Unsorted',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.wish.price != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.wish.currency ?? 'USD'} ${widget.wish.price!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Reserved indicator or arrow
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: widget.wish.isReserved
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Reserved',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.arrowIndicator,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Share Banner Widget
class _ShareBanner extends StatelessWidget {
  final String username;
  final String? wishlistName;
  final VoidCallback onShareTap;
  final VoidCallback onDismiss;

  const _ShareBanner({
    required this.username,
    this.wishlistName,
    required this.onShareTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Construct share URL (without https://)
    final shareUrl = wishlistName != null
        ? 'jinnie.co/$username/${wishlistName!.toLowerCase().replaceAll(' ', '-')}'
        : 'jinnie.co/$username';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji, title, and close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎉',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'wishlist.share_banner_title'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wishlist.share_banner_cta'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onShareTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.ios_share, size: 18),
              label: Text(
                'wishlist.share_now'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Share Bottom Sheet Widget
class _ShareBottomSheet extends StatefulWidget {
  final String username;
  final List<Wishlist> wishlists;

  const _ShareBottomSheet({
    required this.username,
    required this.wishlists,
  });

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final Map<String, bool> _updatingVisibility = {};

  Future<void> _toggleVisibility(Wishlist wishlist) async {
    setState(() {
      _updatingVisibility[wishlist.id] = true;
    });

    // Cycle through: public -> friends -> private -> public
    String newVisibility;
    if (wishlist.visibility == 'public') {
      newVisibility = 'friends';
    } else if (wishlist.visibility == 'friends') {
      newVisibility = 'private';
    } else {
      newVisibility = 'public';
    }

    final wishlistService = context.read<WishlistService>();
    final success = await wishlistService.updateWishlist(
      wishlist.id,
      visibility: newVisibility,
    );

    if (mounted) {
      setState(() {
        _updatingVisibility[wishlist.id] = false;
      });

      if (success) {
        String message;
        if (newVisibility == 'public') {
          message = 'wishlist.wishlist_now_public'.tr();
        } else if (newVisibility == 'friends') {
          message = 'wishlist.wishlist_now_friends'.tr();
        } else {
          message = 'wishlist.wishlist_now_private'.tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Construct profile URL (without https://)
    final profileUrl = 'jinnie.co/${widget.username}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.ios_share,
                      color: AppTheme.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'wishlist.share_sheet_title'.tr(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'wishlist.share_sheet_subtitle'.tr(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Link
                    _ProfileShareItem(
                      username: widget.username,
                      url: profileUrl,
                    ),

                    if (widget.wishlists.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Row(
                          children: [
                            Text(
                              'wishlist.your_lists'.tr(),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Wishlist Items
                      ...widget.wishlists.map((wishlist) {
                        final wishlistUrl =
                            'jinnie.co/${widget.username}/${wishlist.name.toLowerCase().replaceAll(' ', '-')}';
                        final isPrivate = wishlist.visibility == 'private';
                        final isUpdating = _updatingVisibility[wishlist.id] ?? false;

                        return _WishlistShareItem(
                          wishlist: wishlist,
                          url: wishlistUrl,
                          isPrivate: isPrivate,
                          isUpdating: isUpdating,
                          onToggleVisibility: () => _toggleVisibility(wishlist),
                        );
                      }),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Share Item Widget
class _ProfileShareItem extends StatelessWidget {
  final String username;
  final String url;

  const _ProfileShareItem({
    required this.username,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await Share.share(
          'https://$url',
          subject: 'wishlist.your_profile'.tr(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wishlist.your_profile'.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.ios_share,
              color: AppTheme.primaryAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Wishlist Share Item Widget
class _WishlistShareItem extends StatelessWidget {
  final Wishlist wishlist;
  final String url;
  final bool isPrivate;
  final bool isUpdating;
  final VoidCallback onToggleVisibility;

  const _WishlistShareItem({
    required this.wishlist,
    required this.url,
    required this.isPrivate,
    required this.isUpdating,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    // Get visibility label
    String visibilityLabel;
    if (wishlist.visibility == 'public') {
      visibilityLabel = 'wishlist.visibility_public'.tr();
    } else if (wishlist.visibility == 'friends') {
      visibilityLabel = 'wishlist.visibility_friends'.tr();
    } else {
      visibilityLabel = 'wishlist.visibility_private'.tr();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wishlist name
                Text(
                  wishlist.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                // URL or Private indicator
                Text(
                  isPrivate ? 'wishlist.private'.tr() : url,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Visibility toggle
                GestureDetector(
                  onTap: isUpdating ? null : onToggleVisibility,
                  child: Row(
                    children: [
                      if (isUpdating)
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryAccent),
                          ),
                        )
                      else
                        Icon(
                          wishlist.visibility == 'public'
                              ? Icons.public
                              : wishlist.visibility == 'friends'
                                  ? Icons.people
                                  : Icons.lock,
                          size: 13,
                          color: AppTheme.primaryAccent,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isUpdating
                            ? 'wishlist.updating'.tr()
                            : '${'wishlist.visibility'.tr()}: $visibilityLabel',
                        style: TextStyle(
                          color: isUpdating
                              ? AppTheme.primaryAccent
                              : AppTheme.primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Share button
          if (!isPrivate)
            GestureDetector(
              onTap: isUpdating
                  ? null
                  : () async {
                      await Share.share(
                        'https://$url',
                        subject: wishlist.name,
                      );
                    },
              child: Opacity(
                opacity: isUpdating ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.ios_share,
                    color: AppTheme.primaryAccent,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}