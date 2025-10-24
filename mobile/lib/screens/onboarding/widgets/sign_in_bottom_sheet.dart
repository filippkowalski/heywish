import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../theme/app_theme.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/merge_accounts_bottom_sheet.dart';

class SignInBottomSheet {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SignInBottomSheetContent(),
    );
  }
}

class _SignInBottomSheetContent extends StatefulWidget {
  const _SignInBottomSheetContent();

  @override
  State<_SignInBottomSheetContent> createState() => _SignInBottomSheetContentState();
}

class _SignInBottomSheetContentState extends State<_SignInBottomSheetContent> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final onboardingService = context.read<OnboardingService>();

      // Check if upgrading from anonymous
      final wasAnonymous = authService.firebaseUser?.isAnonymous ?? false;

      // Sign in with Google and check if user exists in DB
      final result = await authService.signInWithGoogleCheckExisting();
      final userExists = result['userExists'] as bool;
      final requiresMerge = result['requiresMerge'] as bool;
      final anonymousUserId = result['anonymousUserId'] as String?;

      if (!mounted) return;

      // Check if we need to merge accounts
      if (requiresMerge && anonymousUserId != null) {
        setState(() {
          _isLoading = false;
        });

        // Show merge confirmation dialog
        final shouldMerge = await MergeAccountsBottomSheet.show(context);

        if (!mounted) return;

        if (shouldMerge == true) {
          setState(() {
            _isLoading = true;
          });

          try {
            // Call backend to merge accounts
            final apiService = authService.apiService;
            await apiService.mergeAccounts(anonymousUserId);

            // Sync user data from backend to get updated username
            await authService.syncUserWithBackend(retries: 1);

            // Mark onboarding complete and navigate to home
            await authService.markOnboardingCompleted();

            if (!mounted) return;
            Navigator.of(context).pop();
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to merge accounts. Please try again.';
            });
          }
        } else {
          // User cancelled merge - stay on current screen
          return;
        }
      } else {
        // After sign-in, check if user is still anonymous or now authenticated
        final isNowAuthenticated = authService.firebaseUser != null &&
                                   !authService.firebaseUser!.isAnonymous;

        if (userExists || (wasAnonymous && isNowAuthenticated)) {
          // Existing user OR successfully upgraded anonymous user - mark onboarding complete and close
          await authService.markOnboardingCompleted();
          if (!mounted) return;
          Navigator.of(context).pop();
          // User will be navigated to home screen automatically by router
        } else {
          // New user - show dialog and continue to onboarding
          setState(() {
            _isLoading = false;
          });

          await _showNoAccountDialog();

          if (!mounted) return;
          Navigator.of(context).pop(); // Close bottom sheet

          // Mark that user already signed in so we skip account creation step
          onboardingService.setHasAlreadySignedIn(true);

          // Continue to profile details (skipping account creation since they already signed in)
          onboardingService.goToStep(OnboardingStep.profileDetails);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'auth.error_google_signin'.tr();
      });
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final onboardingService = context.read<OnboardingService>();

      // Check if upgrading from anonymous
      final wasAnonymous = authService.firebaseUser?.isAnonymous ?? false;

      // Sign in with Apple and check if user exists in DB
      final result = await authService.signInWithAppleCheckExisting();
      final userExists = result['userExists'] as bool;
      final requiresMerge = result['requiresMerge'] as bool;
      final anonymousUserId = result['anonymousUserId'] as String?;

      if (!mounted) return;

      // Check if we need to merge accounts
      if (requiresMerge && anonymousUserId != null) {
        setState(() {
          _isLoading = false;
        });

        // Show merge confirmation dialog
        final shouldMerge = await MergeAccountsBottomSheet.show(context);

        if (!mounted) return;

        if (shouldMerge == true) {
          setState(() {
            _isLoading = true;
          });

          try {
            // Call backend to merge accounts
            final apiService = authService.apiService;
            await apiService.mergeAccounts(anonymousUserId);

            // Sync user data from backend to get updated username
            await authService.syncUserWithBackend(retries: 1);

            // Mark onboarding complete and navigate to home
            await authService.markOnboardingCompleted();

            if (!mounted) return;
            Navigator.of(context).pop();
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to merge accounts. Please try again.';
            });
          }
        } else {
          // User cancelled merge - stay on current screen
          return;
        }
      } else {
        // After sign-in, check if user is still anonymous or now authenticated
        final isNowAuthenticated = authService.firebaseUser != null &&
                                   !authService.firebaseUser!.isAnonymous;

        if (userExists || (wasAnonymous && isNowAuthenticated)) {
          // Existing user OR successfully upgraded anonymous user - mark onboarding complete and close
          await authService.markOnboardingCompleted();
          if (!mounted) return;
          Navigator.of(context).pop();
          // User will be navigated to home screen automatically by router
        } else {
          // New user - show dialog and continue to onboarding
          setState(() {
            _isLoading = false;
          });

          await _showNoAccountDialog();

          if (!mounted) return;
          Navigator.of(context).pop(); // Close bottom sheet

          // Mark that user already signed in so we skip account creation step
          onboardingService.setHasAlreadySignedIn(true);

          // Continue to profile details (skipping account creation since they already signed in)
          onboardingService.goToStep(OnboardingStep.profileDetails);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'auth.error_apple_signin'.tr();
      });
    }
  }

  Future<void> _showNoAccountDialog() async {
    if (Platform.isIOS) {
      await showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('auth.no_account_title'.tr()),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('auth.no_account_message'.tr()),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('auth.no_account_continue'.tr()),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('auth.no_account_title'.tr()),
          content: Text('auth.no_account_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('auth.no_account_continue'.tr()),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomPadding + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'auth.sign_in_title'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'auth.sign_in_subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Loading indicator or buttons
          if (_isLoading)
            Column(
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryAccent),
                const SizedBox(height: 16),
                Text(
                  'auth.signing_in'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else ...[
            // Google Sign-in button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.g_mobiledata_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'auth.sign_in_google'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Apple Sign-in button (iOS only)
            if (Platform.isIOS)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleAppleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'auth.sign_in_apple'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
