import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class AccountBenefitsStep extends StatelessWidget {
  const AccountBenefitsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Hero Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/onboarding/account_icon_1.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'onboarding.account_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'onboarding.account_subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Benefits
              _buildBenefitItem(
                context,
                Icons.sync_outlined,
                'onboarding.benefit_sync_title'.tr(),
                'onboarding.benefit_sync_subtitle'.tr(),
              ),
              
              const SizedBox(height: 20),
              
              _buildBenefitItem(
                context,
                Icons.person_outline,
                'onboarding.benefit_username_title'.tr(),
                'onboarding.benefit_username_subtitle'.tr(),
              ),
              
              const SizedBox(height: 20),
              
              _buildBenefitItem(
                context,
                Icons.people_outline,
                'onboarding.benefit_friends_title'.tr(),
                'onboarding.benefit_friends_subtitle'.tr(),
              ),
              
              const Spacer(),
              
              // Reassurance about deletion
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'onboarding.account_reassurance'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              PrimaryButton(
                onPressed: () => onboardingService.nextStep(),
                text: 'onboarding.create_account'.tr(),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}