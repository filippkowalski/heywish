import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../common/widgets/skeleton_loading.dart';
import '../common/widgets/native_refresh_indicator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<FeedItem> _feedItems = [];
  List<dynamic> _searchResults = []; // Can be FeedItem or UserSearchResult
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });

    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      _performSearch(_searchQuery);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _api.searchUsers(query, limit: 20);

      setState(() {
        _searchResults = response?.users ?? [];
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _loadFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch activity feed from friends
      final feedResponse = await _api.getActivityFeed(filter: 'friends', limit: 20);
      final feedItems = <FeedItem>[];

      if (feedResponse != null && feedResponse.activities.isNotEmpty) {
        for (final activity in feedResponse.activities) {
          if (activity.activityType == 'wish_added') {
            feedItems.add(FeedItem(
              id: activity.id,
              friendName: activity.fullName ?? activity.username,
              friendAvatar: activity.avatarUrl,
              wishTitle: activity.data['wish_title'] ?? 'Unknown Item',
              wishImage: activity.data['wish_image'],
              wishPrice: activity.data['wish_price']?.toDouble(),
              wishCurrency: activity.data['wish_currency'] ?? 'USD',
              timeAgo: timeago.format(activity.createdAt),
              action: 'added to wishlist',
              wishId: activity.data['wish_id'],
              wishlistId: activity.data['wishlist_id'],
            ));
          }
        }
      }

      // If no friends' activity, load @heywish profile wishes
      if (feedItems.isEmpty) {
        await _loadHeyWishFeed(feedItems);
      }

      setState(() {
        _feedItems = feedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHeyWishFeed(List<FeedItem> feedItems) async {
    try {
      // Fetch @heywish user's public profile (includes wishlists and items)
      final response = await _api.get('/public/users/heywish');
      if (response == null) return;

      final heywishUser = response['user'];
      final fullName = heywishUser['full_name'] ?? 'HeyWish';
      final avatarUrl = heywishUser['avatar_url'];

      // Wishlists are already included in the response
      final wishlists = response['wishlists'] as List?;
      if (wishlists == null || wishlists.isEmpty) return;

      // Get wishes from all wishlists
      for (final wishlist in wishlists) {
        final items = wishlist['items'] as List?;
        if (items == null || items.isEmpty) continue;

        final wishlistId = wishlist['id'];

        for (final wish in items) {
          String? imageUrl;
          final images = wish['images'];
          if (images != null) {
            if (images is List && images.isNotEmpty) {
              imageUrl = images[0];
            } else if (images is String) {
              imageUrl = images;
            }
          }

          // Parse price - can be string or number from API
          double? price;
          final priceValue = wish['price'];
          if (priceValue != null) {
            if (priceValue is num) {
              price = priceValue.toDouble();
            } else if (priceValue is String) {
              price = double.tryParse(priceValue);
            }
          }

          feedItems.add(FeedItem(
            id: wish['id'],
            friendName: fullName,
            friendAvatar: avatarUrl,
            wishTitle: wish['title'] ?? 'Unknown Item',
            wishImage: imageUrl,
            wishPrice: price,
            wishCurrency: wish['currency'] ?? 'USD',
            timeAgo: timeago.format(DateTime.parse(wish['created_at'])),
            action: 'added to wishlist',
            wishId: wish['id'],
            wishlistId: wishlistId,
          ));
        }
      }
    } catch (error, stackTrace) {
      print('Error loading HeyWish feed: $error');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _copyWishToMyWishlist(FeedItem item) async {
    // Navigate to add wish screen with prefilled data
    context.push('/add-wish', extra: {
      'prefilledData': {
        'title': item.wishTitle,
        'price': item.wishPrice,
        'currency': item.wishCurrency,
        'image': item.wishImage,
      }
    });
  }

  void _shareProfile() {
    final authService = AuthService();
    final username = authService.currentUser?.username ?? '';
    if (username.isNotEmpty) {
      final shareUrl = 'https://heywish.com/@$username';
      Share.share(
        'Check out my wishlist on HeyWish! $shareUrl',
        subject: 'My HeyWish Profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'feed.title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'feed.search_placeholder'.tr(),
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primaryAccent,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show search results when searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show feed
    return NativeRefreshIndicator(
      onRefresh: _loadFeed,
      child: CustomScrollView(
        slivers: [
          // Sharing card - Always show at top
          SliverToBoxAdapter(
            child: _buildSharingCard(),
          ),

          // Feed items
          if (_feedItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _feedItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFeedItem(item),
                    );
                  },
                  childCount: _feedItems.length,
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'feed.empty_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'search.no_results'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final user = _searchResults[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildUserSearchResult(user),
        );
      },
    );
  }

  Widget _buildSharingCard() {
    final authService = AuthService();
    final username = authService.currentUser?.username ?? '';
    final shareUrl = username.isNotEmpty ? 'heywish.com/@$username' : '';

    if (shareUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryAccent.withValues(alpha: 0.08),
            AppTheme.primaryAccent.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.share,
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
                  'feed.more_fun_title'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'feed.more_fun_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppTheme.primaryAccent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _shareProfile,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'app.share'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildSkeletonFeedItem(),
      ),
    );
  }

  Widget _buildSkeletonFeedItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoading(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(width: 120, height: 16),
                    SizedBox(height: 4),
                    SkeletonText(width: 80, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SkeletonLoading(
            width: double.infinity,
            height: 160,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 12),
          const SkeletonText(width: 150, height: 16),
          const SizedBox(height: 4),
          const SkeletonText(width: 80, height: 14),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'feed.error'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'errors.unknown'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh),
              label: Text('app.retry'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResult(dynamic user) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // Navigate to user profile
          context.push('/profile/${user.username}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? user.username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // View profile button
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Friend info header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: item.friendAvatar == null
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Colors.transparent,
                  backgroundImage: item.friendAvatar != null
                      ? NetworkImage(item.friendAvatar!)
                      : null,
                  child: item.friendAvatar == null
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 20,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primary,
                              ),
                          children: [
                            TextSpan(
                              text: item.friendName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: ' ${item.action}',
                              style: const TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Wish item
          if (item.wishImage != null && item.wishImage!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(
                item.wishImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.wishTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                ),
                if (item.wishPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item.wishCurrency ?? '\$'}${item.wishPrice!.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                // Copy to wishlist button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyWishToMyWishlist(item),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text('feed.add_to_wishlist'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryAccent,
                      side: BorderSide(color: AppTheme.primaryAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeedItem {
  final String id;
  final String friendName;
  final String? friendAvatar;
  final String wishTitle;
  final String? wishImage;
  final double? wishPrice;
  final String? wishCurrency;
  final String timeAgo;
  final String action;
  final String? wishId;
  final String? wishlistId;

  FeedItem({
    required this.id,
    required this.friendName,
    this.friendAvatar,
    required this.wishTitle,
    this.wishImage,
    this.wishPrice,
    this.wishCurrency,
    required this.timeAgo,
    required this.action,
    this.wishId,
    this.wishlistId,
  });
}
