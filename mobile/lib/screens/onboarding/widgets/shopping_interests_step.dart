import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class ShoppingInterestsStep extends StatefulWidget {
  const ShoppingInterestsStep({super.key});

  @override
  State<ShoppingInterestsStep> createState() => _ShoppingInterestsStepState();
}

class _ShoppingInterestsStepState extends State<ShoppingInterestsStep> {
  List<ShoppingCategory> get _categories => [
    ShoppingCategory(
      id: 'fashion',
      emoji: '👕',
      label: 'shopping_interests.category_fashion'.tr(),
      color: const Color(0xFFEC4899), // Pink
    ),
    ShoppingCategory(
      id: 'beauty',
      emoji: '💄',
      label: 'shopping_interests.category_beauty'.tr(),
      color: const Color(0xFFF97316), // Orange
    ),
    ShoppingCategory(
      id: 'electronics',
      emoji: '📱',
      label: 'shopping_interests.category_electronics'.tr(),
      color: const Color(0xFF3B82F6), // Blue
    ),
    ShoppingCategory(
      id: 'home',
      emoji: '🏠',
      label: 'shopping_interests.category_home'.tr(),
      color: const Color(0xFF10B981), // Green
    ),
    ShoppingCategory(
      id: 'books',
      emoji: '📚',
      label: 'shopping_interests.category_books'.tr(),
      color: const Color(0xFF8B5CF6), // Purple
    ),
    ShoppingCategory(
      id: 'sports',
      emoji: '⚽',
      label: 'shopping_interests.category_sports'.tr(),
      color: const Color(0xFFF59E0B), // Amber
    ),
    ShoppingCategory(
      id: 'toys',
      emoji: '🧸',
      label: 'shopping_interests.category_toys'.tr(),
      color: const Color(0xFFEF4444), // Red
    ),
    ShoppingCategory(
      id: 'jewelry',
      emoji: '💎',
      label: 'shopping_interests.category_jewelry'.tr(),
      color: const Color(0xFF06B6D4), // Cyan
    ),
    ShoppingCategory(
      id: 'food',
      emoji: '🍔',
      label: 'shopping_interests.category_food'.tr(),
      color: const Color(0xFFFBBF24), // Yellow
    ),
    ShoppingCategory(
      id: 'art',
      emoji: '🎨',
      label: 'shopping_interests.category_art'.tr(),
      color: const Color(0xFFA855F7), // Purple
    ),
    ShoppingCategory(
      id: 'music',
      emoji: '🎵',
      label: 'shopping_interests.category_music'.tr(),
      color: const Color(0xFF14B8A6), // Teal
    ),
    ShoppingCategory(
      id: 'outdoor',
      emoji: '⛺',
      label: 'shopping_interests.category_outdoor'.tr(),
      color: const Color(0xFF22C55E), // Green
    ),
  ];

  Set<String> _selectedCategories = {};

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });

    // Update onboarding data with canonical ids
    final onboardingService = context.read<OnboardingService>();
    onboardingService.updateShoppingInterests(_selectedCategories.toList());
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedCategories.isNotEmpty;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Top section with skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: () => context.read<OnboardingService>().nextStep(),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'app.skip'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 0.0,
                bottom: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'shopping_interests.title'.tr(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'shopping_interests.subtitle'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),

                  const SizedBox(height: 40),

                  // Category chips wrapped
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        _categories.map((category) {
                          final isSelected = _selectedCategories.contains(
                            category.id,
                          );
                          return _buildCategoryChip(category, isSelected);
                        }).toList(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed footer
          Container(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 0.0,
              bottom: 16.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selection count
                if (_selectedCategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'shopping_interests.selected_count'.tr(
                        namedArgs: {
                          'count': _selectedCategories.length.toString(),
                        },
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Continue button
                PrimaryButton(
                  onPressed:
                      canContinue
                          ? () => context.read<OnboardingService>().nextStep()
                          : null,
                  text: 'app.continue'.tr(),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ShoppingCategory category, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleCategory(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? category.color
                    : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class ShoppingCategory {
  final String id;
  final String emoji;
  final String label;
  final Color color;

  ShoppingCategory({
    required this.id,
    required this.emoji,
    required this.label,
    required this.color,
  });
}
