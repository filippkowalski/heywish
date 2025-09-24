import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class OnboardingCompleteStep extends StatefulWidget {
  const OnboardingCompleteStep({super.key});

  @override
  State<OnboardingCompleteStep> createState() => _OnboardingCompleteStepState();
}

class _OnboardingCompleteStepState extends State<OnboardingCompleteStep> {
  bool _isSigningInWithGoogle = false;
  bool _isSigningInWithApple = false;
  bool _isNavigatingToCustomSignIn = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningInWithGoogle = true;
    });
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      
      if (mounted) {
        await _completeOnboardingAndNavigate();
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningInWithGoogle = false;
        });
      }
    }
  }
  
  Future<void> _signInWithApple() async {
    setState(() {
      _isSigningInWithApple = true;
    });
    
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithApple();
      
      if (mounted) {
        await _completeOnboardingAndNavigate();
      }
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningInWithApple = false;
        });
      }
    }
  }
  
  Future<void> _navigateToCustomSignIn() async {
    setState(() {
      _isNavigatingToCustomSignIn = true;
    });
    
    try {
      if (mounted) {
        context.push('/auth/signup').then((_) {
          if (mounted) {
            setState(() {
              _isNavigatingToCustomSignIn = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        setState(() {
          _isNavigatingToCustomSignIn = false;
        });
      }
    }
  }

  Future<void> _completeOnboardingAndNavigate() async {
    try {
      // Mark onboarding as completed
      final authService = context.read<AuthService>();
      await authService.markOnboardingCompleted();
      
      debugPrint('✅ OnboardingCompleteStep: Onboarding marked as completed, navigating to home');
      
      // Navigate to home
      if (mounted) {
        _navigateToHome();
      }
      
      // Sync profile data in background
      final onboardingService = context.read<OnboardingService>();
      onboardingService.completeOnboarding().then((success) {
        debugPrint('✅ OnboardingCompleteStep: Background profile sync result: $success');
      }).catchError((error) {
        debugPrint('❌ OnboardingCompleteStep: Background profile sync error: $error');
      });
    } catch (e) {
      debugPrint('❌ OnboardingCompleteStep: Error completing onboarding: $e');
      
      // On error, still navigate to home to avoid getting stuck
      if (mounted) {
        _navigateToHome();
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
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    
    return Column(
      children: [
        // Decorative top section
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryAccent.withOpacity(0.1),
                AppTheme.primaryAccent.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Animated heart icons background
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background decorative hearts
                  Positioned(
                    top: -10,
                    left: 60,
                    child: Icon(
                      Icons.favorite,
                      size: 24,
                      color: AppTheme.primaryAccent.withOpacity(0.2),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 50,
                    child: Icon(
                      Icons.favorite,
                      size: 16,
                      color: AppTheme.primaryAccent.withOpacity(0.15),
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    left: 40,
                    child: Icon(
                      Icons.favorite,
                      size: 20,
                      color: AppTheme.primaryAccent.withOpacity(0.1),
                    ),
                  ),
                  
                  // Main app icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 50,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
        
        // Main content
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Title
                  AutoSizeText(
                    'Create your account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 20,
                    maxFontSize: 30,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Benefits explanation
                  AutoSizeText(
                    '• Sync your wishlists across devices\n• Never lose your wishes again\n• Share with friends and family\n• Get notified about gift opportunities',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 6,
                    minFontSize: 13,
                    maxFontSize: 16,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Social sign-in buttons (platform-specific ordering)
                  if (isIOS) ...[
                    // Apple Sign In first on iOS
                    _buildSocialButton(
                      icon: Icons.apple,
                      text: 'Continue with Apple',
                      onPressed: _isSigningInWithApple ? null : _signInWithApple,
                      isLoading: _isSigningInWithApple,
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Google Sign In second on iOS
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'Continue with Google',
                      onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
                      isLoading: _isSigningInWithGoogle,
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      hasBorder: true,
                    ),
                  ] else ...[
                    // Google Sign In first on Android
                    _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'Continue with Google',
                      onPressed: _isSigningInWithGoogle ? null : _signInWithGoogle,
                      isLoading: _isSigningInWithGoogle,
                      backgroundColor: Colors.white,
                      textColor: Colors.black87,
                      hasBorder: true,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Apple Sign In second on Android
                    _buildSocialButton(
                      icon: Icons.apple,
                      text: 'Continue with Apple',
                      onPressed: _isSigningInWithApple ? null : _signInWithApple,
                      isLoading: _isSigningInWithApple,
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Custom sign in option
                  TextButton(
                    onPressed: _isNavigatingToCustomSignIn ? null : _navigateToCustomSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isNavigatingToCustomSignIn) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Sign up with email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Color backgroundColor,
    required Color textColor,
    bool hasBorder = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Icon(
                icon,
                color: textColor,
                size: 20,
              ),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          side: hasBorder
              ? const BorderSide(
                  color: AppColors.outline,
                  width: 1,
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}