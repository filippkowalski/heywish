import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/onboarding_service.dart';
import '../../common/theme/app_colors.dart';
import 'widgets/welcome_step.dart';
import 'widgets/username_step.dart';
import 'widgets/profile_info_step.dart';
import 'widgets/notifications_step.dart';
import 'widgets/find_friends_step.dart';
import 'widgets/account_choice_step.dart';
import 'widgets/onboarding_complete_step.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = OnboardingService();
  }

  @override
  void dispose() {
    _onboardingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _onboardingService,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              // Only show full-screen loader for major operations like completing onboarding
              if (onboardingService.isLoading && onboardingService.currentStep == OnboardingStep.complete) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              return Stack(
                children: [
                  // Progress indicator
                  if (_shouldShowProgress(onboardingService.currentStep))
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildProgressIndicator(onboardingService.currentStep),
                    ),

                  // Back button
                  if (_canGoBack(onboardingService.currentStep))
                    Positioned(
                      top: 16,
                      left: 16,
                      child: IconButton(
                        onPressed: onboardingService.previousStep,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                  // Main content
                  Positioned.fill(
                    top: _shouldShowProgress(onboardingService.currentStep) ? 80 : 0,
                    child: _buildCurrentStep(onboardingService.currentStep),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(OnboardingStep currentStep) {
    // Show progress for all 6 main steps
    final steps = [
      OnboardingStep.welcome,
      OnboardingStep.username,
      OnboardingStep.profileInfo,
      OnboardingStep.notifications,
      OnboardingStep.findFriends,
      OnboardingStep.accountChoice,
    ];
    
    final currentIndex = steps.indexOf(currentStep);
    final progress = currentIndex / (steps.length - 1);

    return Column(
      children: [
        const SizedBox(height: 40),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          '${currentIndex + 1} of ${steps.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStepTitle(currentStep),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.welcome:
        return const WelcomeStep();
      case OnboardingStep.username:
        return const UsernameStep();
      case OnboardingStep.profileInfo:
        return const ProfileInfoStep();
      case OnboardingStep.notifications:
        return const NotificationsStep();
      case OnboardingStep.findFriends:
        return const FindFriendsStep();
      case OnboardingStep.accountChoice:
        return const AccountChoiceStep();
      case OnboardingStep.complete:
        return const OnboardingCompleteStep();
    }
  }

  bool _shouldShowProgress(OnboardingStep step) {
    // Show progress for all steps except complete
    return step != OnboardingStep.complete;
  }

  bool _canGoBack(OnboardingStep step) {
    // Don't show back button on first step or complete step
    return step != OnboardingStep.welcome && step != OnboardingStep.complete;
  }

  String _getStepTitle(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return 'Welcome to HeyWish';
      case OnboardingStep.username:
        return 'Choose your username';
      case OnboardingStep.profileInfo:
        return 'Tell us about yourself';
      case OnboardingStep.notifications:
        return 'Stay in the loop';
      case OnboardingStep.findFriends:
        return 'Find your friends';
      case OnboardingStep.accountChoice:
        return 'Save your progress';
      case OnboardingStep.complete:
        return 'All set!';
    }
  }
}