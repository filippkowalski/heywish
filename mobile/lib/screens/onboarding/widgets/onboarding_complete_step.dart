import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class OnboardingCompleteStep extends StatefulWidget {
  const OnboardingCompleteStep({super.key});

  @override
  State<OnboardingCompleteStep> createState() => _OnboardingCompleteStepState();
}

class _OnboardingCompleteStepState extends State<OnboardingCompleteStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingAndNavigate() async {
    try {
      // Mark onboarding as completed
      final authService = context.read<AuthService>();
      await authService.markOnboardingCompleted();

      debugPrint('✅ OnboardingCompleteStep: Onboarding marked as completed');

      // Sync profile data in background
      final onboardingService = context.read<OnboardingService>();
      onboardingService.completeOnboarding().then((success) {
        debugPrint('✅ Background profile sync result: $success');
      }).catchError((error) {
        debugPrint('❌ Background profile sync error: $error');
      });

      // Navigate to home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Animated celebration
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  // Multiple celebration icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 60,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.favorite,
                        size: 70,
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.celebration,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Decorative sparkles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 24, color: Colors.amber),
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 20, color: Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Animated title
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'onboarding.complete_title'.tr(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 32,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animated subtitle
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'onboarding.complete_subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const Spacer(),

          // Start button
          FadeTransition(
            opacity: _fadeAnimation,
            child: PrimaryButton(
              onPressed: _completeOnboardingAndNavigate,
              text: 'onboarding.start_wishing'.tr(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}