import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/friends_service.dart';
import '../../services/auth_service.dart';
import '../../models/friendship_enums.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/navigation/native_page_route.dart';
import '../../widgets/cached_image.dart' show CachedAvatarImage, CachedImageWidget;
import '../../common/utils/wish_category_detector.dart';
import 'public_wishlist_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;

  const PublicProfileScreen({
    super.key,
    required this.username,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  List<dynamic> _wishlists = [];
  bool _isSendingRequest = false;
  bool _disposed = false; // Track if widget is disposed

  // Friendship status
  bool _isAlreadyFriend = false;
  bool _hasSentRequest = false;
  bool _hasReceivedRequest = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _disposed = true; // Mark as disposed to cancel async operations
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      if (_disposed || !mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _api.get('/public/users/${widget.username}');

      if (_disposed || !mounted) return;

      if (response == null) {
        if (_disposed || !mounted) return;
        setState(() {
          _error = 'errors.not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      if (_disposed || !mounted) return;

      setState(() {
        _userData = response['user'];
        _wishlists = response['wishlists'] ?? [];
        _isLoading = false;
      });

      // Check friendship status in background (non-blocking)
      // This allows the profile to render immediately while friends data loads
      if (!_disposed && mounted) {
        _checkFriendshipStatus();
      }
    } catch (error) {
      if (_disposed || !mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFriendshipStatus() async {
    if (_disposed || !mounted) return;

    final authService = context.read<AuthService>();
    final friendsService = context.read<FriendsService>();

    // Check if viewing own profile
    if (authService.currentUser?.username == widget.username) {
      if (_disposed || !mounted) return;
      setState(() {
        _isOwnProfile = true;
      });
      return;
    }

    // Get the user ID from the profile data
    if (_userData != null && _userData!['id'] != null) {
      final userId = _userData!['id'];

      // IMPORTANT: Reload friends data from server to get latest status
      // This ensures we have up-to-date friendship information
      await friendsService.loadAllData(forceRefresh: true);

      if (_disposed || !mounted) return;

      // Check if already friends
      _isAlreadyFriend = friendsService.friends.any((friend) => friend.id == userId);

      // Check if there's a sent request
      _hasSentRequest = friendsService.sentRequests.any(
        (request) => request.addresseeId == userId && request.isPending,
      );

      // Check if there's a received request
      _hasReceivedRequest = friendsService.friendRequests.any(
        (request) => request.requesterId == userId && request.isPending,
      );

      if (_disposed || !mounted) return;

      setState(() {});
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_disposed || !mounted) return;
    if (_userData == null || _userData!['id'] == null) return;

    // Check if user is anonymous
    final authService = context.read<AuthService>();
    if (authService.firebaseUser?.isAnonymous == true) {
      _showCreateAccountPrompt();
      return;
    }

    if (_disposed || !mounted) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.sendFriendRequest(_userData!['id']);

      if (_disposed || !mounted) return;

      // Refresh friendship status
      await friendsService.getFriendRequests(
        type: FriendRequestType.sent.toJson(),
        forceRefresh: true,
      );

      if (_disposed || !mounted) return;

      await _checkFriendshipStatus();

      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_sent'.tr(namedArgs: {'name': _userData!['username'] ?? 'User'})),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (error) {
      if (_disposed || !mounted) {
        // Still need to reset state even on error
        if (mounted && !_disposed) {
          setState(() {
            _isSendingRequest = false;
          });
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.error_sending_request'.tr()),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted && !_disposed) {
        setState(() {
          _isSendingRequest = false;
        });
      }
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
    if (_disposed || !mounted) return;

    try {
      final authService = context.read<AuthService>();
      await authService.linkWithGoogle();

      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.account_created_success'.tr()),
          backgroundColor: Colors.green.shade600,
        ),
      );

      // Refresh the profile to update friendship status
      await _loadProfile();
    } catch (error) {
      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'auth.error_creating_account'.tr()}: ${error.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _linkWithApple() async {
    if (_disposed || !mounted) return;

    try {
      final authService = context.read<AuthService>();
      await authService.linkWithApple();

      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.account_created_success'.tr()),
          backgroundColor: Colors.green.shade600,
        ),
      );

      // Refresh the profile to update friendship status
      await _loadProfile();
    } catch (error) {
      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'auth.error_creating_account'.tr()}: ${error.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _cancelFriendRequest() async {
    if (_disposed || !mounted) return;
    if (_userData == null || _userData!['id'] == null) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.cancelFriendRequest(_userData!['id']);

      if (_disposed || !mounted) return;

      // Refresh friendship status
      await _checkFriendshipStatus();

      if (_disposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('friends.request_cancelled'.tr()),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    } catch (error) {
      if (!(_disposed || !mounted)) {
        // If the request doesn't exist or was already processed,
        // just refresh the status instead of showing an error
        final errorMessage = error.toString().toLowerCase();
        if (errorMessage.contains('not found') || errorMessage.contains('already processed')) {
          // Silently refresh the friendship status
          await _checkFriendshipStatus();
        } else {
          // Show error for other types of failures
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('friends.error_cancelling_request'.tr()),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    } finally {
      if (mounted && !_disposed) {
        setState(() {
          _isSendingRequest = false;
        });
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
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        // Let Flutter/GoRouter handle back navigation automatically
        // Custom back handlers cause Navigator state corruption with IndexedStack + GoRouter
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SkeletonLoading(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          const SizedBox(height: 16),
          const SkeletonText(width: 150, height: 24),
          const SizedBox(height: 8),
          const SkeletonText(width: 100, height: 16),
          const SizedBox(height: 32),
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonLoading(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'errors.unknown'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: Text('app.retry'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_userData == null) return const SizedBox.shrink();

    final fullName = _userData!['full_name'];
    final avatarUrl = _userData!['avatar_url'];
    final bio = _userData!['bio'];

    // Calculate total wishes count
    int totalWishesCount = 0;
    for (final wishlist in _wishlists) {
      final items = wishlist['items'] as List?;
      totalWishesCount += items?.length ?? 0;
    }

    return NativeRefreshIndicator(
      onRefresh: _loadProfile,
      child: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and user info section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CachedAvatarImage(
                        imageUrl: avatarUrl,
                        radius: 48,
                        backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 20),
                      // Name, username, bio, and stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            // Name
                            if (fullName != null)
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                            const SizedBox(height: 6),
                            // Username
                            Text(
                              '@${widget.username}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8E8E93),
                                height: 1.3,
                              ),
                            ),
                            // Bio
                            if (bio != null && bio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                bio,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            // Stats section
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                // Wishlists count
                                Row(
                                  children: [
                                    Icon(
                                      Icons.card_giftcard_outlined,
                                      size: 18,
                                      color: AppTheme.primaryAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_wishlists.length}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _wishlists.length == 1 ? 'wishlist' : 'wishlists',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                // Wishes count
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite_outline,
                                      size: 18,
                                      color: Colors.pinkAccent.shade100,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$totalWishesCount',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      totalWishesCount == 1 ? 'wish' : 'wishes',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Friend request button
                  if (!_isOwnProfile) ...[
                    const SizedBox(height: 24),
                    _buildFriendButton(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Wishlists
          if (_wishlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.card_giftcard_outlined,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No public wishlists yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask @${widget.username} to share a list',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: _wishlists.length,
                itemBuilder: (context, index) {
                  final wishlist = _wishlists[index];
                  return _buildWishlistCard(wishlist);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    if (_isAlreadyFriend) {
      // Already friends
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.grey.shade100,
            disabledForegroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'friends.status_friends'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasSentRequest) {
      // We sent them a request - show cancel button
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: _isSendingRequest ? null : _cancelFriendRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange.shade700,
            side: BorderSide(color: Colors.orange.shade300, width: 1.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSendingRequest
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade700,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'friends.cancel_request'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }

    if (_hasReceivedRequest) {
      // They sent us a request - show button to accept
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to friends screen where they can accept/decline
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('profile.check_friend_requests'.tr()),
                backgroundColor: AppTheme.primaryAccent,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 18),
              const SizedBox(width: 8),
              Text(
                'profile.respond_to_request'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Can send friend request
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSendingRequest ? null : _sendFriendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E5EA),
          disabledForegroundColor: const Color(0xFF8E8E93),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSendingRequest
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'friends.add_friend'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] ?? 'wishlist.title'.tr();
    final wishlistId = wishlist['id'];
    final items = wishlist['items'] as List?;
    final itemCount = items?.length ?? 0;

    // Collect up to 4 images from items
    final List<String> imageUrls = [];
    final List<String> itemTitles = [];

    if (items != null && items.isNotEmpty) {
      for (var i = 0; i < items.length && imageUrls.length < 4; i++) {
        final item = items[i];
        itemTitles.add(item['title'] ?? '');
        final images = item['images'];
        if (images != null) {
          if (images is List && images.isNotEmpty) {
            imageUrls.add(images[0]);
          } else if (images is String && images.isNotEmpty) {
            imageUrls.add(images);
          }
        }
      }
    }

    return GestureDetector(
      onTap: () {
        // Navigate to wishlist detail using Navigator (not GoRouter) from profile screen
        if (wishlistId != null) {
          Navigator.of(context).push(
            NativePageRoute(
              child: PublicWishlistDetailScreen(
                username: widget.username,
                wishlistId: wishlistId,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamic cover image grid
            _WishlistCoverGrid(
              imageUrls: imageUrls,
              itemTitles: itemTitles,
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wishlist name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Item count
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic cover grid widget for wishlist cards
/// Shows 1-4 images in different grid layouts
class _WishlistCoverGrid extends StatelessWidget {
  final List<String> imageUrls;
  final List<String> itemTitles;

  const _WishlistCoverGrid({
    required this.imageUrls,
    required this.itemTitles,
  });

  @override
  Widget build(BuildContext context) {
    final imageCount = imageUrls.length;

    if (imageCount == 0) {
      // No images - show fallback icon
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Center(
            child: Icon(
              itemTitles.isNotEmpty
                  ? WishCategoryDetector.getIconFromTitle(itemTitles[0])
                  : Icons.card_giftcard_outlined,
              size: 48,
              color: itemTitles.isNotEmpty
                  ? WishCategoryDetector.getColorFromTitle(itemTitles[0])
                  : AppTheme.primaryAccent,
            ),
          ),
        ),
      );
    }

    if (imageCount == 1) {
      // Single image - full size
      return AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: CachedImageWidget(
            imageUrl: imageUrls[0],
            fit: BoxFit.cover,
            width: double.infinity,
            errorWidget: _buildFallbackIcon(0),
          ),
        ),
      );
    }

    if (imageCount == 2) {
      // Two images - side by side
      return AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: CachedImageWidget(
                  imageUrl: imageUrls[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorWidget: _buildFallbackIcon(0),
                ),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: CachedImageWidget(
                  imageUrl: imageUrls[1],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorWidget: _buildFallbackIcon(1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageCount == 3) {
      // Three images - one full-height on left, two stacked on right
      return AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Row(
            children: [
              // Left side - full height image
              Expanded(
                child: CachedImageWidget(
                  imageUrl: imageUrls[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorWidget: _buildFallbackIcon(0),
                ),
              ),
              const SizedBox(width: 1),
              // Right side - two stacked images
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CachedImageWidget(
                        imageUrl: imageUrls[1],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: _buildFallbackIcon(1),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Expanded(
                      child: CachedImageWidget(
                        imageUrl: imageUrls[2],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: _buildFallbackIcon(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4+ images - 2x2 grid (capped at 4)
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Column(
          children: [
            // Top row
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CachedImageWidget(
                      imageUrl: imageUrls[0],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorWidget: _buildFallbackIcon(0),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: CachedImageWidget(
                      imageUrl: imageUrls[1],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorWidget: _buildFallbackIcon(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // Bottom row
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CachedImageWidget(
                      imageUrl: imageUrls[2],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorWidget: _buildFallbackIcon(2),
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: CachedImageWidget(
                      imageUrl: imageUrls[3],
                      fit: BoxFit.cover,
                      height: double.infinity,
                      errorWidget: _buildFallbackIcon(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(int index) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          index < itemTitles.length
              ? WishCategoryDetector.getIconFromTitle(itemTitles[index])
              : Icons.card_giftcard_outlined,
          size: 32,
          color: index < itemTitles.length
              ? WishCategoryDetector.getColorFromTitle(itemTitles[index])
              : AppTheme.primaryAccent,
        ),
      ),
    );
  }
}
