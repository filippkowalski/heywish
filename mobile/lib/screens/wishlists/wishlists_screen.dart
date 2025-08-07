import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _authService = AuthService();
  late final ApiService _apiService;
  List<dynamic> _wishlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authService);
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

  void _showCreateWishlistDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Wishlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Birthday Wishlist',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Things I want for my birthday',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Make Public'),
                  subtitle: const Text('Anyone with the link can view'),
                  value: isPublic,
                  onChanged: (value) {
                    setDialogState(() {
                      isPublic = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a title'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  await _apiService.createWishlist({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'is_public': isPublic,
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _loadWishlists();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wishlist created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create wishlist'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWishlist(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wishlist'),
        content: const Text('Are you sure you want to delete this wishlist? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteWishlist(id);
        _loadWishlists();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wishlist deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete wishlist'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _shareWishlist(Map<String, dynamic> wishlist) {
    final shareUrl = 'https://heywish.app/w/${wishlist['share_token']}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Wishlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this link with friends and family:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                shareUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement share functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlists'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWishlistDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlists,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _wishlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No wishlists yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first wishlist to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showCreateWishlistDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Wishlist'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wishlists.length,
                    itemBuilder: (context, index) {
                      final wishlist = _wishlists[index];
                      final itemCount = (wishlist['wishes'] as List?)?.length ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/wishlist/${wishlist['id']}');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            wishlist['title'] ?? 'Untitled',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (wishlist['description'] != null &&
                                              wishlist['description'].isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              wishlist['description'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        if (wishlist['is_public'] == true)
                                          const PopupMenuItem(
                                            value: 'share',
                                            child: Row(
                                              children: [
                                                Icon(Icons.share, size: 20),
                                                SizedBox(width: 8),
                                                Text('Share'),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            // TODO: Implement edit
                                            break;
                                          case 'share':
                                            _shareWishlist(wishlist);
                                            break;
                                          case 'delete':
                                            _deleteWishlist(wishlist['id']);
                                            break;
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$itemCount items',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      wishlist['is_public'] == true
                                          ? Icons.public
                                          : Icons.lock,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      wishlist['is_public'] == true ? 'Public' : 'Private',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}