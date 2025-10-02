import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Animation<Offset> _slideAnimation;
  bool _linkCopied = false;

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

  void _copyLink(String username) {
    final link = 'heywish.com/$username';
    Clipboard.setData(ClipboardData(text: link));
    setState(() {
      _linkCopied = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _linkCopied = false;
        });
      }
    });
  }

  Future<void> _completeOnboardingAndNavigate() async {
    final onboardingService = context.read<OnboardingService>();
    final authService = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (onboardingService.isLoading) {
      return;
    }

    try {
      final success = await onboardingService.completeOnboarding();

      if (!mounted) {
        return;
      }

      if (success) {
        await authService.markOnboardingCompleted();
        debugPrint('✅ OnboardingCompleteStep: Onboarding marked as completed');
        router.go('/home');
      } else {
        final message =
            onboardingService.error ??
            'Failed to save your profile. Please try again.';
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        final username = onboardingService.data.username ?? '';
        final profileUrl = 'heywish.com/$username';

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 32.0,
                    right: 32.0,
                    top: topPadding + 80.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'onboarding.complete_title'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 34,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'onboarding.complete_subtitle'.tr(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      if (onboardingService.shouldSkipUsernameStep)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'onboarding.anonymous_username_hint'.tr(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 40),

                      // Username card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.08),
                                AppColors.primary.withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 28,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'onboarding.your_username'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '@$username',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Profile URL card
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.language_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'onboarding.your_personal_page'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                profileUrl,
                                style: TextStyle(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Copy link button
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: OutlinedButton.icon(
                          onPressed: () => _copyLink(username),
                          icon: Icon(
                            _linkCopied
                                ? Icons.check_rounded
                                : Icons.link_rounded,
                            size: 20,
                            color:
                                _linkCopied
                                    ? Colors.green.shade600
                                    : AppColors.textSecondary,
                          ),
                          label: Text(
                            _linkCopied
                                ? 'onboarding.link_copied'.tr()
                                : 'onboarding.copy_link'.tr(),
                            style: TextStyle(
                              color:
                                  _linkCopied
                                      ? Colors.green.shade600
                                      : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            side: BorderSide(
                              color:
                                  _linkCopied
                                      ? Colors.green.shade600
                                      : Colors.black.withValues(alpha: 0.12),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Fixed footer
              Container(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 20.0,
                  bottom: bottomPadding + 32.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onboardingService.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          onboardingService.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    PrimaryButton(
                      onPressed:
                          onboardingService.isLoading
                              ? null
                              : _completeOnboardingAndNavigate,
                      text: 'onboarding.start_wishing'.tr(),
                      isLoading: onboardingService.isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
