import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import '../../services/wishlist_service.dart';
import '../../models/wishlist.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/widgets/skeleton_loading.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  bool _hasLoadedOnce = false;
  bool _hasCompletedInitialLoad = false;

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
    
    // Wait for authentication and user sync to complete first
    if (!authService.isAuthenticated || authService.currentUser == null) {
      print('⏳ WishlistsScreen: Waiting for authentication and user sync...');
      return;
    }
    
    try {
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    final wishlistService = context.read<WishlistService>();
                    final authService = context.read<AuthService>();
                    
                    if (authService.isAuthenticated && authService.currentUser != null) {
                      await wishlistService.fetchWishlists();
                    }
                  },
                  child: !_hasCompletedInitialLoad
                      ? _buildInitialLoadingState(context)
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create & share your wish lists',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.primary, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Setting up your wishlist space ✨',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Almost ready to start making wishes!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 240,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
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
    return ListView.separated(
      padding: const EdgeInsets.all(20.0),
      itemCount: wishlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final wishlist = wishlists[index];
        return _WishlistCard(wishlist: wishlist);
      },
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

class _WishlistCard extends StatefulWidget {
  final Wishlist wishlist;

  const _WishlistCard({required this.wishlist});

  @override
  State<_WishlistCard> createState() => _WishlistCardState();
}

class _WishlistCardState extends State<_WishlistCard> {
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
            context.push('/wishlists/${widget.wishlist.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon/Image container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.wishlist.coverImageUrl != null
                      ? CachedImageWidget(
                          imageUrl: widget.wishlist.coverImageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                          errorWidget: Icon(
                            Icons.card_giftcard_outlined,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.card_giftcard_outlined,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.wishlist.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.wishlist.isPublic)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Public',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          Text(
                            '${widget.wishlist.wishCount} items',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (widget.wishlist.reservedCount > 0) ...[
                            Text(
                              ' • ',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${widget.wishlist.reservedCount} reserved',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow indicator
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