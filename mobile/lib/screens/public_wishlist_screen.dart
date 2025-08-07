import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/public_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicWishlistScreen extends StatefulWidget {
  final String shareToken;

  const PublicWishlistScreen({
    super.key,
    required this.shareToken,
  });

  @override
  State<PublicWishlistScreen> createState() => _PublicWishlistScreenState();
}

class _PublicWishlistScreenState extends State<PublicWishlistScreen> {
  final _publicApiService = PublicApiService();
  Map<String, dynamic>? _wishlist;
  List<dynamic> _wishes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _publicApiService.getPublicWishlist(widget.shareToken);
      
      setState(() {
        _wishlist = data['wishlist'];
        _wishes = data['wishes'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load wishlist';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReserve(Map<String, dynamic> wish) async {
    if (wish['is_reserved']) {
      if (_publicApiService.isReservedByMe(wish)) {
        // Unreserve
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unreserve Item'),
            content: const Text('Are you sure you want to unreserve this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Unreserve'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await _publicApiService.unreserveItem(widget.shareToken, wish['id']);
            _loadWishlist();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item unreserved'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to unreserve item'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        // Already reserved by someone else
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This item is already reserved by someone else'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Show reservation dialog
      String? reserverName;
      String? reserverEmail;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Reserve "${wish['title']}"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Let ${_wishlist?['owner_name'] ?? 'the owner'} know who reserved this (optional):'),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Your Name (optional)',
                      hintText: 'Anonymous',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => reserverName = value,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Your Email (optional)',
                      hintText: 'For updates',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => reserverEmail = value,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reserve'),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed == true) {
        try {
          await _publicApiService.reserveItem(
            widget.shareToken,
            wish['id'],
            reserverName: reserverName,
            reserverEmail: reserverEmail,
          );
          _loadWishlist();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item reserved successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to reserve item'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  void _shareWishlist() {
    final url = 'https://heywish.app/w/${widget.shareToken}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWishlist,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_wishlist == null) {
      return Scaffold(
        body: const Center(
          child: Text('Wishlist not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_wishlist!['title'] ?? 'Wishlist'),
              background: Container(
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_wishlist!['description'] != null)
                          Text(
                            _wishlist!['description'],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'By ${_wishlist!['owner_name']} • ${_wishlist!['items_count']} items • ${_wishlist!['reserved_count']} reserved',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 50), // Space for title
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareWishlist,
              ),
            ],
          ),

          // Instructions
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap any item to reserve it for ${_wishlist!['owner_name']}. Only you will know what you reserved!',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wishes Grid
          if (_wishes.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No items in this wishlist yet'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final wish = _wishes[index];
                    final isReserved = wish['is_reserved'] == true;
                    final isMyReservation = _publicApiService.isReservedByMe(wish);

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _handleReserve(wish),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(
                              flex: 3,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (wish['image_url'] != null)
                                    Image.network(
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
                                    )
                                  else
                                    Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.card_giftcard,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (isReserved)
                                    Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isMyReservation
                                                ? 'Reserved by you'
                                                : 'Reserved',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Details
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wish['title'] ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
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
                                    if (wish['url'] != null)
                                      InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse(wish['url']);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode: LaunchMode.externalApplication,
                                            );
                                          }
                                        },
                                        child: const Text(
                                          'View item →',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
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
                  },
                  childCount: _wishes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}