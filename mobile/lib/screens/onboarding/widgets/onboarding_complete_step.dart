import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCompletingOnboarding = false;
  bool _hasCompletedOnce = false; // Prevent double-tap
  
  // Use a static flag to prevent multiple completion attempts across widget rebuilds
  static bool _globalCompletionInProgress = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    // Don't auto-complete immediately to avoid infinite loops
    // User must click the button to complete
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboardingProcess() async {
    debugPrint('🎯 OnboardingCompleteStep: _completeOnboardingProcess called');
    debugPrint('🎯 OnboardingCompleteStep: _globalCompletionInProgress: $_globalCompletionInProgress');
    debugPrint('🎯 OnboardingCompleteStep: _hasCompletedOnce: $_hasCompletedOnce');
    debugPrint('🎯 OnboardingCompleteStep: _isCompletingOnboarding: $_isCompletingOnboarding');
    
    // Prevent multiple completion attempts using static flag
    if (_globalCompletionInProgress || _hasCompletedOnce) {
      debugPrint('⚠️ OnboardingCompleteStep: Completion already in progress or completed, skipping');
      return;
    }
    
    _globalCompletionInProgress = true;
    _hasCompletedOnce = true;
    
    // Small delay to avoid setState during build
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (!mounted) {
      debugPrint('⚠️ OnboardingCompleteStep: Widget unmounted during delay, skipping completion');
      return;
    }
    
    setState(() {
      _isCompletingOnboarding = true;
    });

    try {
      // Mark onboarding as completed FIRST to prevent navigation loops
      final authService = context.read<AuthService>();
      await authService.markOnboardingCompleted();
      
      debugPrint('✅ OnboardingCompleteStep: Onboarding marked as completed, navigating immediately');
      
      // Navigate immediately to prevent widget recreation issues
      if (mounted) {
        _navigateToHome();
      }
      
      // Then sync the profile data to server in background (don't wait for it)
      final onboardingService = context.read<OnboardingService>();
      onboardingService.completeOnboarding().then((success) {
        debugPrint('✅ OnboardingCompleteStep: Background profile sync result: $success');
      }).catchError((error) {
        debugPrint('❌ OnboardingCompleteStep: Background profile sync error: $error');
      });
    } catch (e) {
      debugPrint('❌ OnboardingCompleteStep: Error completing onboarding: $e');
      
      // On error, navigate to home to avoid getting stuck
      if (mounted) {
        _navigateToHome();
      }
    } finally {
      // Reset the global flag to allow future attempts if needed
      _globalCompletionInProgress = false;
      
      if (mounted) {
        setState(() {
          _isCompletingOnboarding = false;
        });
      }
    }
  }

  void _navigateToHome() {
    debugPrint('🏠 OnboardingCompleteStep: Navigating to home screen');
    try {
      // Use go() which replaces the entire navigation stack
      context.go('/home');
      debugPrint('✅ OnboardingCompleteStep: Navigation to home successful');
    } catch (e) {
      debugPrint('❌ OnboardingCompleteStep: Navigation error: $e');
    }
  }

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
          
          // Success Animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Success Message
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    Text(
                      'Welcome to HeyWish!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Consumer<OnboardingService>(
                      builder: (context, onboardingService, child) {
                        final userData = onboardingService.data;
                        return Text(
                          'Hi ${userData.fullName ?? userData.username ?? 'there'}! Your account is all set up.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 48),
          
          // Setup Summary
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Consumer<OnboardingService>(
                  builder: (context, onboardingService, child) {
                    final userData = onboardingService.data;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your setup summary:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _buildSummaryItem(
                            Icons.account_circle_outlined,
                            'Username',
                            '@${userData.username ?? 'Not set'}',
                          ),
                          
                          if (userData.birthday != null)
                            _buildSummaryItem(
                              Icons.cake_outlined,
                              'Birthday',
                              _formatDate(userData.birthday!),
                            ),
                          
                          if (userData.gender != null)
                            _buildSummaryItem(
                              Icons.person_outline,
                              'Gender',
                              userData.gender!,
                            ),
                          
                          _buildSummaryItem(
                            Icons.notifications_outlined,
                            'Notifications',
                            userData.notificationPreferences.values.any((v) => v) 
                                ? 'Enabled' 
                                : 'Disabled',
                          ),
                          
                          _buildSummaryItem(
                            Icons.people_outline,
                            'Friends found',
                            '${userData.friendSuggestions.length}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
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
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    PrimaryButton(
                      text: 'Start Creating Wishlists',
                      onPressed: (_isCompletingOnboarding || _hasCompletedOnce) ? null : _completeOnboardingProcess,
                      isLoading: _isCompletingOnboarding,
                    ),
                    
                    // Fallback skip button if completion is taking too long
                    if (_isCompletingOnboarding) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _navigateToHome,
                        child: Text(
                          'Skip and continue to app',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}