import 'package:flutter/material.dart';
import 'dart:async';
import '../services/mock_data_service.dart';
import '../services/friends_service.dart';
import '../models/friend.dart';
import '../theme/app_theme.dart';
import '../widgets/cached_image.dart';
import '../common/navigation/native_page_route.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  List<UserSearchResult> _userSearchResults = [];
  bool _isSearching = false;
  bool _isLoadingUsers = false;
  String _searchType = 'discover'; // 'discover' or 'people'
  Timer? _searchDebouncer;
  late TabController _tabController;

  final FriendsService _friendsService = FriendsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    setState(() {
      _suggestions = MockDataService.getMockSuggestions();
    });
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

    if (_searchType == 'people' && query.length >= 2) {
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
            backgroundColor: Colors.red.shade600,
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
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _searchType = index == 0 ? 'discover' : 'people';
              if (_searchController.text.isNotEmpty) {
                _onSearchChanged(_searchController.text);
              }
            });
          },
          tabs: const [
            Tab(text: 'Discover', icon: Icon(Icons.explore)),
            Tab(text: 'People', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: _searchType == 'people' 
                  ? 'Search for users by name or username...'
                  : 'Search for gifts, brands, or ideas...',
              leading: Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
              ],
              onChanged: _onSearchChanged,
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Discover tab
                _isSearching && _searchType == 'discover' 
                    ? _buildDiscoverSearchResults() 
                    : _buildDiscoverContent(),
                // People tab
                _buildPeopleContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text('Product search coming soon!'),
          SizedBox(height: 8),
          Text(
            'We\'re working on connecting to product databases',
            style: TextStyle(color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleContent() {
    if (!_isSearching || _searchType != 'people') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text('Find friends on HeyWish'),
            SizedBox(height: 8),
            Text(
              'Search for users by name or username',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_isLoadingUsers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching for users...'),
          ],
        ),
      );
    }

    if (_userSearchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text('No users found'),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _userSearchResults.length,
      itemBuilder: (context, index) {
        final user = _userSearchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserSearchResult user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CachedAvatarImage(
          imageUrl: user.avatarUrl,
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: _buildUserActionButton(user),
        onTap: () {
          // Navigate to user profile
          _showUserProfile(user);
        },
      ),
    );
  }

  Widget _buildUserActionButton(UserSearchResult user) {
    if (user.isFriend) {
      return Chip(
        label: Text('Friends'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
        ),
      );
    }

    if (user.hasPendingRequest) {
      if (user.requestSentByMe) {
        return Chip(
          label: Text('Pending'),
          backgroundColor: Colors.orange.shade100,
          labelStyle: TextStyle(
            color: Colors.orange.shade700,
            fontSize: 12,
          ),
        );
      } else {
        return Chip(
          label: Text('Respond'),
          backgroundColor: Colors.blue.shade100,
          labelStyle: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 12,
          ),
        );
      }
    }

    return ElevatedButton(
      onPressed: () => _sendFriendRequest(user),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size(0, 32),
      ),
      child: Text(
        'Add Friend',
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  void _showUserProfile(UserSearchResult user) {
    NativeTransitions.showNativeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      child: DraggableScrollableSheet(
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
                          imageUrl: user.avatarUrl,
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Text(
                            user.bio!,
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _buildUserActionButton(user),
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

  Widget _buildDiscoverContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          _buildCategoriesSection(),
          
          // Trending and suggestions
          ..._suggestions.map((section) => _buildSuggestionSection(section)),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Electronics', 'icon': Icons.devices, 'color': Theme.of(context).colorScheme.primary},
      {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.blue},
      {'name': 'Home & Garden', 'icon': Icons.home, 'color': Colors.blue},
      {'name': 'Books', 'icon': Icons.book, 'color': Colors.blue},
      {'name': 'Sports', 'icon': Icons.sports_tennis, 'color': Colors.blue},
      {'name': 'Beauty', 'icon': Icons.face, 'color': Theme.of(context).colorScheme.primary},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category['name']} category coming soon!')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'] as IconData,
              size: 32,
              color: category['color'] as Color,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: category['color'] as Color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection(Map<String, dynamic> section) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section['title'] as String,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View all coming soon!')),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (section['items'] as List).length,
              itemBuilder: (context, index) {
                final item = (section['items'] as List)[index];
                return _buildSuggestionCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> item) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: item['image'] != null
                  ? CachedImageWidget(
                      imageUrl: item['image'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: Icon(
                        Icons.image,
                        color: Colors.grey.shade300,
                      ),
                    )
                  : Icon(
                      Icons.image,
                      color: Colors.grey.shade300,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (item['price'] != null)
                      Text(
                        '\$${item['price']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (item['trend'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTrendColor(item['trend']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['trend'].toString().toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getTrendColor(item['trend']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'viral':
        return Colors.blue;
      case 'popular':
        return Theme.of(context).colorScheme.primary;
      case 'rising':
        return Colors.blue;
      default:
        return Colors.grey.shade300;
    }
  }
}