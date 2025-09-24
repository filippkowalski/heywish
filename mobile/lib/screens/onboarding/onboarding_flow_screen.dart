import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/onboarding_service.dart';
import '../../common/theme/app_colors.dart';
import '../../common/utils/native_transitions.dart';
import 'widgets/welcome_step.dart';
import 'widgets/intro_step.dart';
import 'widgets/username_step.dart';
import 'widgets/username_confirmation_step.dart';
import 'widgets/birthday_step.dart';
import 'widgets/gender_step.dart';
import 'widgets/notifications_step.dart';
// import 'widgets/find_friends_step.dart'; // Temporarily hidden
// import 'widgets/account_choice_step.dart'; // Skipped - go directly to complete
import 'widgets/onboarding_complete_step.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  OnboardingStep? _previousStep;
  
  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              // Track step changes for transition direction
              final currentStep = onboardingService.currentStep;
              final isForward = _isStepForward(currentStep);
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

                  // Main content with animated transitions
                  Positioned.fill(
                    child: _buildAnimatedStep(currentStep, isForward),
                  ),
                ],
              );
            },
          ),
        ),
      );
  }


  Widget _buildAnimatedStep(OnboardingStep currentStep, bool isForward) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return NativeTransitions.animatedPageTransition(
          child: child,
          animation: animation,
          isForward: isForward,
        );
      },
      child: Container(
        key: ValueKey(currentStep),
        child: _buildCurrentStep(currentStep),
      ),
    );
  }

  Widget _buildCurrentStep(OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.welcome:
        return const WelcomeStep();
      case OnboardingStep.intro:
        return const IntroStep();
      case OnboardingStep.username:
        return const UsernameStep();
      case OnboardingStep.usernameConfirmation:
        return const UsernameConfirmationStep();
      case OnboardingStep.birthday:
        return const BirthdayStep();
      case OnboardingStep.gender:
        return const GenderStep();
      case OnboardingStep.notifications:
        return const NotificationsStep();
      case OnboardingStep.findFriends:
        return const NotificationsStep(); // Skip to notifications for now
      case OnboardingStep.accountChoice:
        return const OnboardingCompleteStep(); // Skip to complete
      case OnboardingStep.complete:
        return const OnboardingCompleteStep();
    }
  }
  
  bool _isStepForward(OnboardingStep currentStep) {
    if (_previousStep == null) {
      _previousStep = currentStep;
      return true;
    }
    
    final currentIndex = OnboardingStep.values.indexOf(currentStep);
    final previousIndex = OnboardingStep.values.indexOf(_previousStep!);
    
    bool isForward = currentIndex > previousIndex;
    
    // Update previous step for next comparison
    _previousStep = currentStep;
    
    return isForward;
  }

  bool _canGoBack(OnboardingStep step) {
    // Don't show back button on first step, confirmation step, or complete step
    return step != OnboardingStep.welcome && 
           step != OnboardingStep.usernameConfirmation && 
           step != OnboardingStep.complete;
  }
}