import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';
import '../../services/friends_service.dart';
import '../../models/friend.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;

  const FriendsScreen({super.key, this.onNavigateToSearch});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final FriendsService _friendsService = FriendsService();
  final TextEditingController _searchController = TextEditingController();

  List<Friend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<FriendRequest> _sentRequests = [];
  bool _isLoadingFriends = false;
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFriends(),
      _loadFriendRequests(),
      _loadSentRequests(),
    ]);
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final friends = await _friendsService.getFriends();
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friends: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final requests = await _friendsService.getFriendRequests(type: 'received');
      setState(() {
        _friendRequests = requests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friend requests: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadSentRequests() async {
    try {
      final requests = await _friendsService.getFriendRequests(type: 'sent');
      setState(() {
        _sentRequests = requests;
      });
    } catch (e) {
      debugPrint('Error loading sent requests: $e');
    }
  }

  Future<void> _respondToRequest(FriendRequest request, String action) async {
    try {
      await _friendsService.respondToFriendRequest(request.id, action);
      
      // Remove from requests list
      setState(() {
        _friendRequests.removeWhere((r) => r.id == request.id);
      });

      // If accepted, refresh friends list
      if (action == 'accept') {
        await _loadFriends();
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
                  if (_friends.isNotEmpty) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_friends.length}',
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
                  if (_friendRequests.isNotEmpty) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_friendRequests.length}',
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
                  if (_sentRequests.isNotEmpty) ...[
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_sentRequests.length}',
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
          _buildFriendsTab(),
          _buildRequestsTab(),
          _buildSentTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
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
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          return _buildFriendCard(friend);
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return Center(child: CircularProgressIndicator());
    }

    if (_friendRequests.isEmpty) {
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
      onRefresh: _loadFriendRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) {
          final request = _friendRequests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildSentTab() {
    if (_sentRequests.isEmpty) {
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
      onRefresh: _loadSentRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
          child: friend.avatarUrl == null
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: request.requesterAvatarUrl != null 
              ? NetworkImage(request.requesterAvatarUrl!) 
              : null,
          child: request.requesterAvatarUrl == null
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
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
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: request.addresseeAvatarUrl != null 
              ? NetworkImage(request.addresseeAvatarUrl!) 
              : null,
          child: request.addresseeAvatarUrl == null
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
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
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
                          child: friend.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
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