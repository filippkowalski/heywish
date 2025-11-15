import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/behavior/no_stretch_scroll_behavior.dart';

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
  bool _isNavigating = false;

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
    final link = 'jinnie.co/$username';
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
    // Prevent multiple simultaneous calls
    if (_isNavigating) {
      debugPrint(
        '⚠️  OnboardingCompleteStep: Already navigating, ignoring duplicate call',
      );
      return;
    }

    final authService = context.read<AuthService>();
    final onboardingService = context.read<OnboardingService>();
    final router = GoRouter.of(context);

    // Also check if service is already processing
    if (onboardingService.isLoading) {
      debugPrint(
        '⚠️  OnboardingCompleteStep: Service is loading, ignoring duplicate call',
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      // If user skipped username step (anonymous), save profile now
      if (onboardingService.shouldSkipUsernameStep) {
        debugPrint(
          '🔄 OnboardingCompleteStep: Saving anonymous user profile...',
        );
        final success = await onboardingService.completeOnboarding();
        if (!success) {
          debugPrint(
            '❌ OnboardingCompleteStep: Failed to save anonymous profile',
          );
          if (mounted) {
            setState(() {
              _isNavigating = false;
            });
          }
          return;
        }

        // Sync user data from backend to ensure AuthService has the updated username
        await authService.syncUserWithBackend(retries: 1);
        debugPrint(
          '✅ OnboardingCompleteStep: Anonymous user data synced with backend',
        );
      }

      // Profile has already been saved when user completed username step (for non-anonymous)
      // Just mark onboarding as completed and navigate to home
      await authService.markOnboardingCompleted();
      debugPrint('✅ OnboardingCompleteStep: Onboarding marked as completed');

      router.go('/home');
    } catch (e) {
      debugPrint('❌ OnboardingCompleteStep: Error navigating to home: $e');
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('errors.something_went_wrong'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        final username = onboardingService.data.username ?? '';
        final profileUrl = 'jinnie.co/$username';
        final mediaQuery = MediaQuery.of(context);
        final bottomPadding = mediaQuery.padding.bottom;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF0F4FF),
                const Color(0xFFF8F5FF),
                Colors.white,
              ],
              stops: const [0.0, 0.3, 0.7],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ScrollConfiguration(
                        behavior: const NoStretchScrollBehavior(),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 40.0,
                          ),
                          child: Column(
                            children: [
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
                              const SizedBox(height: 48),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              AppColors.primary.withValues(
                                                alpha: 0.1,
                                              ),
                                              AppColors.primary.withValues(
                                                alpha: 0.05,
                                              ),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 36,
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: AppColors.success,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        '@$username',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.link_rounded,
                                              size: 16,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              profileUrl,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _copyLink(username),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color:
                                                    _linkCopied
                                                        ? AppColors.success
                                                        : AppColors.outline,
                                                width: 1.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _linkCopied
                                                      ? Icons
                                                          .check_circle_outline_rounded
                                                      : Icons.copy_rounded,
                                                  size: 18,
                                                  color:
                                                      _linkCopied
                                                          ? AppColors.success
                                                          : AppColors
                                                              .textSecondary,
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    _linkCopied
                                                        ? 'onboarding.link_copied'
                                                            .tr()
                                                        : 'onboarding.copy_link'
                                                            .tr(),
                                                    style: TextStyle(
                                                      color:
                                                          _linkCopied
                                                              ? AppColors
                                                                  .success
                                                              : AppColors
                                                                  .textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    _buildFeatureItem(
                                      icon: Icons.favorite_border_rounded,
                                      title:
                                          'onboarding.feature_create_title'
                                              .tr(),
                                      subtitle:
                                          'onboarding.feature_create_subtitle'
                                              .tr(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFeatureItem(
                                      icon: Icons.people_outline_rounded,
                                      title:
                                          'onboarding.feature_share_title'.tr(),
                                      subtitle:
                                          'onboarding.feature_share_subtitle'
                                              .tr(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFeatureItem(
                                      icon: Icons.card_giftcard_rounded,
                                      title:
                                          'onboarding.feature_gift_title'.tr(),
                                      subtitle:
                                          'onboarding.feature_gift_subtitle'
                                              .tr(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        24.0,
                        0.0,
                        24.0,
                        bottomPadding + 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onboardingService.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                onboardingService.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          PrimaryButton(
                            onPressed:
                                (_isNavigating || onboardingService.isLoading)
                                    ? null
                                    : _completeOnboardingAndNavigate,
                            text: 'onboarding.start_wishing'.tr(),
                            icon: Icons.arrow_forward_rounded,
                            isLoading:
                                _isNavigating || onboardingService.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isNavigating || onboardingService.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.7),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
