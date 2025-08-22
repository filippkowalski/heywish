import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
          const SizedBox(height: 20),
          
          // App Icon/Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Welcome to HeyWish!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            'The modern way to create and share wishlists with friends and family.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Features
          _buildFeature(
            context,
            Icons.list_alt_rounded,
            'Create Beautiful Wishlists',
            'Organize your wishes with photos and descriptions',
          ),
          
          const SizedBox(height: 16),
          
          _buildFeature(
            context,
            Icons.people_rounded,
            'Share with Friends',
            'Let others know what you really want',
          ),
          
          const SizedBox(height: 16),
          
          _buildFeature(
            context,
            Icons.notifications_rounded,
            'Smart Notifications',
            'Get notified about birthdays and special deals',
          ),
          
          const SizedBox(height: 40), // Less spacing since button is now fixed
                ],
              ),
            ),
          ),
        ),
        
        // Fixed bottom section
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          child: Column(
            children: [
              // Get Started Button
              Consumer<OnboardingService>(
                builder: (context, onboardingService, child) {
                  return PrimaryButton(
                    text: 'Get Started',
                    onPressed: onboardingService.nextStep,
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Terms
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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