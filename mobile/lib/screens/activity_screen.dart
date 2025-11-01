import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/friends_service.dart';
import '../services/auth_service.dart';
import '../models/friend.dart';
import '../theme/app_theme.dart';
import '../widgets/cached_image.dart';
import '../common/widgets/native_refresh_indicator.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  List<Activity> _activities = [];
  bool _isLoading = true;
  String _selectedFilter = 'friends';
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearch = false;
  bool _isSearching = false;
  List<UserSearchResult> _searchResults = [];
  Timer? _searchDebouncer;

  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    // Hide search when switching away from Friends tab
    if (_tabController.index != 0 && _showSearch) {
      setState(() {
        _showSearch = false;
        _searchController.clear();
        _searchResults.clear();
        _isSearching = false;
      });
      _searchFocusNode.unfocus();
    }
  }

  void _activateSearch() {
    setState(() {
      _showSearch = true;
    });
    // Delay focus to ensure the search field is built
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    if (query.length >= 2) {
      _searchDebouncer?.cancel();
      _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
        _searchUsers(query);
      });
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) return;

    try {
      final results = await _friendsService.searchUsers(query);
      if (mounted && _searchController.text == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('search.error_searching'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _sendFriendRequest(UserSearchResult user) async {
    // Check if user is anonymous
    final authService = context.read<AuthService>();
    if (authService.firebaseUser?.isAnonymous == true) {
      _showCreateAccountPrompt();
      return;
    }

    try {
      await _friendsService.sendFriendRequest(user.id);

      if (!mounted) return;

      // Update the search results to reflect the new status
      setState(() {
        final index = _searchResults.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _searchResults[index] = UserSearchResult(
            id: user.id,
            username: user.username,
            fullName: user.fullName,
            avatarUrl: user.avatarUrl,
            bio: user.bio,
            friendshipStatus: 'pending',
            requestDirection: 'sent',
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_sent'.tr()),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_error'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _showCreateAccountPrompt() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add,
                size: 40,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'auth.create_account_title'.tr(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'auth.create_account_subtitle'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Google Sign In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _linkWithGoogle();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.g_mobiledata, size: 24, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'auth.sign_in_google'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Apple Sign In Button (iOS only)
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _linkWithApple();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, size: 24, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'auth.sign_in_apple'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Maybe Later Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'app.maybe_later'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkWithGoogle() async {
    try {
      final authService = context.read<AuthService>();
      await authService.linkWithGoogle();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.account_created_success'.tr()),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'auth.error_creating_account'.tr()}: ${error.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _linkWithApple() async {
    try {
      final authService = context.read<AuthService>();
      await authService.linkWithApple();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.account_created_success'.tr()),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'auth.error_creating_account'.tr()}: ${error.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final activities = await _friendsService.getActivityFeed(filter: _selectedFilter);
      setState(() {
        _activities = activities;
      });
    } catch (e) {
      debugPrint('Error loading activities: $e');
      // Fallback to mock data if API fails
      setState(() {
        _activities = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('activity.title'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          // Show search icon only on Friends tab
          if (_tabController.index == 0)
            IconButton(
              onPressed: _activateSearch,
              icon: Icon(Icons.search),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            _showSearch && _tabController.index == 0 ? 152 : 96,
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                onTap: (index) {
                  String filter;
                  switch (index) {
                    case 0:
                      filter = 'friends';
                      break;
                    case 1:
                      filter = 'all';
                      break;
                    case 2:
                      filter = 'own';
                      break;
                    default:
                      filter = 'friends';
                  }
                  _onFilterChanged(filter);
                },
                tabs: [
                  Tab(text: 'activity.tab_friends'.tr(), icon: Icon(Icons.people)),
                  Tab(text: 'activity.tab_discover'.tr(), icon: Icon(Icons.explore)),
                  Tab(text: 'activity.tab_my_activity'.tr(), icon: Icon(Icons.person)),
                ],
              ),
              // Search field - only visible on Friends tab
              if (_showSearch && _tabController.index == 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'search.hint_users'.tr(),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _showSearch && _searchController.text.isNotEmpty
          ? _buildSearchResults()
          : NativeRefreshIndicator(
              onRefresh: _loadActivities,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _activities.isEmpty
                      ? _buildEmptyState()
                      : _buildActivityList(),
            ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('search.searching'.tr()),
          ],
        ),
      );
    }

    if (_searchController.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'search.min_chars'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'search.no_results'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'search.try_different'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildSearchResultCard(user);
      },
    );
  }

  Widget _buildSearchResultCard(UserSearchResult user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CachedAvatarImage(
          imageUrl: user.avatarUrl,
          radius: 24,
        ),
        title: Text(
          user.displayName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                user.bio!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: _buildFriendshipButton(user),
      ),
    );
  }

  Widget _buildFriendshipButton(UserSearchResult user) {
    if (user.friendshipStatus == 'accepted') {
      return Chip(
        label: Text('friends.status_friends'.tr()),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
        ),
      );
    }

    if (user.friendshipStatus == 'pending') {
      if (user.requestDirection == 'sent') {
        return Chip(
          label: Text('friends.status_pending'.tr()),
          backgroundColor: Colors.orange.shade100,
          labelStyle: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
          ),
        );
      } else {
        return TextButton(
          onPressed: () {
            // User should go to Friends screen to respond
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.check_friend_requests'.tr()),
              ),
            );
          },
          child: Text('friends.respond'.tr()),
        );
      }
    }

    return ElevatedButton.icon(
      onPressed: () => _sendFriendRequest(user),
      icon: Icon(Icons.person_add, size: 16),
      label: Text('friends.add'.tr()),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'friends':
        title = 'activity.no_friend_activity_title'.tr();
        subtitle = 'activity.no_friend_activity_subtitle'.tr();
        icon = Icons.people_outline;
        break;
      case 'all':
        title = 'activity.no_discover_activity_title'.tr();
        subtitle = 'activity.no_discover_activity_subtitle'.tr();
        icon = Icons.explore_outlined;
        break;
      case 'own':
        title = 'activity.no_my_activity_title'.tr();
        subtitle = 'activity.no_my_activity_subtitle'.tr();
        icon = Icons.person_outline;
        break;
      default:
        title = 'activity.no_activity'.tr();
        subtitle = 'activity.no_activity'.tr();
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          if (_selectedFilter == 'friends') ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _activateSearch,
              icon: Icon(Icons.search),
              label: Text('friends.find_friends'.tr()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        
        // Activity items
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final activity = _activities[index];
              return _buildActivityCard(activity, index == 0);
            },
            childCount: _activities.length,
          ),
        ),
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'activity.stay_connected_title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'activity.stay_connected_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
        top: isFirst ? 0 : 0,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar - Clickable
              GestureDetector(
                onTap: () {
                  context.push('/profile/${activity.username}');
                },
                child: CachedAvatarImage(
                  imageUrl: activity.avatarUrl,
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.push('/profile/${activity.username}');
                      },
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: activity.userDisplayName,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: ' ${activity.description}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (activity.data['wishlist_name'] != null)
                      Text(
                        'in ${activity.data['wishlist_name']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    if (activity.data['item_name'] != null)
                      Text(
                        'Item: ${activity.data['item_name']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(activity.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Action icon
              _buildActionIcon(activity.activityType),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildActionIcon(String type) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getActivityColor(type).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getActivityIcon(type),
        color: _getActivityColor(type),
        size: 16,
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'collection_created':
        return Icons.playlist_add;
      case 'item_added':
        return Icons.add_circle;
      case 'item_reserved':
        return Icons.check_circle;
      case 'item_purchased':
        return Icons.shopping_bag;
      case 'friend_added':
        return Icons.people;
      case 'friend_request_sent':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'collection_created':
        return Theme.of(context).colorScheme.primary;
      case 'item_added':
        return Colors.green;
      case 'item_reserved':
        return Colors.orange;
      case 'item_purchased':
        return Colors.blue;
      case 'friend_added':
        return Colors.purple;
      case 'friend_request_sent':
        return Colors.blue;
      default:
        return Colors.grey.shade400;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}