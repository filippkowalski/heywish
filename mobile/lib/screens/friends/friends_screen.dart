import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../services/friends_service.dart';
import '../../services/auth_service.dart';
import '../../models/friend.dart';
import '../../models/friendship_enums.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cached_image.dart';
import '../../common/widgets/native_refresh_indicator.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final int initialTabIndex;

  const FriendsScreen({
    super.key,
    this.onNavigateToSearch,
    this.initialTabIndex = 0,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearch = false;
  bool _isSearching = false;
  List<UserSearchResult> _searchResults = [];
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, 2).toInt();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    // Load data through the service when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsService>().loadAllData();
    });
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
      final results = await context.read<FriendsService>().searchUsers(query);
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
      await context.read<FriendsService>().sendFriendRequest(user.id);

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
            friendshipStatus: FriendshipStatus.pending.toJson(),
            requestDirection: RequestDirection.sent.toJson(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_sent'.tr(namedArgs: {'name': user.displayName})),
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

  Future<void> _respondToRequest(FriendRequest request, String action) async {
    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.respondToFriendRequest(request.id, action);

      // Reload data after any action so lists stay in sync
      await friendsService.loadAllData(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.request_action_success'.tr(namedArgs: {'action': action})),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.request_action_error'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _cancelFriendRequest(UserSearchResult user) async {
    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.cancelFriendRequest(user.id);

      if (!mounted) return;

      // Update the search results to reflect the cancelled status
      setState(() {
        final index = _searchResults.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _searchResults[index] = UserSearchResult(
            id: user.id,
            username: user.username,
            fullName: user.fullName,
            avatarUrl: user.avatarUrl,
            bio: user.bio,
            friendshipStatus: null,
            requestDirection: null,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_cancelled'.tr()),
          backgroundColor: Colors.grey.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.error_cancelling_request'.tr()),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _cancelSentRequest(FriendRequest request) async {
    if (request.addresseeId == null) return;

    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.cancelFriendRequest(request.addresseeId!);

      // Reload data after cancelling
      await friendsService.loadAllData(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.request_cancelled'.tr()),
            backgroundColor: Colors.grey.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.error_cancelling_request'.tr()),
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
            title: Text('friends.title'.tr()),
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
                _showSearch && _tabController.index == 0 ? 104 : 48,
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 6),
                      Text('friends.tab_friends'.tr()),
                      if (friendsService.friends.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${friendsService.friends.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                      Icon(Icons.inbox, size: 20),
                      SizedBox(width: 6),
                      Text('friends.tab_requests'.tr()),
                      if (friendsService.friendRequests.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${friendsService.friendRequests.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 6),
                      Text('friends.tab_sent'.tr()),
                      if (friendsService.sentRequests.isNotEmpty) ...[
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${friendsService.sentRequests.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
    // Show search results if searching
    if (_showSearch && _searchController.text.isNotEmpty) {
      return _buildSearchResults();
    }

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
              'friends.no_friends_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'friends.no_friends_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _activateSearch,
              icon: Icon(Icons.search),
              label: Text('friends.find_friends'.tr()),
            ),
          ],
        ),
      );
    }

    return NativeRefreshIndicator(
      onRefresh: () => friendsService.getFriends(forceRefresh: true),
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
        onTap: user.isFriend
          ? () => context.push('/profile/${user.username}')
          : null,
      ),
    );
  }

  Widget _buildFriendshipButton(UserSearchResult user) {
    if (user.isFriend) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.green.shade700,
            ),
            SizedBox(width: 4),
            Text(
              'friends.status_friends'.tr(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (user.hasPendingRequest) {
      if (user.requestSentByMe) {
        return InkWell(
          onTap: () => _cancelFriendRequest(user),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.orange.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                SizedBox(width: 4),
                Text(
                  'friends.status_pending'.tr(),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
              ],
            ),
          ),
        );
      } else {
        return TextButton(
          onPressed: () {
            // Navigate to requests tab to respond
            _tabController.animateTo(1);
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
              'friends.no_requests_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'friends.no_requests_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return NativeRefreshIndicator(
      onRefresh: () => friendsService.getFriendRequests(
            type: FriendRequestType.received.toJson(),
            forceRefresh: true,
          ),
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
              'friends.no_sent_requests_title'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'friends.no_sent_requests_subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return NativeRefreshIndicator(
      onRefresh: () => friendsService.getFriendRequests(
            type: FriendRequestType.sent.toJson(),
            forceRefresh: true,
          ),
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
          // Navigate to friend's profile page
          context.push('/profile/${friend.username}');
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
              onPressed: () => _respondToRequest(request, FriendRequestAction.decline.toJson()),
              icon: Icon(Icons.close, color: Colors.red.shade600),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _respondToRequest(request, FriendRequestAction.accept.toJson()),
              icon: Icon(Icons.check, color: Colors.green.shade600),
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.shade50,
              ),
            ),
          ],
        ),
        onTap: request.requesterUsername != null
            ? () => context.push('/profile/${request.requesterUsername}')
            : null,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _cancelSentRequest(request),
              icon: Icon(Icons.close, size: 18),
              color: Colors.red.shade600,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                padding: EdgeInsets.all(8),
                minimumSize: Size(32, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        onTap: request.addresseeUsername != null
            ? () => context.push('/profile/${request.addresseeUsername}')
            : null,
      ),
    );
  }
}
