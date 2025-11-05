import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/merge_accounts_bottom_sheet.dart';

class AccountChoiceStep extends StatefulWidget {
  const AccountChoiceStep({super.key});

  @override
  State<AccountChoiceStep> createState() => _AccountChoiceStepState();
}

class _AccountChoiceStepState extends State<AccountChoiceStep> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.authenticateWithGoogle();

      if (mounted) {
        if (result.action == NavigationAction.continueOnboarding) {
          context.read<OnboardingService>().nextStep();
        } else if (result.action == NavigationAction.goHome) {
          await authService.markOnboardingCompleted();
          context.go('/home');
        } else if (result.action == NavigationAction.showMergeDialog) {
          setState(() => _isSigningIn = false);
          final shouldMerge = await MergeAccountsBottomSheet.show(context);
          if (!mounted) return;

          if (shouldMerge == true) {
            setState(() => _isSigningIn = true);
            try {
              await authService.performAccountMerge(result.anonymousUserId!);
              await authService.markOnboardingCompleted();
              if (!mounted) return;
              context.go('/home');
            } catch (e) {
              if (!mounted) return;
              String errorMsg;
              if (e.toString().contains('sync') || e.toString().contains('connection')) {
                errorMsg = 'errors.network_error'.tr();
              } else {
                errorMsg = 'Failed to merge accounts. Please try again.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      final authService = context.read<AuthService>();
      final result = await authService.authenticateWithApple();

      if (mounted) {
        if (result.action == NavigationAction.continueOnboarding) {
          context.read<OnboardingService>().nextStep();
        } else if (result.action == NavigationAction.goHome) {
          await authService.markOnboardingCompleted();
          context.go('/home');
        } else if (result.action == NavigationAction.showMergeDialog) {
          setState(() => _isSigningIn = false);
          final shouldMerge = await MergeAccountsBottomSheet.show(context);
          if (!mounted) return;

          if (shouldMerge == true) {
            setState(() => _isSigningIn = true);
            try {
              await authService.performAccountMerge(result.anonymousUserId!);
              await authService.markOnboardingCompleted();
              if (!mounted) return;
              context.go('/home');
            } catch (e) {
              if (!mounted) return;
              String errorMsg;
              if (e.toString().contains('sync') || e.toString().contains('connection')) {
                errorMsg = 'errors.network_error'.tr();
              } else {
                errorMsg = 'Failed to merge accounts. Please try again.';
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Profile icon/avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AutoSizeText(
                        'onboarding.create_account_title'.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        minFontSize: 20,
                        maxFontSize: 30,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: AutoSizeText(
                        'onboarding.create_account_subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        minFontSize: 13,
                        maxFontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Profile summary card
                    Consumer<OnboardingService>(
                      builder: (context, onboardingService, child) {
                        final userData = onboardingService.data;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryItem(
                                'onboarding.summary_username'.tr(),
                                '@${userData.username ?? 'Not set'}',
                              ),

                              if (userData.birthday != null) ...[
                                const SizedBox(height: 12),
                                _buildSummaryItem(
                                  'onboarding.summary_birthday'.tr(),
                                  _formatDate(userData.birthday!),
                                ),
                              ],

                              if (userData.gender != null) ...[
                                const SizedBox(height: 12),
                                _buildSummaryItem(
                                  'onboarding.summary_gender'.tr(),
                                  _getGenderDisplayName(userData.gender!),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
              child: Column(
                children: [
                  // Google Sign In button
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                      icon:
                          _isSigningIn
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(Icons.g_mobiledata),
                      label: Text('onboarding.continue_with_google'.tr()),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ),

                  // Apple Sign In button (iOS only)
                  if (_isIOS) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isSigningIn ? null : _handleAppleSignIn,
                        icon: const Icon(Icons.apple),
                        label: Text('onboarding.continue_with_apple'.tr()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Security note
                  Text(
                    'onboarding.data_security_note'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _getGenderDisplayName(String gender) {
    switch (gender) {
      case 'female':
        return 'onboarding.gender_woman'.tr();
      case 'male':
        return 'onboarding.gender_man'.tr();
      case 'non-binary':
        return 'onboarding.gender_non_binary'.tr();
      case 'prefer-not-to-say':
        return 'onboarding.gender_prefer_not_say'.tr();
      default:
        return gender;
    }
  }
}
