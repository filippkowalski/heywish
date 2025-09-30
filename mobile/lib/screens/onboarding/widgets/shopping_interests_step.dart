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

class _ShoppingInterestsStepState extends State<ShoppingInterestsStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<ShoppingCategory> _categories = [
    ShoppingCategory(
      id: 'fashion',
      emoji: '👕',
      label: 'Fashion',
      color: Color(0xFFFFB6C1),
    ),
    ShoppingCategory(
      id: 'beauty',
      emoji: '💄',
      label: 'Beauty',
      color: Color(0xFFDDA0DD),
    ),
    ShoppingCategory(
      id: 'electronics',
      emoji: '📱',
      label: 'Electronics',
      color: Color(0xFF87CEEB),
    ),
    ShoppingCategory(
      id: 'home',
      emoji: '🏠',
      label: 'Home & Decor',
      color: Color(0xFFFFA07A),
    ),
    ShoppingCategory(
      id: 'books',
      emoji: '📚',
      label: 'Books',
      color: Color(0xFF98D8C8),
    ),
    ShoppingCategory(
      id: 'sports',
      emoji: '⚽',
      label: 'Sports',
      color: Color(0xFFFFD700),
    ),
    ShoppingCategory(
      id: 'toys',
      emoji: '🧸',
      label: 'Toys & Games',
      color: Color(0xFFFF69B4),
    ),
    ShoppingCategory(
      id: 'jewelry',
      emoji: '💎',
      label: 'Jewelry',
      color: Color(0xFFE6E6FA),
    ),
  ];

  Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });

    // Update onboarding data
    final onboardingService = context.read<OnboardingService>();
    onboardingService.data.shoppingInterests = _selectedCategories.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'shopping_interests.title'.tr(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Subtitle
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'shopping_interests.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Category Grid
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategories.contains(category.id);

                    return GestureDetector(
                      onTap: () => _toggleCategory(category.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : AppColors.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: category.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Continue Button
          FadeTransition(
            opacity: _fadeAnimation,
            child: PrimaryButton(
              onPressed: () => context.read<OnboardingService>().nextStep(),
              text: 'app.next'.tr(),
            ),
          ),

          const SizedBox(height: 16),
        ],
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