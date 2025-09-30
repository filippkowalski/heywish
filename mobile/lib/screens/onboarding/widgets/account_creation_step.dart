import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';

class AccountCreationStep extends StatelessWidget {
  const AccountCreationStep({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'onboarding.account_title'.tr(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'onboarding.account_subtitle'.tr(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefitsList(),

          const SizedBox(height: 32),

          // Primary buttons - Sign up options
          ElevatedButton.icon(
            onPressed: () => _signUpWithGoogle(context),
            icon: Image.asset(
              'assets/icons/google.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.g_mobiledata, size: 24);
              },
            ),
            label: Text('auth.sign_in_google'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 2,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () => _signUpWithApple(context),
            icon: const Icon(Icons.apple, size: 24),
            label: Text('auth.sign_in_apple'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Secondary button - Skip
          TextButton(
            onPressed: () => _skipAccountCreation(context),
            child: Text(
              'onboarding.skip_for_now'.tr(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBenefitItem(
            Icons.devices,
            'onboarding.benefit_sync_title'.tr(),
            'onboarding.benefit_sync_subtitle'.tr(),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            Icons.cloud_done,
            'onboarding.benefit_never_lose_title'.tr(),
            'onboarding.benefit_never_lose_subtitle'.tr(),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            Icons.person,
            'onboarding.benefit_username_title'.tr(),
            'onboarding.benefit_username_subtitle'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signUpWithGoogle(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      final onboarding = context.read<OnboardingService>();

      // 1. Sign in with Google
      await authService.signInWithGoogle();

      // 2. Check if user already exists (has username)
      final isExistingUser = authService.currentUser?.username != null;

      if (isExistingUser) {
        // Existing user - skip onboarding, go to main app
        await authService.markOnboardingCompleted();
        if (context.mounted) {
          context.go('/home');
        }
      } else {
        // New user - continue to username selection
        onboarding.goToStep(OnboardingStep.username);
      }
    } catch (e) {
      debugPrint('Error signing up with Google: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.error_google_signin'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signUpWithApple(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      final onboarding = context.read<OnboardingService>();

      // 1. Sign in with Apple
      await authService.signInWithApple();

      // 2. Check if user already exists (has username)
      final isExistingUser = authService.currentUser?.username != null;

      if (isExistingUser) {
        // Existing user - skip onboarding, go to main app
        await authService.markOnboardingCompleted();
        if (context.mounted) {
          context.go('/home');
        }
      } else {
        // New user - continue to username selection
        onboarding.goToStep(OnboardingStep.username);
      }
    } catch (e) {
      debugPrint('Error signing up with Apple: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.error_apple_signin'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _skipAccountCreation(BuildContext context) async {
    final authService = context.read<AuthService>();
    final onboarding = context.read<OnboardingService>();

    // Generate username immediately (instant)
    final username = _generateAnonymousUsername();
    debugPrint('Generated anonymous username: $username');

    // Move to next step immediately - don't wait for auth
    onboarding.goToStep(OnboardingStep.profileDetails);

    // Do auth and sync in background
    try {
      // Create anonymous Firebase account
      await authService.signInAnonymously();

      // Sync with backend with generated username
      await authService.syncUserWithBackend(
        signUpMethod: 'anonymous',
        username: username,
      );

      debugPrint('✅ Anonymous account created successfully in background');
    } catch (e) {
      debugPrint('❌ Error creating anonymous account: $e');
      // Show error but don't block user - they can retry later
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.unknown_error'.tr()),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () async {
                try {
                  await authService.signInAnonymously();
                  await authService.syncUserWithBackend(
                    signUpMethod: 'anonymous',
                    username: username,
                  );
                } catch (e) {
                  debugPrint('Retry failed: $e');
                }
              },
            ),
          ),
        );
      }
    }
  }

  /// Generate anonymous username (user1234567 format)
  String _generateAnonymousUsername() {
    // Generate 7-digit random number
    final random = Random();
    final digits = 1000000 + random.nextInt(9000000);
    return 'user$digits';
  }
}