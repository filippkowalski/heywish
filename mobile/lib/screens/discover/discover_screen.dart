import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/gift_guide_service.dart';
import '../../models/gift_guide_category.dart';
import 'guide_list_screen.dart';
import 'all_categories_screen.dart';
import '../../common/navigation/native_page_route.dart';

/// Main discover screen with horizontal scrollable category previews
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    // Load categories on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftGuideService>().loadCategories();
    });
  }

  /// Get rotated subset of categories based on current day
  /// Shows 6-8 categories per section, rotates daily
  List<GiftGuideCategory> _getRotatedCategories(
    List<GiftGuideCategory> categories,
    int maxVisible,
  ) {
    if (categories.length <= maxVisible) return categories;

    // Use day of year for rotation
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final offset = dayOfYear % categories.length;

    // Rotate and take maxVisible items
    final rotated = [...categories.sublist(offset), ...categories.sublist(0, offset)];
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
          // Loading state
          if (service.isLoading && service.categoriesGrouped == null) {
            return _buildLoadingState();
          }

          // Error state
          if (service.error != null) {
            return _buildErrorState(service.error!, () {
              service.clearError();
              service.loadCategories(forceRefresh: true);
            });
          }

          // Categories loaded
          final categoriesGrouped = service.categoriesGrouped;
          if (categoriesGrouped == null || categoriesGrouped.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCategoryPreviews(categoriesGrouped);
        },
      ),
    );
  }

  Widget _buildCategoryPreviews(Map<String, List<GiftGuideCategory>> grouped) {
    // Reordered sections: Price/Style → Recipient → Shopping → Occasion
    final sections = [
      {
        'key': 'price_style',
        'title': 'discover.section_price_style'.tr(),
        'categories': grouped['price_style'] ?? [],
        'maxVisible': 6,
      },
      {
        'key': 'recipient',
        'title': 'discover.section_recipient'.tr(),
        'categories': grouped['recipient'] ?? [],
        'maxVisible': 5,
      },
      {
        'key': 'shopping',
        'title': 'discover.section_shopping'.tr(),
        'categories': grouped['shopping'] ?? [],
        'maxVisible': 8,
      },
      {
        'key': 'occasion',
        'title': 'discover.section_occasion'.tr(),
        'categories': grouped['occasion'] ?? [],
        'maxVisible': 6,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          for (var section in sections)
            if ((section['categories'] as List).isNotEmpty)
              _buildHorizontalSection(
                section['title'] as String,
                section['categories'] as List<GiftGuideCategory>,
                section['maxVisible'] as int,
                section['key'] as String,
                grouped,
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(
    String title,
    List<GiftGuideCategory> allCategories,
    int maxVisible,
    String groupKey,
    Map<String, List<GiftGuideCategory>> allGrouped,
  ) {
    final displayCategories = _getRotatedCategories(allCategories, maxVisible);
    final hasMore = allCategories.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "View All" button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _navigateToAllCategories(groupKey, title, allGrouped),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE91E63),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable category list
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayCategories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == displayCategories.length - 1 ? 0 : 12,
                ),
                child: _HorizontalCategoryCard(
                  category: displayCategories[index],
                  onTap: () => _navigateToGuideList(displayCategories[index]),
                ),
              );
            },
          ),
        ),

        // Daily rotation hint (only if has more categories)
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, right: 20),
            child: Text(
              'Categories rotate daily • Showing ${displayCategories.length} of ${allCategories.length}',
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

  void _navigateToGuideList(GiftGuideCategory category) {
    context.pushNative(
      GuideListScreen(category: category),
    );
  }

  void _navigateToAllCategories(
    String groupKey,
    String groupTitle,
    Map<String, List<GiftGuideCategory>> allGrouped,
  ) {
    context.pushNative(
      AllCategoriesScreen(
        groupKey: groupKey,
        groupTitle: groupTitle,
        categories: allGrouped[groupKey] ?? [],
      ),
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

/// Horizontal category card widget (wider, horizontal layout)
class _HorizontalCategoryCard extends StatelessWidget {
  final GiftGuideCategory category;
  final VoidCallback onTap;

  const _HorizontalCategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),

            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Colored indicator line
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
