import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../services/gift_guide_service.dart';
import '../../models/gift_guide.dart';
import '../../models/gift_guide_item.dart';
import '../../common/widgets/masonry_wish_card.dart';
import '../../common/widgets/skeleton_loading.dart';
import '../wishlists/wish_detail_screen.dart';

/// Guide detail screen - shows guide with items in masonry grid
class GuideDetailScreen extends StatefulWidget {
  final String guideSlug;

  const GuideDetailScreen({
    super.key,
    required this.guideSlug,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  GiftGuide? _guide;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer loading to avoid calling notifyListeners() during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGuideDetails();
    });
  }

  Future<void> _loadGuideDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final guide = await context.read<GiftGuideService>().loadGuideDetails(
            widget.guideSlug,
          );

      if (mounted) {
        setState(() {
          _guide = guide;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showItemDetail(GiftGuideItem item) async {
    await WishDetailScreen.showGiftGuideItem(
      context,
      title: item.title,
      image: item.image,
      price: item.price,
      currency: item.currency,
      url: item.url,
      description: item.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _guide != null
            ? Text(
                _guide!.title,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (_guide != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Implement share functionality
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Error state
    if (_error != null || _guide == null) {
      return _buildErrorState(_error ?? 'Guide not found', _loadGuideDetails);
    }

    // Guide details
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _guide!.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 20),

          // Items masonry grid
          if (_guide!.items != null && _guide!.items!.isNotEmpty)
            _buildItemsGrid(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildItemsGrid() {
    final items = _guide!.items!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return MasonryWishCard(
            title: item.title,
            description: item.description,
            imageUrl: item.image,
            price: item.price,
            currency: item.currency,
            url: item.url,
            isReserved: false,
            onTap: () => _showItemDetail(item),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Description skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonText(
              lines: 4,
              height: 15,
              spacing: 10,
              width: double.infinity,
            ),
          ),

          const SizedBox(height: 20),

          // Items grid skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                // Alternate heights for masonry effect
                final height = index % 2 == 0 ? 280.0 : 320.0;
                return SkeletonLoading(
                  width: double.infinity,
                  height: height,
                  borderRadius: BorderRadius.circular(16),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'discover.error_loading_guides'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('discover.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
