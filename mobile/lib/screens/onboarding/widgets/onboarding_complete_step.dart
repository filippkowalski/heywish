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
        final screenHeight = mediaQuery.size.height;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.03),
                Colors.white,
                Colors.white,
              ],
              stops: const [0.0, 0.3, 1.0],
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
                          padding: EdgeInsets.fromLTRB(
                            32,
                            screenHeight * 0.08,
                            32,
                            24,
                          ),
                          child: Column(
                            children: [
                              // Animated checkmark circle
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.success,
                                        AppColors.success.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.success.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.05),

                              // Title
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    'onboarding.complete_title'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontSize: 36,
                                      letterSpacing: -1.2,
                                      height: 1.1,
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
                                      fontSize: 17,
                                      height: 1.4,
                                      fontWeight: FontWeight.w400,
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
                              SizedBox(height: screenHeight * 0.06),

                              // Profile card - completely redesigned
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Top accent bar
                                      Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary.withValues(alpha: 0.6),
                                              AppColors.primary,
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(28),
                                            topRight: Radius.circular(28),
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                                        child: Column(
                                          children: [
                                            // Username with accent
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        AppColors.primary.withValues(alpha: 0.08),
                                                        AppColors.primary.withValues(alpha: 0.04),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: Text(
                                                    '@$username',
                                                    style: TextStyle(
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 26,
                                                      letterSpacing: -0.8,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 28),

                                            // Divider
                                            Container(
                                              height: 1,
                                              margin: const EdgeInsets.symmetric(horizontal: 20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    const Color(0xFFE8E8E8),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // Profile URL
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.link_rounded,
                                                  size: 20,
                                                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  profileUrl,
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 28),

                                            // Copy link button - redesigned
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _copyLink(username),
                                                borderRadius: BorderRadius.circular(16),
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: _linkCopied
                                                        ? LinearGradient(
                                                            colors: [
                                                              AppColors.success,
                                                              AppColors.success.withValues(alpha: 0.8),
                                                            ],
                                                          )
                                                        : LinearGradient(
                                                            colors: [
                                                              AppColors.primary,
                                                              AppColors.primary.withValues(alpha: 0.9),
                                                            ],
                                                          ),
                                                    borderRadius: BorderRadius.circular(16),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (_linkCopied
                                                                ? AppColors.success
                                                                : AppColors.primary)
                                                            .withValues(alpha: 0.3),
                                                        blurRadius: 12,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        _linkCopied
                                                            ? Icons.check_circle_rounded
                                                            : Icons.content_copy_rounded,
                                                        size: 22,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        _linkCopied
                                                            ? 'onboarding.link_copied'.tr()
                                                            : 'onboarding.copy_link'.tr(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 17,
                                                          letterSpacing: -0.3,
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
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom button area
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
}
