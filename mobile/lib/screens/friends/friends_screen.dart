import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';
import '../../services/friends_service.dart';
import '../../models/friend.dart';
import '../../widgets/cached_image.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;

  const FriendsScreen({super.key, this.onNavigateToSearch});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load data through the service when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsService>().loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _respondToRequest(FriendRequest request, String action) async {
    try {
      await context.read<FriendsService>().respondToFriendRequest(request.id, action);
      
      // Reload data to get fresh state
      if (action == 'accept') {
        await context.read<FriendsService>().loadAllData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request ${action}ed'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error responding to request: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsService>(
      builder: (context, friendsService, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Friends'),
            actions: [
              IconButton(
                onPressed: () {
                  widget.onNavigateToSearch?.call();
                },
                icon: Icon(Icons.person_add_outlined),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people),
                      SizedBox(width: 8),
                      Text('Friends'),
                      if (friendsService.friends.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${friendsService.friends.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox),
                      SizedBox(width: 8),
                      Text('Requests'),
                      if (friendsService.friendRequests.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${friendsService.friendRequests.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 8),
                      Text('Sent'),
                      if (friendsService.sentRequests.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${friendsService.sentRequests.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(friendsService),
              _buildRequestsTab(friendsService),
              _buildSentTab(friendsService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsTab(FriendsService friendsService) {
    if (friendsService.isLoadingFriends) {
      return Center(child: CircularProgressIndicator());
    }

    if (friendsService.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Find and add friends to see their wishlists',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                widget.onNavigateToSearch?.call();
              },
              icon: Icon(Icons.person_add),
              label: Text('Find Friends'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendsService.getFriends(),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: friendsService.friends.length,
        itemBuilder: (context, index) {
          final friend = friendsService.friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildRequestsTab(FriendsService friendsService) {
    if (friendsService.isLoadingRequests) {
      return Center(child: CircularProgressIndicator());
    }

    if (friendsService.friendRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No friend requests',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll see friend requests here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendsService.getFriendRequests(type: 'received'),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: friendsService.friendRequests.length,
        itemBuilder: (context, index) {
          final request = friendsService.friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildSentTab(FriendsService friendsService) {
    if (friendsService.sentRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No sent requests',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Friend requests you send will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => friendsService.getFriendRequests(type: 'sent'),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: friendsService.sentRequests.length,
        itemBuilder: (context, index) {
          final request = friendsService.sentRequests[index];
          return _buildSentRequestCard(request);
        },
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CachedAvatarImage(
          imageUrl: friend.avatarUrl,
          radius: 24,
        ),
        title: Text(
          friend.displayName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${friend.username}'),
            SizedBox(height: 4),
            Text(
              'Friends since ${DateFormat('MMM d, y').format(friend.friendsSince)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to friend's profile/wishlists
          _showFriendProfile(friend);
        },
      ),
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CachedAvatarImage(
          imageUrl: request.requesterAvatarUrl,
          radius: 24,
        ),
        title: Text(
          request.requesterDisplayName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Sent ${DateFormat('MMM d').format(request.createdAt)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _respondToRequest(request, 'decline'),
              icon: Icon(Icons.close, color: Colors.red.shade600),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _respondToRequest(request, 'accept'),
              icon: Icon(Icons.check, color: Colors.green.shade600),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(FriendRequest request) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CachedAvatarImage(
          imageUrl: request.addresseeAvatarUrl,
          radius: 24,
        ),
        title: Text(
          request.addresseeDisplayName,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Sent ${DateFormat('MMM d').format(request.createdAt)}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Chip(
          label: Text('Pending'),
          backgroundColor: Colors.orange.shade100,
          labelStyle: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showFriendProfile(Friend friend) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CachedAvatarImage(
                          imageUrl: friend.avatarUrl,
                          radius: 40,
                        ),
                        SizedBox(height: 16),
                        Text(
                          friend.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${friend.username}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Friends since ${DateFormat('MMMM d, y').format(friend.friendsSince)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            friend.bio!,
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Navigate to friend's wishlists
                            },
                            icon: Icon(Icons.card_giftcard),
                            label: Text('View Wishlists'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}