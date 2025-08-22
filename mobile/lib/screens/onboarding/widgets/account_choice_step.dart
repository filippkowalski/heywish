import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class AccountChoiceStep extends StatefulWidget {
  const AccountChoiceStep({super.key});

  @override
  State<AccountChoiceStep> createState() => _AccountChoiceStepState();
}

class _AccountChoiceStepState extends State<AccountChoiceStep> {
  bool _isCreatingAccount = false;

  Future<void> _createAccount() async {
    setState(() {
      _isCreatingAccount = true;
    });

    try {
      // Navigate to signup screen
      if (mounted) {
        context.push('/auth/signup').then((_) {
          // When returning from signup, complete onboarding
          if (mounted) {
            setState(() {
              _isCreatingAccount = false;
            });
            // Move to completion after successful account creation
            context.read<OnboardingService>().nextStep();
          }
        });
      }
    } catch (e) {
      debugPrint('Error navigating to signup: $e');
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final onboardingService = context.read<OnboardingService>();
    final authService = context.read<AuthService>();
    
    try {
      // Sign in anonymously if not already authenticated
      if (!authService.isAuthenticated) {
        await authService.signInAnonymously();
      }
      
      // Move to completion
      onboardingService.nextStep();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      // Still proceed to next step to avoid getting stuck
      onboardingService.nextStep();
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
                  
                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.account_circle,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Save your progress?',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'You\'ve created a great profile! Create an account to save your progress and sync across devices.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Current profile summary
                  Consumer<OnboardingService>(
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
                              'Your profile:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildProfileItem(
                              Icons.account_circle_outlined,
                              'Username',
                              '@${userData.username ?? 'Not set'}',
                            ),
                            
                            if (userData.birthday != null)
                              _buildProfileItem(
                                Icons.cake_outlined,
                                'Birthday',
                                _formatDate(userData.birthday!),
                              ),
                            
                            if (userData.gender != null)
                              _buildProfileItem(
                                Icons.person_outline,
                                'Gender',
                                userData.gender!,
                              ),
                            
                            _buildProfileItem(
                              Icons.notifications_outlined,
                              'Notifications',
                              userData.notificationPreferences.values.any((v) => v) 
                                  ? 'Enabled' 
                                  : 'Disabled',
                            ),
                            
                            _buildProfileItem(
                              Icons.people_outline,
                              'Friends found',
                              '${userData.friendSuggestions.length}',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Benefits section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'With an account:',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        _buildBenefitItem('✓ Your data is securely backed up'),
                        _buildBenefitItem('✓ Sync across all your devices'),
                        _buildBenefitItem('✓ Friends can find you easily'),
                        _buildBenefitItem('✓ Never lose your wishlists'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
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
              // Create account button
              PrimaryButton(
                text: 'Create Account & Save',
                onPressed: _isCreatingAccount ? null : _createAccount,
                isLoading: _isCreatingAccount,
              ),
              const SizedBox(height: 12),
              
              // Continue as guest button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.outline),
                  ),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              
              // Note
              const SizedBox(height: 16),
              Text(
                'As a guest, your data will only be saved locally on this device',
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

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.green.shade700,
        ),
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