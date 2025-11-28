import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/gift_guide_service.dart';
import '../../models/gift_guide.dart';
import '../../common/widgets/vertical_guide_card.dart';
import 'guide_detail_screen.dart';
import '../../common/navigation/native_page_route.dart';

/// Main discover screen with horizontal scrollable guide previews
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    // Load both categories (for mapping) and guides on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<GiftGuideService>();
      service.loadCategories();
      service.loadAllGuides();
    });
  }

  /// Get rotated subset of guides based on current day
  /// Shows maxVisible guides per section, rotates daily
  List<GiftGuide> _getRotatedGuides(
    List<GiftGuide> guides,
    int maxVisible,
  ) {
    if (guides.length <= maxVisible) return guides;

    // Use day of year for rotation
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final offset = dayOfYear % guides.length;

    // Rotate and take maxVisible items
    final rotated = [...guides.sublist(offset), ...guides.sublist(0, offset)];
    return rotated.take(maxVisible).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('discover.title'.tr()),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: Consumer<GiftGuideService>(
        builder: (context, service, child) {
          // Loading state - need both categories and guides
          if (service.isLoading &&
              (service.guidesGroupedBySection == null || service.categoriesGrouped == null)) {
            return _buildLoadingState();
          }

          // Error state
          if (service.error != null) {
            return _buildErrorState(service.error!, () {
              service.clearError();
              service.loadCategories(forceRefresh: true);
              service.loadAllGuides(forceRefresh: true);
            });
          }

          // Guides loaded
          final guidesGrouped = service.guidesGroupedBySection;
          if (guidesGrouped == null || guidesGrouped.isEmpty) {
            return _buildEmptyState();
          }

          return _buildGuidePreviews(guidesGrouped);
        },
      ),
    );
  }

  Widget _buildGuidePreviews(Map<String, List<GiftGuide>> grouped) {
    // Reordered sections: Price/Style → Recipient → Shopping → Occasion
    final sections = [
      {
        'key': 'price_style',
        'title': 'discover.section_price_style'.tr(),
        'guides': grouped['price_style'] ?? [],
        'maxVisible': 6,
      },
      {
        'key': 'recipient',
        'title': 'discover.section_recipient'.tr(),
        'guides': grouped['recipient'] ?? [],
        'maxVisible': 5,
      },
      {
        'key': 'shopping',
        'title': 'discover.section_shopping'.tr(),
        'guides': grouped['shopping'] ?? [],
        'maxVisible': 8,
      },
      {
        'key': 'occasion',
        'title': 'discover.section_occasion'.tr(),
        'guides': grouped['occasion'] ?? [],
        'maxVisible': 6,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          for (var section in sections)
            if ((section['guides'] as List).isNotEmpty)
              _buildHorizontalGuideSection(
                section['title'] as String,
                section['guides'] as List<GiftGuide>,
                section['maxVisible'] as int,
                section['key'] as String,
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHorizontalGuideSection(
    String title,
    List<GiftGuide> allGuides,
    int maxVisible,
    String groupKey,
  ) {
    final displayGuides = _getRotatedGuides(allGuides, maxVisible);
    final hasMore = allGuides.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable guide list
        SizedBox(
          height: 250, // Matches card height with text overlay
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayGuides.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == displayGuides.length - 1 ? 0 : 12,
                ),
                child: VerticalGuideCard(
                  guide: displayGuides[index],
                  onTap: () => _navigateToGuideDetail(displayGuides[index]),
                ),
              );
            },
          ),
        ),

        // Daily rotation hint (only if has more guides)
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, right: 20),
            child: Text(
              'discover.guides_rotate_hint'.tr(namedArgs: {
                'shown': displayGuides.length.toString(),
                'total': allGuides.length.toString(),
              }),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateToGuideDetail(GiftGuide guide) {
    context.pushNative(
      GuideDetailScreen(guideSlug: guide.slug),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFE91E63),
          ),
          const SizedBox(height: 16),
          Text(
            'discover.loading'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
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
              'discover.error_loading_categories'.tr(),
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

  Widget _buildEmptyState() {
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
                Icons.inbox_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'discover.no_guides_title'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'discover.no_guides_subtitle'.tr(),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
