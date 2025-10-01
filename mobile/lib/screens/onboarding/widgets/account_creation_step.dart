import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';

class AccountCreationStep extends StatefulWidget {
  const AccountCreationStep({Key? key}) : super(key: key);

  @override
  State<AccountCreationStep> createState() => _AccountCreationStepState();
}

class _AccountCreationStepState extends State<AccountCreationStep>
    with TickerProviderStateMixin {
  late AnimationController _blob1Controller;
  late AnimationController _blob2Controller;
  late AnimationController _blob3Controller;

  @override
  void initState() {
    super.initState();

    // Create animation controllers with different durations for organic movement
    _blob1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _blob2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _blob3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blob1Controller.dispose();
    _blob2Controller.dispose();
    _blob3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the safe area padding to account for it manually
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0E7FF), // Light indigo
            const Color(0xFFF5F3FF), // Light purple
            const Color(0xFFFCE7F3), // Light pink
            Colors.white.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated mesh gradient overlay blobs
          AnimatedBuilder(
            animation: _blob1Controller,
            builder: (context, child) {
              return Positioned(
                top: -120 + (_blob1Controller.value * 30),
                left: -80 + (sin(_blob1Controller.value * 2 * pi) * 20),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _blob2Controller,
            builder: (context, child) {
              return Positioned(
                bottom: -100 + (_blob2Controller.value * 40),
                right: -100 + (sin(_blob2Controller.value * 2 * pi) * 25),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.2), // Pink
                        const Color(0xFFEC4899).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _blob3Controller,
            builder: (context, child) {
              return Positioned(
                top: 250 + (sin(_blob3Controller.value * 2 * pi) * 25),
                right: 30 + (_blob3Controller.value * 30),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(
                          0xFF8B5CF6,
                        ).withValues(alpha: 0.15), // Purple
                        const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Main content
          Padding(
            padding: EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: topPadding + 60.0,
              bottom: bottomPadding + 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Text(
                  'onboarding.account_teaser'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                Text(
                  'onboarding.account_title'.tr(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 12),
                Text(
                  'onboarding.account_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 48),

                // Benefits cards
                _buildBenefitCard(
                  icon: Icons.layers_rounded,
                  iconColor: const Color(0xFF3B82F6), // Blue
                  title: 'onboarding.benefit_sync_title'.tr(),
                ),
                const SizedBox(height: 16),
                _buildBenefitCard(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF8B5CF6), // Purple
                  title: 'onboarding.benefit_never_lose_title'.tr(),
                ),
                const SizedBox(height: 16),
                _buildBenefitCard(
                  icon: Icons.person_add_outlined,
                  iconColor: const Color(0xFF3B82F6), // Blue
                  title: 'onboarding.benefit_username_title'.tr(),
                ),

                const Spacer(),

                // Buttons section - Platform specific
                // iOS: Show both Apple and Google
                // Android: Only show Google
                if (Platform.isIOS) ...[
                  _buildSignInButton(
                    context: context,
                    onPressed: () => _signUpWithApple(context),
                    backgroundColor: const Color(0xFF1F2937), // Dark gray/black
                    foregroundColor: Colors.white,
                    icon: Icons.apple,
                    label: 'auth.sign_in_apple'.tr(),
                  ),
                  const SizedBox(height: 14),
                ],

                _buildSignInButton(
                  context: context,
                  onPressed: () => _signUpWithGoogle(context),
                  backgroundColor: const Color(0xFFDB4437), // Google red
                  foregroundColor: Colors.white,
                  customIcon: Image.asset(
                    'assets/icons/google.png',
                    height: 20,
                    width: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata,
                        size: 22,
                        color: Colors.white,
                      );
                    },
                  ),
                  label: 'auth.sign_in_google'.tr(),
                  hasBorder: false,
                ),

                const SizedBox(height: 28),

                // Skip button
                Center(
                  child: TextButton(
                    onPressed: () => _skipAccountCreation(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                    ),
                    child: Text(
                      'onboarding.skip_for_now'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    IconData? icon,
    Widget? customIcon,
    required String label,
    bool hasBorder = false,
  }) {
    return Container(
      decoration:
          hasBorder
              ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
              : null,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side:
                  hasBorder
                      ? BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.2),
                        width: 1.5,
                      )
                      : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (customIcon != null) customIcon,
              if (icon != null) Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUpWithGoogle(BuildContext context) async {
    try {
      final authService = context.read<AuthService>();
      final onboarding = context.read<OnboardingService>();

      // 1. Sign in with Google
      await authService.signInWithGoogle();

      // 2. Set email in onboarding data
      final email = authService.firebaseUser?.email;
      if (email != null) {
        onboarding.updateEmail(email);
      }

      // 3. Check if user already exists (has username)
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

      // 2. Set email in onboarding data
      final email = authService.firebaseUser?.email;
      if (email != null) {
        onboarding.updateEmail(email);
      }

      // 3. Check if user already exists (has username)
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
