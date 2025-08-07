import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService? authService;
  final ApiService? apiService;

  const DashboardScreen({
    super.key,
    this.authService,
    this.apiService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthService _authService;
  late final ApiService _apiService;
  List<dynamic> _wishlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _apiService = widget.apiService ?? ApiService(_authService);
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    try {
      final wishlists = await _apiService.getWishlists();
      setState(() {
        _wishlists = wishlists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load wishlists'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sign out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlists,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          '${_wishlists.length}',
                          'Wishlists',
                          Icons.list_alt,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          '${_getTotalItems()}',
                          'Total Items',
                          Icons.card_giftcard,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            Icons.add,
                            'Create Wishlist',
                            () {
                              Navigator.pushNamed(context, '/wishlists');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            Icons.share,
                            'Share',
                            () {
                              // TODO: Implement share
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Wishlists
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Wishlists',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/wishlists');
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (_wishlists.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No wishlists yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/wishlists');
                              },
                              child: const Text('Create Your First Wishlist'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _wishlists.length,
                        itemBuilder: (context, index) {
                          final wishlist = _wishlists[index];
                          return _buildWishlistCard(wishlist);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final itemCount = (wishlist['wishes'] as List?)?.length ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.card_giftcard,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          wishlist['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$itemCount items'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wishlist['is_public'] == true)
              const Icon(Icons.public, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/wishlist/${wishlist['id']}');
        },
      ),
    );
  }

  int _getTotalItems() {
    int total = 0;
    for (var wishlist in _wishlists) {
      total += ((wishlist['wishes'] as List?)?.length ?? 0);
    }
    return total;
  }
}