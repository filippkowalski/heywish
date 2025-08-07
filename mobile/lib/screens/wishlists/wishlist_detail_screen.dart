import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class WishlistDetailScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailScreen({
    super.key,
    required this.wishlistId,
  });

  @override
  State<WishlistDetailScreen> createState() => _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends State<WishlistDetailScreen> {
  final _authService = AuthService();
  late final ApiService _apiService;
  Map<String, dynamic>? _wishlist;
  bool _isLoading = true;
  bool _isAddingItem = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authService);
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      final wishlist = await _apiService.getWishlist(widget.wishlistId);
      setState(() {
        _wishlist = wishlist;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load wishlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String? imageUrl;
    bool isScraping = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'Product URL',
                    hintText: 'https://example.com/product',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: isScraping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      onPressed: isScraping
                          ? null
                          : () async {
                              if (urlController.text.isEmpty) return;
                              
                              setDialogState(() {
                                isScraping = true;
                              });

                              try {
                                final product = await _apiService.scrapeProduct(
                                  urlController.text,
                                );
                                
                                setDialogState(() {
                                  titleController.text = product['title'] ?? '';
                                  imageUrl = product['image'];
                                  if (product['price'] != null) {
                                    priceController.text = product['price'].toString();
                                  }
                                  isScraping = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  isScraping = false;
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to fetch product details'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (imageUrl != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Item Title *',
                    hintText: 'Product name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: '29.99',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Size, color, preferences...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
              onPressed: _isAddingItem
                  ? null
                  : () async {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an item title'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        _isAddingItem = true;
                      });

                      try {
                        double? price;
                        if (priceController.text.isNotEmpty) {
                          price = double.tryParse(priceController.text);
                        }

                        await _apiService.addWish({
                          'wishlist_id': widget.wishlistId,
                          'title': titleController.text,
                          'url': urlController.text.isNotEmpty ? urlController.text : null,
                          'price': price,
                          'image_url': imageUrl,
                          'notes': notesController.text.isNotEmpty ? notesController.text : null,
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _loadWishlist();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          _isAddingItem = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add item'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: _isAddingItem
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to remove this item from your wishlist?'),
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
        await _apiService.deleteWish(itemId);
        _loadWishlist();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete item'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_wishlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Wishlist not found'),
        ),
      );
    }

    final wishes = _wishlist!['wishes'] as List? ?? [];
    final currentUserId = _authService.currentUser?.uid;
    final isOwner = _wishlist!['user_id'] == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlist!['title'] ?? 'Wishlist'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Implement share
              },
            ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadWishlist,
        child: wishes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No items yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwner 
                        ? 'Add your first item to this wishlist'
                        : 'This wishlist is empty',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: wishes.length,
                itemBuilder: (context, index) {
                  final wish = wishes[index];
                  final isReserved = wish['reserved_by'] != null;
                  final isReservedByMe = wish['reserved_by'] == currentUserId;

                  return Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        if (wish['url'] != null) {
                          // TODO: Open URL
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wish['image_url'] != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  wish['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.card_giftcard,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wish['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (wish['price'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${wish['price']}',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (!isOwner)
                                    SizedBox(
                                      width: double.infinity,
                                      child: isReserved
                                          ? isReservedByMe
                                              ? OutlinedButton(
                                                  onPressed: () async {
                                                    try {
                                                      await _apiService.unreserveWish(wish['id']);
                                                      _loadWishlist();
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Failed to unreserve'),
                                                            backgroundColor: Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  child: const Text(
                                                    'Unreserve',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'Reserved',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                          : ElevatedButton(
                                              onPressed: () async {
                                                try {
                                                  await _apiService.reserveWish(wish['id']);
                                                  _loadWishlist();
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Item reserved!'),
                                                        backgroundColor: Colors.green,
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Failed to reserve'),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                'Reserve',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                    )
                                  else if (isOwner)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (isReserved)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Reserved',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                              ),
                                            ),
                                          )
                                        else
                                          const SizedBox(),
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _deleteItem(wish['id']),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}