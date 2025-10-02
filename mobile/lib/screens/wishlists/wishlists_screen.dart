import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import '../../services/wishlist_service.dart';
import '../../models/wishlist.dart';
import '../../models/wish.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> with SingleTickerProviderStateMixin {
  bool _hasLoadedOnce = false;
  bool _hasCompletedInitialLoad = false;
  String? _selectedWishlistFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlists();
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
                              : wishlistService.wishlists.isEmpty
                                  ? _buildEmptyState(context)
                                  : _buildContent(wishlistService.wishlists),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
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
          // Add item button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                context.push('/add-wish');
              },
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
              tooltip: 'Add Item',
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
    return Center(
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
    );
  }

  Widget _buildContent(List<Wishlist> wishlists) {
    final wishlistService = context.watch<WishlistService>();
    final uncategorizedWishes = wishlistService.uncategorizedWishes;

    // Collect all wishes from all wishlists
    final allWishes = <Wish>[];
    for (final wishlist in wishlists) {
      if (wishlist.wishes != null) {
        allWishes.addAll(wishlist.wishes!);
      }
    }

    // Add uncategorized wishes
    allWishes.addAll(uncategorizedWishes);

    // Filter wishes by selected wishlist
    final filteredWishes = _selectedWishlistFilter == null
        ? allWishes
        : _selectedWishlistFilter == 'uncategorized'
            ? uncategorizedWishes
            : allWishes.where((wish) => wish.wishlistId == _selectedWishlistFilter).toList();

    return Column(
      children: [
        // Tabs for filtering by wishlist
        if (wishlists.isNotEmpty || uncategorizedWishes.isNotEmpty)
          _buildWishlistTabs(wishlists, uncategorizedWishes.length),

        // Wishes list
        Expanded(
          child: filteredWishes.isEmpty
              ? _buildEmptyWishesState()
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

  Widget _buildWishlistTabs(List<Wishlist> wishlists, int uncategorizedCount) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" tab
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
          // Uncategorized tab (only show if there are uncategorized wishes)
          if (uncategorizedCount > 0) ...[
            _buildTabChip(
              label: 'Uncategorized',
              count: uncategorizedCount,
              isSelected: _selectedWishlistFilter == 'uncategorized',
              onTap: () {
                setState(() {
                  _selectedWishlistFilter = 'uncategorized';
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          // Wishlist tabs
          ...wishlists.map((wishlist) {
            final wishCount = wishlist.wishes?.length ?? 0;
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
              onPressed: () {
                context.push('/add-wish');
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
              icon: Icon(Icons.add),
              label: Text('home.create_first_wishlist'.tr()),
            ),
          ],
        ),
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
          onTap: () {
            // Navigate to wish detail
            final wishlistId = widget.wishlist?.id ?? 'uncategorized';
            context.push('/wishlists/$wishlistId/items/${widget.wish.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Item image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.wish.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedImageWidget(
                            imageUrl: widget.wish.imageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorWidget: Icon(
                              Icons.card_giftcard_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.wish.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.wishlist?.name ?? 'Uncategorized',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.wish.price != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${widget.wish.currency ?? 'USD'} ${widget.wish.price!.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Reserved indicator or arrow
                if (widget.wish.isReserved)
                  Container(
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
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.arrowIndicator,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}