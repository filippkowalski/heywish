import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/preferences_service.dart';
import '../../models/wishlist.dart';
import '../../models/wish.dart';
import '../../theme/app_theme.dart';
import '../../common/widgets/native_refresh_indicator.dart';
import '../../common/widgets/masonry_wish_card.dart';
import '../../common/navigation/native_page_route.dart';
import '../../utils/string_utils.dart';
import 'add_wish_screen.dart';
import 'edit_wishlist_screen.dart';
import 'wish_detail_screen.dart';

Future<void> _launchExternalLink(BuildContext context, String rawUrl) async {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return;
  }

  final normalized = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(normalized);
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (uri == null) {
    debugPrint('❌ Invalid URL provided for launch: $rawUrl');
    messenger?.showSnackBar(
      SnackBar(content: Text('wish.could_not_open_url'.tr())),
    );
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      messenger?.showSnackBar(
        SnackBar(content: Text('wish.could_not_open_url'.tr())),
      );
    }
  } catch (error) {
    debugPrint('❌ Failed to open link $uri: $error');
    messenger?.showSnackBar(
      SnackBar(content: Text('wish.could_not_open_url'.tr())),
    );
  }
}

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen>
    with SingleTickerProviderStateMixin {
  bool _hasLoadedOnce = false;
  bool _hasCompletedInitialLoad = false;
  String? _selectedWishlistFilter;
  bool _isShareBannerDismissed = false;
  static const String _shareBannerDismissedKey = 'share_banner_dismissed';
  DateTime? _lastCheckedMergeTimestamp;

  // FAB visibility
  bool _isFabVisible = true;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    _loadShareBannerState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlists();
    });
  }

  void _onScroll() {
    if (_scrollController == null) return;

    // Show FAB when scrolling up, hide when scrolling down
    if (_scrollController!.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (_scrollController!.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }

  Future<void> _loadShareBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShareBannerDismissed =
          prefs.getBool(_shareBannerDismissedKey) ?? false;
    });
  }

  Future<void> _dismissShareBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareBannerDismissedKey, true);
    setState(() {
      _isShareBannerDismissed = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use read() instead of watch() to avoid creating a dependency loop
    // didChangeDependencies is already triggered by dependencies, so we don't need watch here
    final authService = context.read<AuthService>();

    // Check if merge just completed - force reload regardless of _hasLoadedOnce
    if (authService.lastMergeTimestamp != null &&
        (_lastCheckedMergeTimestamp == null ||
            authService.lastMergeTimestamp!
                .isAfter(_lastCheckedMergeTimestamp!))) {
      debugPrint('🔄 WishlistsScreen: Merge detected, forcing data reload');
      _lastCheckedMergeTimestamp = authService.lastMergeTimestamp;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWishlists();
      });
      return;
    }

    // Try loading wishlists when authentication state changes, but only once
    if (authService.isAuthenticated &&
        authService.currentUser != null &&
        !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWishlists();
      });
    }
  }

  Future<void> _loadWishlists() async {
    debugPrint('🔄 WishlistsScreen: Loading wishlists...');
    final wishlistService = context.read<WishlistService>();
    final authService = context.read<AuthService>();

    try {
      // Wait for authentication and user sync to complete first
      if (!authService.isAuthenticated || authService.currentUser == null) {
        debugPrint(
          '⏳ WishlistsScreen: Waiting for authentication and user sync...',
        );
        return;
      }

      await wishlistService.fetchWishlists();
      debugPrint('✅ WishlistsScreen: Wishlists loaded successfully');
    } catch (e) {
      debugPrint('❌ WishlistsScreen: Failed to load wishlists: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasCompletedInitialLoad = true;
        });
      }
    }
  }

  /// Calculate total valuation for a list of wishes
  Map<String, dynamic> _calculateTotalValuation(List<Wish> wishes) {
    if (wishes.isEmpty) {
      return {'total': 0.0, 'currency': 'USD', 'hasAnyPrices': false};
    }

    // Group wishes by currency and calculate totals
    final Map<String, double> currencyTotals = {};
    bool hasAnyPrices = false;

    for (final wish in wishes) {
      if (wish.price != null && wish.price! > 0) {
        hasAnyPrices = true;
        final currency = wish.currency ?? 'USD';
        final totalPrice = wish.price! * wish.quantity;
        currencyTotals[currency] =
            (currencyTotals[currency] ?? 0.0) + totalPrice;
      }
    }

    if (!hasAnyPrices) {
      return {'total': 0.0, 'currency': 'USD', 'hasAnyPrices': false};
    }

    // For now, use the most common currency or USD as default
    final primaryCurrency = currencyTotals.keys.first;
    final total = currencyTotals[primaryCurrency] ?? 0.0;

    return {
      'total': total,
      'currency': primaryCurrency,
      'hasAnyPrices': true,
      'currencyTotals': currencyTotals,
    };
  }

  /// Format currency value
  String _formatCurrency(double value, String currency) {
    final formatter = intl.NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: value % 1 == 0 ? 0 : 2,
    );
    return formatter.format(value);
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final wishlistService = context.watch<WishlistService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child:
              !_hasCompletedInitialLoad || wishlistService.isLoading
                  ? Column(
                    children: [
                      _buildHeader(context, authService),
                      Expanded(child: _buildLoadingShimmer()),
                    ],
                  )
                  : wishlistService.error != null
                  ? Column(
                    children: [
                      _buildHeader(context, authService),
                      Expanded(child: _buildErrorState(wishlistService.error!)),
                    ],
                  )
                  : (wishlistService.wishlists.isEmpty &&
                      wishlistService.allWishes.isEmpty)
                  ? Column(
                    children: [
                      _buildHeader(context, authService),
                      Expanded(child: _buildEmptyState(context)),
                    ],
                  )
                  : NestedScrollView(
                    controller: _scrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [
                        SliverToBoxAdapter(
                          child: _buildHeader(context, authService),
                        ),
                      ];
                    },
                    body: NativeRefreshIndicator(
                      onRefresh: () async {
                        final wishlistService = context.read<WishlistService>();
                        final authService = context.read<AuthService>();

                        if (authService.isAuthenticated &&
                            authService.currentUser != null) {
                          await wishlistService.fetchWishlists();
                        }
                      },
                      child: _buildContent(wishlistService.wishlists),
                    ),
                  ),
        ),
      ),
      floatingActionButton:
          !_hasCompletedInitialLoad || wishlistService.isLoading
              ? null
              : AnimatedSlide(
                duration: const Duration(milliseconds: 200),
                offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isFabVisible ? 1.0 : 0.0,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final result = await AddWishScreen.show(
                        context,
                        source: 'homepage',
                      );
                      // Refresh if wish was added successfully
                      if (result == true && mounted) {
                        await _loadWishlists();
                      }
                    },
                    backgroundColor: AppTheme.primaryAccent,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthService authService) {
    final wishlistService = context.watch<WishlistService>();
    final hasAnyWishes = wishlistService.allWishes.isNotEmpty;
    final username = authService.currentUser?.username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap:
                  username != null
                      ? () => _launchExternalLink(
                        context,
                        'https://jinnie.co/$username',
                      )
                      : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.title'.tr(),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (username != null)
                    Text(
                      'jinnie.co/$username',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    )
                  else
                    Text(
                      'home.subtitle_create_share'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Share button - only show when user has at least one wish
          if (hasAnyWishes)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showShareBottomSheet(context),
                icon: const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'app.share'.tr(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(16.0),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image skeleton
              Container(
                height: index.isEven ? 180 : 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              // Content skeleton
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'errors.something_went_wrong'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadWishlists,
                icon: const Icon(Icons.refresh),
                label: Text('wish.try_again'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Wishlist> wishlists) {
    final wishlistService = context.watch<WishlistService>();
    final authService = context.watch<AuthService>();
    final allWishes = wishlistService.allWishes;
    final unsortedWishes = wishlistService.unsortedWishes;
    final filteredWishlists =
        wishlists.where((wishlist) => !wishlist.isSynthetic).toList();

    // Filter wishes by selected wishlist
    final filteredWishes =
        _selectedWishlistFilter == null
            ? allWishes
            : wishlistService.getWishesForWishlist(_selectedWishlistFilter);

    // Determine if we should show the share banner (3+ items)
    final shouldShowShareBanner = filteredWishes.length >= 3;

    // Get current user's username
    final username = authService.currentUser?.username;

    // Get selected wishlist for URL
    Wishlist? selectedWishlist;
    if (_selectedWishlistFilter != null) {
      try {
        selectedWishlist = filteredWishlists.firstWhere(
          (w) => w.id == _selectedWishlistFilter,
        );
      } catch (e) {
        selectedWishlist = null;
      }
    }

    return CustomScrollView(
      slivers: [
        // Share banner (show after 3+ items and if not dismissed)
        if (shouldShowShareBanner &&
            username != null &&
            !_isShareBannerDismissed)
          SliverToBoxAdapter(
            child: _ShareBanner(
              username: username,
              wishlistName: selectedWishlist?.name,
              onShareTap: () => _showShareBottomSheet(context),
              onDismiss: _dismissShareBanner,
            ),
          ),

        // Tabs for filtering by wishlist
        if (filteredWishlists.isNotEmpty || unsortedWishes.isNotEmpty)
          SliverToBoxAdapter(
            child:
                _buildWishlistTabs(filteredWishlists, unsortedWishes.length),
          ),

        // Show either wishes grid or empty state
        if (filteredWishes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyWishesStateContent(),
          )
        else ...[
          // Wishes masonry grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: filteredWishes.length,
              itemBuilder: (context, index) {
                final wish = filteredWishes[index];
                Wishlist? wishlist;
                if (wish.wishlistId != null) {
                  try {
                    wishlist = filteredWishlists.firstWhere(
                      (w) => w.id == wish.wishlistId,
                    );
                  } catch (e) {
                    wishlist = null;
                  }
                }
                return MasonryWishCard(
                  title: wish.title,
                  description: wish.description,
                  imageUrl: wish.imageUrl,
                  price: wish.price,
                  currency: wish.currency,
                  url: wish.url,
                  isReserved: wish.isReserved,
                  onTap: () async {
                    // Show wish detail bottom sheet
                    final wishlistId = wishlist?.id ?? 'unsorted';
                    final result = await WishDetailScreen.show(
                      context,
                      wishId: wish.id,
                      wishlistId: wishlistId,
                    );

                    // Refresh if item was deleted
                    if (result == true && context.mounted) {
                      // Small delay to ensure backend has processed the deletion
                      await Future.delayed(const Duration(milliseconds: 150));

                      if (context.mounted) {
                        // Trigger refresh via WishlistService
                        await context.read<WishlistService>().fetchWishlists();

                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('wish.item_deleted'.tr()),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          ),

          // Wishlist valuation at bottom of scrollable list
          if ((wishlists.isNotEmpty || unsortedWishes.isNotEmpty) &&
              filteredWishes.isNotEmpty)
            SliverToBoxAdapter(child: _buildWishlistValuation(filteredWishes)),

          // Extra padding at the bottom for better UX
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ],
    );
  }

  Widget _buildWishlistTabs(List<Wishlist> wishlists, int unsortedCount) {
    final wishlistService = context.watch<WishlistService>();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" tab (includes unsorted wishes)
          _buildTabChip(
            label: 'home.all_wishlists'.tr(),
            isSelected: _selectedWishlistFilter == null,
            onTap: () {
              setState(() {
                _selectedWishlistFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          // Wishlist tabs (filter out synthetic "All Wishes" wishlist)
          ...wishlists.where((w) => !w.isSynthetic).map((wishlist) {
            final wishCount =
                wishlistService.getWishesForWishlist(wishlist.id).length;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTabChip(
                label: wishlist.name,
                count: wishCount,
                isSelected: _selectedWishlistFilter == wishlist.id,
                onTap: () {
                  setState(() {
                    _selectedWishlistFilter = wishlist.id;
                  });
                },
                onLongPress: () {
                  if (wishlist.isSynthetic) {
                    return;
                  }
                  // Navigate to edit wishlist on long press
                  // Use Navigator (not GoRouter) from IndexedStack tab
                  Navigator.of(context).push(
                    NativePageRoute(
                      child: EditWishlistScreen(wishlistId: wishlist.id),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistValuation(List<Wish> wishes) {
    final preferencesService = context.watch<PreferencesService>();

    // Don't show if preference is disabled
    if (!preferencesService.showWishlistValuation) {
      return const SizedBox.shrink();
    }

    final valuation = _calculateTotalValuation(wishes);
    final hasAnyPrices = valuation['hasAnyPrices'] as bool;

    if (!hasAnyPrices) {
      return const SizedBox.shrink();
    }

    final total = valuation['total'] as double;
    final currency = valuation['currency'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: Text(
          '${'wishlist_valuation.total_value'.tr()}: ${_formatCurrency(total, currency)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWishesStateContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'home.no_items_yet'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedWishlistFilter == null
                  ? 'home.add_first_item'.tr()
                  : 'home.no_items_in_wishlist'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await AddWishScreen.show(
                  context,
                  source: 'homepage',
                );
                // Refresh if wish was added successfully
                if (result == true && mounted) {
                  await _loadWishlists();
                }
              },
              icon: const Icon(Icons.add),
              label: Text('wish.add_item'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      'home.empty_title'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'home.empty_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await AddWishScreen.show(
                          context,
                          source: 'homepage',
                        );
                        // Refresh if wish was added successfully
                        if (result == true && mounted) {
                          await _loadWishlists();
                        }
                      },
                      icon: Icon(Icons.add),
                      label: Text('home.create_first_wish'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    final authService = context.read<AuthService>();
    final wishlistService = context.read<WishlistService>();
    final username = authService.currentUser?.username;

    if (username == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _ShareBottomSheet(
            username: username,
            wishlists: wishlistService.wishlists,
          ),
    );
  }
}

// Share Banner Widget
class _ShareBanner extends StatelessWidget {
  final String username;
  final String? wishlistName;
  final VoidCallback onShareTap;
  final VoidCallback onDismiss;

  const _ShareBanner({
    required this.username,
    this.wishlistName,
    required this.onShareTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with emoji, title, and close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'wishlist.share_banner_title'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'wishlist.share_banner_cta'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Close button
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Share button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onShareTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.ios_share, size: 18),
              label: Text(
                'wishlist.share_now'.tr(),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Share Bottom Sheet Widget - Compact design
class _ShareBottomSheet extends StatefulWidget {
  final String username;
  final List<Wishlist> wishlists;

  const _ShareBottomSheet({required this.username, required this.wishlists});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final Map<String, bool> _updatingVisibility = {};
  static const String _hasSeenCopyExplanationKey = 'has_seen_copy_explanation';

  Future<void> _copyLinkToClipboard(String url) async {
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    await Clipboard.setData(ClipboardData(text: fullUrl));

    if (!mounted) return;

    // Check if user has seen the explanation
    final prefs = await SharedPreferences.getInstance();
    final hasSeenExplanation = prefs.getBool(_hasSeenCopyExplanationKey) ?? false;

    if (!hasSeenExplanation) {
      await prefs.setBool(_hasSeenCopyExplanationKey, true);
      if (mounted) {
        _showCopyExplanationBottomSheet();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('success.link_copied'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  void _showCopyExplanationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _CopyExplanationBottomSheet(),
    );
  }

  Future<void> _showVisibilitySelector(Wishlist wishlist) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _VisibilitySelectionBottomSheet(
        currentVisibility: wishlist.visibility,
      ),
    );

    if (result != null && result != wishlist.visibility && mounted) {
      await _updateVisibility(wishlist, result);
    }
  }

  Future<void> _updateVisibility(Wishlist wishlist, String newVisibility) async {
    setState(() {
      _updatingVisibility[wishlist.id] = true;
    });

    final wishlistService = context.read<WishlistService>();
    final success = await wishlistService.updateWishlist(
      wishlist.id,
      visibility: newVisibility,
    );

    if (mounted) {
      setState(() {
        _updatingVisibility[wishlist.id] = false;
      });

      if (success) {
        String message;
        if (newVisibility == 'public') {
          message = 'wishlist.wishlist_now_public'.tr();
        } else if (newVisibility == 'friends') {
          message = 'wishlist.wishlist_now_friends'.tr();
        } else {
          message = 'wishlist.wishlist_now_private'.tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileUrl = 'jinnie.co/${widget.username}';
    final nonSyntheticWishlists = widget.wishlists.where((w) => !w.isSynthetic).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header row with title and close
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'share.your_links'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),

            // Content - clean list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile row - featured
                    _ProfileLinkRow(
                      url: profileUrl,
                      onOpenLink: () => _launchExternalLink(context, 'https://$profileUrl'),
                      onCopyLink: () => _copyLinkToClipboard(profileUrl),
                    ),

                    // Wishlists
                    if (nonSyntheticWishlists.isNotEmpty) ...[
                      Divider(height: 1, color: Colors.grey.shade200),
                      ...nonSyntheticWishlists.map((wishlist) {
                        final wishlistUrl = 'jinnie.co/${widget.username}/${slugify(wishlist.name)}';
                        final isUpdating = _updatingVisibility[wishlist.id] ?? false;

                        return _WishlistLinkRow(
                          wishlist: wishlist,
                          url: wishlistUrl,
                          isUpdating: isUpdating,
                          onOpenLink: () => _launchExternalLink(context, 'https://$wishlistUrl'),
                          onCopyLink: () => _copyLinkToClipboard(wishlistUrl),
                          onChangeVisibility: () => _showVisibilitySelector(wishlist),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile link row - clean, native style
class _ProfileLinkRow extends StatelessWidget {
  final String url;
  final VoidCallback onOpenLink;
  final VoidCallback onCopyLink;

  const _ProfileLinkRow({
    required this.url,
    required this.onOpenLink,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'share.your_profile'.tr(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'share.profile_desc'.tr(),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          // Link row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onOpenLink,
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: AppTheme.primaryAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          url,
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onOpenLink,
                child: Text(
                  'share.open'.tr(),
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onCopyLink,
                child: Text(
                  'share.copy'.tr(),
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Wishlist link row - native list style
class _WishlistLinkRow extends StatelessWidget {
  final Wishlist wishlist;
  final String url;
  final bool isUpdating;
  final VoidCallback onOpenLink;
  final VoidCallback onCopyLink;
  final VoidCallback onChangeVisibility;

  const _WishlistLinkRow({
    required this.wishlist,
    required this.url,
    required this.isUpdating,
    required this.onOpenLink,
    required this.onCopyLink,
    required this.onChangeVisibility,
  });

  String _getVisibilityLabel() {
    switch (wishlist.visibility) {
      case 'public':
        return 'wishlist.visibility_public'.tr();
      case 'friends':
        return 'wishlist.visibility_friends'.tr();
      default:
        return 'wishlist.visibility_private'.tr();
    }
  }

  IconData _getVisibilityIcon() {
    switch (wishlist.visibility) {
      case 'public':
        return Icons.public;
      case 'friends':
        return Icons.people_outline;
      default:
        return Icons.lock_outline;
    }
  }

  Color _getVisibilityColor() {
    switch (wishlist.visibility) {
      case 'public':
        return Colors.green.shade600;
      case 'friends':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrivate = wishlist.visibility == 'private';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + visibility row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wishlist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Visibility badge with label
                  GestureDetector(
                    onTap: isUpdating ? null : onChangeVisibility,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUpdating)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(_getVisibilityColor()),
                            ),
                          )
                        else ...[
                          Icon(_getVisibilityIcon(), size: 15, color: _getVisibilityColor()),
                          const SizedBox(width: 4),
                          Text(
                            _getVisibilityLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              color: _getVisibilityColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isPrivate) ...[
                const SizedBox(height: 8),
                // Link row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onOpenLink,
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                url,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onOpenLink,
                      child: Text(
                        'share.open'.tr(),
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: onCopyLink,
                      child: Text(
                        'share.copy'.tr(),
                        style: TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'share.private_notice'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade200),
      ],
    );
  }
}

// Visibility Selection Bottom Sheet - Compact
class _VisibilitySelectionBottomSheet extends StatelessWidget {
  final String currentVisibility;

  const _VisibilitySelectionBottomSheet({required this.currentVisibility});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'share.choose_visibility'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Options
          _CompactVisibilityOption(
            icon: Icons.public,
            title: 'share.visibility_public_title'.tr(),
            description: 'share.visibility_public_desc'.tr(),
            isSelected: currentVisibility == 'public',
            color: Colors.green,
            onTap: () => Navigator.pop(context, 'public'),
          ),
          _CompactVisibilityOption(
            icon: Icons.people_outline,
            title: 'share.visibility_friends_title'.tr(),
            description: 'share.visibility_friends_desc'.tr(),
            isSelected: currentVisibility == 'friends',
            color: Colors.blue,
            onTap: () => Navigator.pop(context, 'friends'),
          ),
          _CompactVisibilityOption(
            icon: Icons.lock_outline,
            title: 'share.visibility_private_title'.tr(),
            description: 'share.visibility_private_desc'.tr(),
            isSelected: currentVisibility == 'private',
            color: Colors.grey,
            onTap: () => Navigator.pop(context, 'private'),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// Compact Visibility Option
class _CompactVisibilityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final MaterialColor color;
  final VoidCallback onTap;

  const _CompactVisibilityOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.shade50 : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? color.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? color.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check, size: 20, color: color.shade600),
          ],
        ),
      ),
    );
  }
}

// Copy Explanation Bottom Sheet - Compact
class _CopyExplanationBottomSheet extends StatelessWidget {
  const _CopyExplanationBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Success icon + title row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'share.link_copied_title'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'share.link_copied_description'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Benefits - compact
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _CompactBenefitRow(icon: Icons.devices, text: 'share.benefit_no_app'.tr()),
                  const SizedBox(height: 8),
                  _CompactBenefitRow(icon: Icons.visibility, text: 'share.benefit_view_reserve'.tr()),
                  const SizedBox(height: 8),
                  _CompactBenefitRow(icon: Icons.share, text: 'share.benefit_easy_share'.tr()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Got it button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'share.got_it'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Benefit Row
class _CompactBenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CompactBenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
