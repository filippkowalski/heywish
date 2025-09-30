import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class AuthenticationStep extends StatelessWidget {
  const AuthenticationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, OnboardingService>(
      builder: (context, authService, onboardingService, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo or illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'auth.sign_in_title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'auth.sign_in_subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Authentication buttons
              Column(
                children: [
                  // Google Sign In
                  PrimaryButton(
                    onPressed: () => _handleGoogleSignIn(context, authService, onboardingService),
                    icon: Icons.g_mobiledata,
                    text: 'auth.sign_in_google'.tr(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apple Sign In
                  PrimaryButton(
                    onPressed: () => _handleAppleSignIn(context, authService, onboardingService),
                    icon: Icons.apple,
                    text: 'auth.sign_in_apple'.tr(),
                    isOutlined: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email Sign In
                  PrimaryButton(
                    onPressed: () => _handleEmailSignIn(context, authService, onboardingService),
                    icon: Icons.email_outlined,
                    text: 'auth.sign_in_email'.tr(),
                    isOutlined: true,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context, AuthService authService, OnboardingService onboardingService) async {
    try {
      await authService.signInWithGoogle();
      // Authentication state change will be handled automatically by AuthService
      // The onboarding flow will continue via auth state changes
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auth.error_google_signin'.tr())),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context, AuthService authService, OnboardingService onboardingService) async {
    try {
      await authService.signInWithApple();
      // Authentication state change will be handled automatically by AuthService
      // The onboarding flow will continue via auth state changes
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auth.error_apple_signin'.tr())),
        );
      }
    }
  }

  Future<void> _handleEmailSignIn(BuildContext context, AuthService authService, OnboardingService onboardingService) async {
    // For now, show a message that email sign in is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('auth.email_coming_soon'.tr())),
    );
  }
}