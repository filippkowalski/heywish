import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../common/widgets/skeleton_loading.dart';
import '../common/widgets/native_refresh_indicator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../common/navigation/native_page_route.dart';
import 'search_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ApiService _api = ApiService();

  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  String? _error;
  int _friendsCount = 0;
  bool _hasFriendsWithWishes = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch friends count
      final friendsResponse = await _api.getFriends(limit: 1);
      _friendsCount = friendsResponse?.pagination.total ?? 0;

      // Fetch activity feed
      final feedResponse = await _api.getActivityFeed(filter: 'friends', limit: 20);

      if (feedResponse != null) {
        final feedItems = <FeedItem>[];

        for (final activity in feedResponse.activities) {
          if (activity.activityType == 'wish_added') {
            // Convert activity to FeedItem
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

        setState(() {
          _feedItems = feedItems;
          _hasFriendsWithWishes = feedItems.isNotEmpty;
          _isLoading = false;
        });
      } else {
        setState(() {
          _feedItems = [];
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _feedItems.isEmpty
                          ? _buildEmptyState()
                          : _buildFeedList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Friends Activity',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See what your friends are wishing for',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.5),
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
          Row(
            children: [
              SkeletonLoading(
                width: 40, 
                height: 40,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonText(width: 120, height: 16),
                    const SizedBox(height: 4),
                    const SkeletonText(width: 80, height: 14),
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load feed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    // Scenario 1: No friends at all
    if (_friendsCount == 0) {
      return _buildNoFriendsState();
    }

    // Scenario 2: Has friends but they haven't added wishes
    if (_friendsCount > 0 && !_hasFriendsWithWishes) {
      return _buildFriendsNoWishesState();
    }

    // Fallback empty state
    return _buildNoActivityState();
  }

  Widget _buildNoFriendsState() {
    final authService = AuthService();
    final username = authService.currentUser?.username ?? '';
    final shareUrl = username.isNotEmpty ? 'heywish.com/@$username' : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: AppTheme.primaryAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Find Your Friends',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with friends to see their wishes and discover gift ideas',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Share username card
            if (shareUrl.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Profile Link',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            shareUrl,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 20,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Search button
            FilledButton.icon(
              onPressed: () {
                // Navigate to search screen with People tab selected
                Navigator.of(context).push(
                  NativePageRoute(
                    child: const SearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Search for Friends'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsNoWishesState() {
    final authService = AuthService();
    final username = authService.currentUser?.username ?? '';
    final shareUrl = username.isNotEmpty ? 'heywish.com/@$username' : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 80,
              color: AppTheme.primaryAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Friends Are Quiet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have friends, but they haven\'t added any wishes yet. Invite more friends to grow your network!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Share username card
            if (shareUrl.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Share Your Profile',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            shareUrl,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy,
                            size: 20,
                            color: AppTheme.primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Find more friends button
            FilledButton.icon(
              onPressed: () {
                // Navigate to search screen with People tab selected
                Navigator.of(context).push(
                  NativePageRoute(
                    child: const SearchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Find More Friends'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivityState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon to see what your friends are wishing for',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    return NativeRefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFeedItem(item),
          );
        },
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: item.friendAvatar != null
                    ? NetworkImage(item.friendAvatar!)
                    : null,
                  child: item.friendAvatar == null
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade600)
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
                          color: Colors.grey.shade500,
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
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
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
                    label: const Text('Add to my wishlist'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryAccent,
                      side: BorderSide(color: AppTheme.primaryAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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