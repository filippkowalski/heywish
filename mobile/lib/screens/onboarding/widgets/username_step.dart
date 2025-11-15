import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import '../../../services/onboarding_service.dart';
import '../../../services/auth_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/platform_loader.dart';
import '../../../common/behavior/no_stretch_scroll_behavior.dart';

/// Custom text formatter to convert input to lowercase
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}

class UsernameStep extends StatefulWidget {
  const UsernameStep({super.key});

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  final _usernameController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    // Pre-fill username
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingService = context.read<OnboardingService>();

      // If username already exists in onboarding data, use it
      if (onboardingService.data.username != null) {
        _usernameController.text = onboardingService.data.username!;
      } else {
        // Otherwise, try to autopopulate from email
        _autopopulateFromEmail();
      }
    });
  }

  /// Autopopulate username from email (excluding Apple anonymous emails)
  void _autopopulateFromEmail() {
    final onboardingService = context.read<OnboardingService>();
    final email = onboardingService.data.email;

    if (email == null || email.isEmpty) {
      return;
    }

    // Check if it's an Apple anonymous email (privaterelay.appleid.com)
    if (email.contains('@privaterelay.appleid.com')) {
      debugPrint(
        '📧 UsernameStep: Skipping autopopulate for Apple anonymous email',
      );
      return;
    }

    // Extract username from email (part before @)
    final emailPrefix = email.split('@').first;

    if (emailPrefix.isNotEmpty) {
      debugPrint(
        '📧 UsernameStep: Autopopulating username from email: $emailPrefix',
      );
      _usernameController.text = emailPrefix;
      _onUsernameChanged(emailPrefix);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Validate username according to Instagram-style rules
  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return null; // Allow empty for now
    }

    if (username.length < 3) {
      return 'username_validation.min_length'.tr();
    }

    if (username.length > 30) {
      return 'username_validation.max_length'.tr();
    }

    // Check for spaces
    if (username.contains(' ')) {
      return 'username_validation.no_spaces'.tr();
    }

    // Check for invalid characters (Instagram allows letters, numbers, underscores, and periods)
    final validPattern = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validPattern.hasMatch(username)) {
      return 'username_validation.invalid_characters'.tr();
    }

    // Cannot start or end with period
    if (username.startsWith('.') || username.endsWith('.')) {
      return 'username_validation.no_period_edges'.tr();
    }

    // Cannot have consecutive periods
    if (username.contains('..')) {
      return 'username_validation.no_consecutive_periods'.tr();
    }

    return null; // Valid
  }

  void _onUsernameChanged(String value) {
    final onboardingService = context.read<OnboardingService>();

    // The input is already cleaned by the inputFormatters and LowerCaseTextFormatter
    // No need to manually update the controller value

    // Validate the username
    final validationError = _validateUsername(value);
    if (_validationError != validationError) {
      setState(() {
        _validationError = validationError;
      });
    }

    onboardingService.updateUsername(value);

    // Only check availability if username is valid
    _debounceTimer?.cancel();
    if (validationError == null && value.isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        onboardingService.checkUsernameAvailability(value);
      });
    }
  }

  Future<void> _handleContinue(OnboardingService onboardingService) async {
    // Get AuthService before any async calls to avoid using BuildContext across async gap
    final authService = context.read<AuthService>();

    try {
      debugPrint('🎯 UsernameStep: Saving profile to backend...');

      // Save profile to backend
      final success = await onboardingService.completeOnboarding();

      if (success) {
        debugPrint('✅ UsernameStep: Profile saved successfully');

        // Sync user data from backend to ensure AuthService has the updated username
        await authService.syncUserWithBackend(retries: 1);
        debugPrint('✅ UsernameStep: User data synced with backend');

        // Move to complete step
        onboardingService.nextStep();
      } else {
        debugPrint('❌ UsernameStep: Failed to save profile');
        // Error is already shown by OnboardingService
      }
    } catch (e) {
      debugPrint('❌ UsernameStep: Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errors.unknown_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusMessage(OnboardingService onboardingService) {
    // Show validation error first if any
    if (_validationError != null) {
      return _validationError!;
    }

    // Show API result if available and no validation errors
    if (onboardingService.usernameCheckResult != null &&
        onboardingService.usernameCheckResult != 'Checking...') {
      if (onboardingService.usernameCheckResult == 'Available') {
        return 'username_validation.available'.tr();
      } else {
        return onboardingService.usernameCheckResult!;
      }
    }

    // Show checking status
    if (onboardingService.isLoading) {
      return 'username_validation.checking'.tr();
    }

    return '';
  }

  Color _getStatusColor(OnboardingService onboardingService) {
    // Red for validation errors
    if (_validationError != null) {
      return Colors.red.shade600;
    }

    // Color based on API result
    if (onboardingService.usernameCheckResult == 'Available') {
      return Colors.green.shade600;
    } else if (onboardingService.usernameCheckResult != null &&
        onboardingService.usernameCheckResult != 'Checking...') {
      return Colors.red.shade600;
    }

    // Gray for checking
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF0F4FF), // Very light blue
            const Color(0xFFF8F5FF), // Very light purple
            Colors.white,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: ScrollConfiguration(
                behavior: const NoStretchScrollBehavior(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(
                    left: 32.0,
                    right: 32.0,
                    top: 40.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'onboarding.username_title'.tr(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'onboarding.username_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 48),

                      // Username input - centered and styled
                      Consumer<OnboardingService>(
                        builder: (context, onboardingService, child) {
                          return Column(
                            children: [
                              // Status message above input
                              if (_usernameController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    _getStatusMessage(onboardingService),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: _getStatusColor(onboardingService),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              // Username field with inline loader
                              Container(
                                key: const ValueKey('username-input-container'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  focusNode: _focusNode,
                                  onChanged: _onUsernameChanged,
                                  textAlign: TextAlign.left,
                                  maxLength: 30,
                                  inputFormatters: [
                                    // Filter out spaces and convert to lowercase
                                    FilteringTextInputFormatter.deny(
                                      RegExp(r'\s'),
                                    ),
                                    LowerCaseTextFormatter(),
                                    // Only allow letters, numbers, periods, and underscores
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9._]'),
                                    ),
                                  ],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 20,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText:
                                        'onboarding.username_placeholder'.tr(),
                                    counterText: '', // Hide character counter
                                    contentPadding: EdgeInsets.zero,
                                    hintStyle: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 20,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.alternate_email,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.6),
                                        size: 24,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 0,
                                      minHeight: 0,
                                    ),
                                    suffixIcon:
                                        onboardingService.isLoading &&
                                                _validationError == null
                                            ? Container(
                                              width: 20,
                                              height: 20,
                                              padding: const EdgeInsets.all(12),
                                              child: PlatformLoader(
                                                size: 16,
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.6),
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : null,
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (onboardingService
                                            .canProceedFromCurrentStep() &&
                                        _validationError == null) {
                                      onboardingService.nextStep();
                                    }
                                  },
                                ),
                              ),

                              // URL preview below input
                              if (_usernameController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12.0,
                                    left: 24,
                                  ),
                                  child: Text(
                                    'jinnie.co/${_usernameController.text}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),

                              // Extra spacing to ensure URL is visible above keyboard
                              SizedBox(
                                height:
                                    MediaQuery.of(context).viewInsets.bottom > 0
                                        ? 200
                                        : 0,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: EdgeInsets.fromLTRB(
                24.0,
                0.0,
                24.0,
                bottomPadding + 16.0,
              ),
              child: Consumer<OnboardingService>(
                builder: (context, onboardingService, child) {
                  final canProceed =
                      onboardingService.canProceedFromCurrentStep() &&
                      _validationError == null &&
                      _usernameController.text.isNotEmpty;

                  return PrimaryButton(
                    text: 'app.continue'.tr(),
                    onPressed:
                        canProceed
                            ? () => _handleContinue(onboardingService)
                            : null,
                    isLoading: onboardingService.isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
