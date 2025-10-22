import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/onboarding_service.dart';
import '../../common/theme/app_colors.dart';
import '../../common/navigation/native_page_route.dart';
import 'widgets/welcome_step.dart';
import 'widgets/account_creation_step.dart';
import 'widgets/user_status_check_step.dart';
import 'widgets/username_step.dart';
import 'widgets/profile_details_step.dart';
import 'widgets/shopping_interests_step.dart';
import 'widgets/notifications_step.dart';
import 'widgets/onboarding_complete_step.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  OnboardingStep? _previousStep;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<OnboardingService>(
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
                // Main content with animated transitions (full screen)
                Positioned.fill(
                  child: _buildAnimatedStep(currentStep, isForward),
                ),

                // Back button (positioned above content with safe area)
                if (_canGoBack(onboardingService.currentStep))
                  Positioned(
                    top: topPadding + 12,
                    left: 16,
                    child: IconButton(
                      onPressed: onboardingService.previousStep,
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }


  Widget _buildAnimatedStep(OnboardingStep currentStep, bool isForward) {
    // Use platform-specific transition duration
    final duration = Platform.isIOS
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 300);

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Create a dummy secondary animation for the transition
        final secondaryAnimation = const AlwaysStoppedAnimation<double>(0.0);

        return NativeTransitions.buildPageTransition(
          child: child,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
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
      case OnboardingStep.shoppingInterests:
        return const ShoppingInterestsStep();
      case OnboardingStep.profileDetails:
        return const ProfileDetailsStep();
      case OnboardingStep.notifications:
        return const NotificationsStep();
      case OnboardingStep.accountCreation:
        return const AccountCreationStep();
      case OnboardingStep.checkUserStatus:
        return const UserStatusCheckStep();
      case OnboardingStep.username:
        return const UsernameStep();
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
    // Don't show back button on certain steps
    return step != OnboardingStep.welcome &&
           step != OnboardingStep.shoppingInterests &&
           step != OnboardingStep.accountCreation &&
           step != OnboardingStep.checkUserStatus &&
           step != OnboardingStep.username &&
           step != OnboardingStep.complete;
  }
}