import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/friends_service.dart';
import '../models/friend.dart';
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

  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
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
      ),
      body: NativeRefreshIndicator(
        onRefresh: _loadActivities,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _activities.isEmpty
                ? _buildEmptyState()
                : _buildActivityList(),
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
              onPressed: () {
                // Navigate to search screen - need to pass callback from home screen
              },
              icon: Icon(Icons.person_add),
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