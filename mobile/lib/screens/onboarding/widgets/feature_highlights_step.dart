import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class FeatureHighlightsStep extends StatefulWidget {
  const FeatureHighlightsStep({super.key});

  @override
  State<FeatureHighlightsStep> createState() => _FeatureHighlightsStepState();
}

class _FeatureHighlightsStepState extends State<FeatureHighlightsStep> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<OnboardingService>().nextStep();
    }
  }

  void _skipToEnd() {
    context.read<OnboardingService>().nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top section with skip button
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _skipToEnd,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.all(12),
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
              ],
            ),
          ),

          // PageView with features
          Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildFeaturePage(
                imagePath: 'assets/images/onboarding/feature_organize.png',
                title: 'onboarding.feature_organize_title'.tr(),
                subtitle: 'onboarding.feature_organize_subtitle'.tr(),
              ),
              _buildFeaturePage(
                imagePath: 'assets/images/onboarding/feature_share.png',
                title: 'onboarding.feature_share_title'.tr(),
                subtitle: 'onboarding.feature_share_subtitle'.tr(),
              ),
              _buildFeaturePage(
                imagePath: 'assets/images/onboarding/feature_gift.png',
                title: 'onboarding.feature_gift_title'.tr(),
                subtitle: 'onboarding.feature_gift_subtitle'.tr(),
              ),
            ],
          ),
        ),

        // Page indicators
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),

          // Next/Continue button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: PrimaryButton(
              onPressed: _nextPage,
              text: _currentPage < 2 ? 'app.next'.tr() : 'onboarding.get_started'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feature image with animation
          Hero(
            tag: imagePath,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}