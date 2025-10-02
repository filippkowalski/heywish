import 'package:flutter/material.dart';
import 'dart:async';
import '../services/friends_service.dart';
import '../models/friend.dart';
import '../theme/app_theme.dart';
import '../widgets/cached_image.dart';
import '../common/navigation/native_page_route.dart';

class SearchScreen extends StatefulWidget {
  final int initialTabIndex;

  const SearchScreen({
    super.key,
    this.initialTabIndex = 1, // Default to People tab
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserSearchResult> _userSearchResults = [];
  bool _isSearching = false;
  bool _isLoadingUsers = false;
  Timer? _searchDebouncer;

  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _userSearchResults.clear();
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
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final results = await _friendsService.searchUsers(query);
      setState(() {
        _userSearchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _sendFriendRequest(UserSearchResult user) async {
    try {
      await _friendsService.sendFriendRequest(user.id);

      // Update the user in the results list
      setState(() {
        final index = _userSearchResults.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _userSearchResults[index] = UserSearchResult(
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.displayName}'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Find Friends',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: false,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search by username or name...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.primaryAccent,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryAccent,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Empty state - no search yet
    if (!_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: 80,
                color: AppTheme.primaryAccent.withOpacity(0.3),
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
                'Search for friends by their username or name to connect and see their wishlists',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isLoadingUsers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryAccent,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Searching...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    // No results
    if (_userSearchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Results list
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _userSearchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _userSearchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserSearchResult user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserProfile(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CachedAvatarImage(
                  imageUrl: user.avatarUrl,
                  radius: 28,
                  backgroundColor: AppTheme.primaryAccent.withOpacity(0.1),
                ),
                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action button
                _buildUserActionButton(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserActionButton(UserSearchResult user) {
    if (user.isFriend) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.shade200,
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
              'Friends',
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
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
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
        );
      } else {
        return OutlinedButton(
          onPressed: () => _showUserProfile(user),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryAccent,
            side: BorderSide(color: AppTheme.primaryAccent),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Respond',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      }
    }

    return OutlinedButton.icon(
      onPressed: () => _sendFriendRequest(user),
      icon: Icon(Icons.person_add, size: 16),
      label: Text(
        'Add',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryAccent,
        side: BorderSide(color: AppTheme.primaryAccent),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showUserProfile(UserSearchResult user) {
    NativeTransitions.showNativeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
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
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        // Avatar
                        CachedAvatarImage(
                          imageUrl: user.avatarUrl,
                          radius: 48,
                          backgroundColor: AppTheme.primaryAccent.withOpacity(0.1),
                        ),
                        SizedBox(height: 20),

                        // Name
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 4),

                        // Username
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),

                        // Bio
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          SizedBox(height: 20),
                          Text(
                            user.bio!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        SizedBox(height: 32),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: _buildProfileActionButton(user),
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

  Widget _buildProfileActionButton(UserSearchResult user) {
    if (user.isFriend) {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.check_circle_outline),
        label: Text('Already Friends'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade300),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (user.hasPendingRequest && user.requestSentByMe) {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(Icons.schedule),
        label: Text('Request Pending'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade300),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () {
        Navigator.pop(context);
        _sendFriendRequest(user);
      },
      icon: Icon(Icons.person_add),
      label: Text('Add Friend'),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
