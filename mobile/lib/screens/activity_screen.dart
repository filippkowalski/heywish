import 'package:flutter/material.dart';
import '../services/mock_data_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _activities = MockDataService.getMockActivities();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activities.isEmpty
                ? _buildEmptyState()
                : _buildActivityList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.gray400,
          ),
          SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When people interact with your wishlists,\nyou\'ll see updates here',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.gray400),
          ),
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
            AppTheme.skyColor.withOpacity(0.1),
            AppTheme.mintColor.withOpacity(0.1),
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
              color: AppTheme.skyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppTheme.skyColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get updates when friends interact with your wishlists',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isFirst) {
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
          side: BorderSide(color: AppTheme.gray200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar or icon
              _buildActivityIcon(activity),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['message'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (activity['wishlist'] != null)
                      Text(
                        'in ${activity['wishlist']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(activity['timestamp'] as DateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action icon
              _buildActionIcon(activity['type'] as String),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityIcon(Map<String, dynamic> activity) {
    if (activity['avatar'] != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(activity['avatar'] as String),
        backgroundColor: AppTheme.gray200,
        onBackgroundImageError: (exception, stackTrace) {},
        child: activity['avatar'] == null
            ? const Icon(Icons.person, color: AppTheme.gray400)
            : null,
      );
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getActivityColor(activity['type'] as String).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _getActivityIcon(activity['type'] as String),
        color: _getActivityColor(activity['type'] as String),
        size: 20,
      ),
    );
  }

  Widget _buildActionIcon(String type) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _getActivityColor(type).withOpacity(0.1),
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
      case 'wish_reserved':
        return Icons.check_circle;
      case 'wishlist_shared':
        return Icons.share;
      case 'wish_added':
        return Icons.add_circle;
      case 'friend_activity':
        return Icons.people;
      case 'price_drop':
        return Icons.trending_down;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'wish_reserved':
        return AppTheme.mintColor;
      case 'wishlist_shared':
        return AppTheme.skyColor;
      case 'wish_added':
        return AppTheme.primaryColor;
      case 'friend_activity':
        return AppTheme.coralColor;
      case 'price_drop':
        return AppTheme.amberColor;
      default:
        return AppTheme.gray400;
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