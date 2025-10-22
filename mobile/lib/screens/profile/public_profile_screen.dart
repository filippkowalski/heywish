import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/friends_service.dart';
import '../../services/auth_service.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../widgets/cached_image.dart' show CachedAvatarImage, CachedImageWidget;

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

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _api.get('/public/users/${widget.username}');

      if (response == null) {
        setState(() {
          _error = 'errors.not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userData = response['user'];
        _wishlists = response['wishlists'] ?? [];
        _isLoading = false;
      });

      // Check friendship status after profile is loaded
      await _checkFriendshipStatus();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFriendshipStatus() async {
    final authService = context.read<AuthService>();
    final friendsService = context.read<FriendsService>();

    // Check if viewing own profile
    if (authService.currentUser?.username == widget.username) {
      setState(() {
        _isOwnProfile = true;
      });
      return;
    }

    // Get the user ID from the profile data
    if (_userData != null && _userData!['id'] != null) {
      final userId = _userData!['id'];

      // Check if already friends
      _isAlreadyFriend = friendsService.friends.any((friend) => friend.id == userId);

      // Check if there's a sent request
      _hasSentRequest = friendsService.sentRequests.any(
        (request) => request.addresseeId == userId && request.status == 'pending',
      );

      // Check if there's a received request
      _hasReceivedRequest = friendsService.friendRequests.any(
        (request) => request.requesterId == userId && request.status == 'pending',
      );

      setState(() {});
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_userData == null || _userData!['id'] == null) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.sendFriendRequest(_userData!['id']);

      // Refresh friendship status
      await friendsService.getFriendRequests(type: 'sent');
      await _checkFriendshipStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.request_sent'.tr(namedArgs: {'name': _userData!['username'] ?? 'User'})),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.error_sending_request'.tr()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  Future<void> _cancelFriendRequest() async {
    if (_userData == null || _userData!['id'] == null) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      final friendsService = context.read<FriendsService>();
      await friendsService.cancelFriendRequest(_userData!['id']);

      // Refresh friendship status
      await friendsService.getFriendRequests(type: 'sent');
      await _checkFriendshipStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.request_cancelled'.tr()),
            backgroundColor: Colors.orange.shade600,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friends.error_cancelling_request'.tr()),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primary,
          ),
          onPressed: () => context.pop(),
        ),
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

    return NativeRefreshIndicator(
      onRefresh: _loadProfile,
      child: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  // Avatar
                  CachedAvatarImage(
                    imageUrl: avatarUrl,
                    radius: 40,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  if (fullName != null)
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 4),
                  // Username
                  Text(
                    '@${widget.username}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  // Bio
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      bio,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Friend request button
                  if (!_isOwnProfile) ...[
                    const SizedBox(height: 24),
                    _buildFriendButton(),
                  ],
                ],
              ),
            ),
          ),

          // Wishlists section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                'wishlist.wishlists'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
              ),
            ),
          ),

          // Wishlists
          if (_wishlists.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'home.empty_title'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final wishlist = _wishlists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildWishlistCard(wishlist),
                    );
                  },
                  childCount: _wishlists.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendButton() {
    if (_isAlreadyFriend) {
      // Already friends
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 18,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Friends',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_hasSentRequest) {
      // We sent them a request - show cancel button
      return OutlinedButton.icon(
        onPressed: _isSendingRequest ? null : _cancelFriendRequest,
        icon: _isSendingRequest
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange.shade700,
                ),
              )
            : const Icon(Icons.close, size: 18),
        label: Text(_isSendingRequest ? 'Cancelling...' : 'friends.cancel_request'.tr()),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (_hasReceivedRequest) {
      // They sent us a request - show button to accept
      return FilledButton.icon(
        onPressed: () {
          // Navigate to friends screen where they can accept/decline
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your friend requests in the Friends tab'),
            ),
          );
        },
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Respond to Request'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryAccent,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Can send friend request
    return FilledButton.icon(
      onPressed: _isSendingRequest ? null : _sendFriendRequest,
      icon: _isSendingRequest
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.person_add, size: 18),
      label: Text(_isSendingRequest ? 'Sending...' : 'friends.add_friend'.tr()),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryAccent,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] ?? 'wishlist.title'.tr();
    final wishlistId = wishlist['id'];
    final items = wishlist['items'] as List?;
    final itemCount = items?.length ?? 0;

    // Get first 3 item images for preview
    final imageUrls = <String>[];
    if (items != null) {
      for (final item in items.take(3)) {
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

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Navigate to wishlist detail
          if (wishlistId != null) {
            context.push('/profile/${widget.username}/wishlist/$wishlistId');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
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
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: Row(
                    children: imageUrls
                        .take(3)
                        .map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CachedImageWidget(
                              imageUrl: url,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
