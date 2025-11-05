import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../common/widgets/skeleton_loading.dart';
import '../common/widgets/native_refresh_indicator.dart';
import '../common/navigation/native_page_route.dart';
import '../services/api_service.dart' hide Friend;
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../models/friend.dart';
import '../widgets/cached_image.dart';
import 'wishlists/add_wish_screen.dart';
import 'feed_wish_detail_screen.dart';
import 'profile/public_profile_screen.dart';
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
  int _selectedTabIndex = 0; // 0 = Activity, 1 = Friends

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _searchController.addListener(_onSearchChanged);
    // Load friends data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsService>().getFriends();
    });
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
          if (activity.activityType == 'item_added' ||
              activity.activityType == 'wish_added') {
            // Extract image from images array
            String? wishImage;
            final images = activity.data['images'];
            if (images != null) {
              if (images is List && images.isNotEmpty) {
                wishImage = images[0];
              } else if (images is String) {
                wishImage = images;
              }
            }

            // Extract price - can be number or string
            double? wishPrice;
            final priceValue = activity.data['price'];
            if (priceValue != null) {
              if (priceValue is num) {
                wishPrice = priceValue.toDouble();
              } else if (priceValue is String) {
                wishPrice = double.tryParse(priceValue);
              }
            }

            feedItems.add(FeedItem(
              id: activity.id,
              friendName: activity.fullName ?? activity.username,
              friendUsername: activity.username,
              friendAvatar: activity.avatarUrl,
              wishTitle: activity.data['wish_title'] ?? 'Unknown Item',
              wishImage: wishImage,
              wishPrice: wishPrice,
              wishCurrency: activity.data['currency'] ?? 'USD',
              timeAgo: timeago.format(activity.createdAt),
              action: 'added to wishlist',
              wishId: activity.data['wish_id'],
              wishlistId: activity.data['wishlist_id'],
              wishUrl: activity.data['wish_url'] ?? activity.data['url'],
              wishDescription: activity.data['wish_description'] ?? activity.data['description'],
            ));
          }
        }
      }

      // If no friends' activity, load @jinnie profile wishes
      if (feedItems.isEmpty) {
        await _loadJinnieFeed(feedItems);
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

  Future<void> _loadJinnieFeed(List<FeedItem> feedItems) async {
    try {
      // Fetch @jinnie user's public profile (includes wishlists and items)
      final response = await _api.get('/public/users/jinnie');
      if (response == null) return;

      final jinnieUser = response['user'];
      final fullName = jinnieUser['full_name'] ?? 'Jinnie';
      final avatarUrl = jinnieUser['avatar_url'];

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
            friendUsername: 'jinnie',
            friendAvatar: avatarUrl,
            wishTitle: wish['title'] ?? 'Unknown Item',
            wishImage: imageUrl,
            wishPrice: price,
            wishCurrency: wish['currency'] ?? 'USD',
            timeAgo: timeago.format(DateTime.parse(wish['created_at'])),
            action: 'added to wishlist',
            wishId: wish['id'],
            wishlistId: wishlistId,
            wishUrl: wish['url'],
            wishDescription: wish['description'],
          ));
        }
      }
    } catch (error, stackTrace) {
      print('Error loading Jinnie feed: $error');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _copyWishToMyWishlist(FeedItem item) async {
    // Show add wish bottom sheet with prefilled data
    await AddWishScreen.show(
      context,
      prefilledData: {
        'title': item.wishTitle,
        'price': item.wishPrice,
        'currency': item.wishCurrency,
        'image': item.wishImage,
        'url': item.wishUrl,
        'description': item.wishDescription,
      },
    );
  }

  void _shareProfile() {
    final authService = AuthService();
    final username = authService.currentUser?.username ?? '';
    if (username.isNotEmpty) {
      final shareUrl = 'https://jinnie.co/@$username';
      Share.share(
        'Check out my wishlist on Jinnie! $shareUrl',
        subject: 'My Jinnie Profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
            ];
          },
          body: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
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
          // Toggle buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    label: 'feed.tab_activity'.tr(),
                    icon: Icons.local_activity_outlined,
                    isSelected: _selectedTabIndex == 0,
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _buildToggleButton(
                    label: 'feed.tab_friends'.tr(),
                    icon: Icons.people_outline,
                    isSelected: _selectedTabIndex == 1,
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                  ),
                ),
              ],
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

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppTheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Show search results when searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show friends list or activity feed based on selected tab
    if (_selectedTabIndex == 1) {
      return _buildFriendsListView();
    }

    // Show activity feed
    return NativeRefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Sharing card - Always show at top
          _buildSharingCard(),

          // Feed items
          if (_feedItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: _feedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFeedItem(item),
                  );
                }).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'feed.empty_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
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
    final shareUrl = username.isNotEmpty ? 'jinnie.co/@$username' : '';

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
          // Navigate to user profile using Navigator (not GoRouter) from IndexedStack tab
          Navigator.of(context).push(
            NativePageRoute(
              child: PublicProfileScreen(username: user.username),
            ),
          );
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
                // Clickable avatar
                GestureDetector(
                  onTap: () {
                    // Navigate using Navigator (not GoRouter) from IndexedStack tab
                    Navigator.of(context).push(
                      NativePageRoute(
                        child: PublicProfileScreen(username: item.friendUsername),
                      ),
                    );
                  },
                  child: CircleAvatar(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable username
                      GestureDetector(
                        onTap: () {
                          // Navigate using Navigator (not GoRouter) from IndexedStack tab
                          Navigator.of(context).push(
                            NativePageRoute(
                              child: PublicProfileScreen(username: item.friendUsername),
                            ),
                          );
                        },
                        child: RichText(
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

          // Wish item - Clickable
          GestureDetector(
            onTap: () async {
              // Show friend's wish detail with all data from feed
              await FeedWishDetailScreen.show(
                context,
                wishTitle: item.wishTitle,
                wishImage: item.wishImage,
                wishPrice: item.wishPrice,
                wishCurrency: item.wishCurrency,
                wishUrl: item.wishUrl,
                wishDescription: item.wishDescription,
                friendName: item.friendName,
                friendUsername: item.friendUsername,
                friendAvatar: item.friendAvatar,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Add to wishlist button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsListView() {
    return Consumer<FriendsService>(
      builder: (context, friendsService, child) {
        if (friendsService.isLoadingFriends) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (friendsService.friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'feed.friends_empty_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'feed.friends_empty_subtitle'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return NativeRefreshIndicator(
          onRefresh: () => friendsService.getFriends(forceRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            itemCount: friendsService.friends.length,
            itemBuilder: (context, index) {
              final friend = friendsService.friends[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFriendCard(friend),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // Navigate using Navigator (not GoRouter) from IndexedStack tab
          Navigator.of(context).push(
            NativePageRoute(
              child: PublicProfileScreen(username: friend.username),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
          child: Row(
            children: [
              // Avatar
              CachedAvatarImage(
                imageUrl: friend.avatarUrl,
                radius: 28,
              ),
              const SizedBox(width: 12),
              // Friend info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${friend.username}',
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
}

class FeedItem {
  final String id;
  final String friendName;
  final String friendUsername;
  final String? friendAvatar;
  final String wishTitle;
  final String? wishImage;
  final double? wishPrice;
  final String? wishCurrency;
  final String timeAgo;
  final String action;
  final String? wishId;
  final String? wishlistId;
  final String? wishUrl;
  final String? wishDescription;

  FeedItem({
    required this.id,
    required this.friendName,
    required this.friendUsername,
    this.friendAvatar,
    required this.wishTitle,
    this.wishImage,
    this.wishPrice,
    this.wishCurrency,
    required this.timeAgo,
    required this.action,
    this.wishId,
    this.wishlistId,
    this.wishUrl,
    this.wishDescription,
  });
}
