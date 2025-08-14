import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/wishlist_service.dart';
import '../../models/wishlist.dart';
import '../../theme/app_theme.dart';

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
      print('❌ WishlistsScreen: Failed to load wishlists: $e');
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
      appBar: AppBar(
        title: const Text('My Wishlists'),
        actions: [
          if (authService.isAnonymous)
            TextButton(
              onPressed: () {
                context.push('/auth/signup');
              },
              child: const Text('Sign Up'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Don't reset the _hasCompletedInitialLoad flag during refresh
          final wishlistService = context.read<WishlistService>();
          final authService = context.read<AuthService>();
          
          if (authService.isAuthenticated && authService.currentUser != null) {
            await wishlistService.fetchWishlists();
          }
        },
        child: !_hasCompletedInitialLoad
            ? _buildInitialLoadingState(context)
            : wishlistService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : wishlistService.error != null
                    ? _buildErrorState(wishlistService.error!)
                    : wishlistService.wishlists.isEmpty
                        ? _buildEmptyState(context)
                        : _buildContent(wishlistService.wishlists),
      ),
    );
  }

  Widget _buildInitialLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading your wishlists...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Getting everything ready',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Wishlist> wishlists) {
    return CustomScrollView(
      slivers: [
        // Header with stats
        SliverToBoxAdapter(
          child: _buildStatsHeader(wishlists),
        ),
        
        // Quick actions
        SliverToBoxAdapter(
          child: _buildQuickActions(),
        ),
        
        // Wishlists grid
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final wishlist = wishlists[index];
                return _WishlistCard(wishlist: wishlist);
              },
              childCount: wishlists.length,
            ),
          ),
        ),
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(List<Wishlist> wishlists) {
    final totalWishes = wishlists.fold<int>(0, (sum, w) => sum + w.wishCount);
    final totalReserved = wishlists.fold<int>(0, (sum, w) => sum + w.reservedCount);

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.coralColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Wishlist Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Lists', '${wishlists.length}', Icons.list_alt),
              const SizedBox(width: 16),
              _buildStatCard('Items', '$totalWishes', Icons.card_giftcard),
              const SizedBox(width: 16),
              _buildStatCard('Reserved', '$totalReserved', Icons.check_circle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                'Create List',
                Icons.add_circle,
                AppTheme.primaryColor,
                () => context.push('/wishlists/new'),
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                'Browse Ideas',
                Icons.lightbulb_outline,
                AppTheme.coralColor,
                () {
                  // TODO: Navigate to browse/discover
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Browse feature coming soon!')),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                'Share',
                Icons.share,
                AppTheme.skyColor,
                () {
                  // TODO: Share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No wishlists yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first wishlist and start adding items you love',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.push('/wishlists/new');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Wishlist'),
            ),
          ],
        ),
      ),
    );
  }

}

class _WishlistCard extends StatelessWidget {
  final Wishlist wishlist;

  const _WishlistCard({required this.wishlist});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/wishlists/${wishlist.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: wishlist.coverImageUrl != null
                  ? Image.network(
                      wishlist.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: AppTheme.primaryColor,
                        );
                      },
                    )
                  : const Icon(
                      Icons.card_giftcard,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wishlist.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${wishlist.wishCount} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (wishlist.reservedCount > 0)
                      Text(
                        '${wishlist.reservedCount} reserved',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mintColor,
                            ),
                      ),
                    const Spacer(),
                    if (wishlist.isPublic)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.skyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Public',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.skyColor,
                              ),
                        ),
                      ),
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