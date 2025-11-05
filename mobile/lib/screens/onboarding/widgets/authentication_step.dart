import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/merge_accounts_bottom_sheet.dart';

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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
      final result = await authService.authenticateWithGoogle();

      // Store auth method for analytics
      onboardingService.setAuthMethod('google');

      if (context.mounted) {
        if (result.action == NavigationAction.goHome) {
          await authService.markOnboardingCompleted();
          context.go('/home');
        } else if (result.action == NavigationAction.continueOnboarding) {
          onboardingService.goToStep(result.resumeAt!);
        } else if (result.action == NavigationAction.showMergeDialog) {
          final shouldMerge = await MergeAccountsBottomSheet.show(context);
          if (!context.mounted) return;

          if (shouldMerge == true) {
            try {
              await authService.performAccountMerge(result.anonymousUserId!);
              await authService.markOnboardingCompleted();
              if (!context.mounted) return;
              context.go('/home');
            } catch (e) {
              if (!context.mounted) return;
              String errorMsg;
              if (e.toString().contains('sync') || e.toString().contains('connection')) {
                errorMsg = 'errors.network_error'.tr();
              } else {
                errorMsg = 'Failed to merge accounts. Please try again.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
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
      final result = await authService.authenticateWithApple();

      // Store auth method for analytics
      onboardingService.setAuthMethod('apple');

      if (context.mounted) {
        if (result.action == NavigationAction.goHome) {
          await authService.markOnboardingCompleted();
          context.go('/home');
        } else if (result.action == NavigationAction.continueOnboarding) {
          onboardingService.goToStep(result.resumeAt!);
        } else if (result.action == NavigationAction.showMergeDialog) {
          final shouldMerge = await MergeAccountsBottomSheet.show(context);
          if (!context.mounted) return;

          if (shouldMerge == true) {
            try {
              await authService.performAccountMerge(result.anonymousUserId!);
              await authService.markOnboardingCompleted();
              if (!context.mounted) return;
              context.go('/home');
            } catch (e) {
              if (!context.mounted) return;
              String errorMsg;
              if (e.toString().contains('sync') || e.toString().contains('connection')) {
                errorMsg = 'errors.network_error'.tr();
              } else {
                errorMsg = 'Failed to merge accounts. Please try again.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
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