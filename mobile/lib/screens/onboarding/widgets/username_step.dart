import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:async';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/platform_loader.dart';

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
    
    // Pre-fill if username already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingService = context.read<OnboardingService>();
      if (onboardingService.data.username != null) {
        _usernameController.text = onboardingService.data.username!;
      }
    });
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
      return 'Username must be at least 3 characters';
    }
    
    if (username.length > 30) {
      return 'Username must be 30 characters or less';
    }
    
    // Check for spaces
    if (username.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    
    // Check for invalid characters (Instagram allows letters, numbers, underscores, and periods)
    final validPattern = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!validPattern.hasMatch(username)) {
      return 'Username can only contain letters, numbers, periods, and underscores';
    }
    
    // Cannot start or end with period
    if (username.startsWith('.') || username.endsWith('.')) {
      return 'Username cannot start or end with a period';
    }
    
    // Cannot have consecutive periods
    if (username.contains('..')) {
      return 'Username cannot have consecutive periods';
    }
    
    return null; // Valid
  }

  /// Clean and format username input
  String _cleanUsername(String input) {
    // Remove spaces and convert to lowercase
    return input.replaceAll(' ', '').toLowerCase();
  }

  void _onUsernameChanged(String value) {
    final onboardingService = context.read<OnboardingService>();
    
    // Clean the input (remove spaces, convert to lowercase)
    final cleanedValue = _cleanUsername(value);
    
    // Update the text field if it was cleaned
    if (cleanedValue != value) {
      final cursorPosition = _usernameController.selection.baseOffset;
      _usernameController.value = TextEditingValue(
        text: cleanedValue,
        selection: TextSelection.collapsed(
          offset: cursorPosition > cleanedValue.length 
              ? cleanedValue.length 
              : cursorPosition,
        ),
      );
    }
    
    // Validate the username
    final validationError = _validateUsername(cleanedValue);
    setState(() {
      _validationError = validationError;
    });
    
    onboardingService.updateUsername(cleanedValue);
    
    // Only check availability if username is valid
    _debounceTimer?.cancel();
    if (validationError == null && cleanedValue.isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        onboardingService.checkUsernameAvailability(cleanedValue);
      });
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
        return '✓ Username is available';
      } else {
        return onboardingService.usernameCheckResult!;
      }
    }
    
    // Show checking status
    if (onboardingService.isLoading) {
      return 'Checking availability...';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main content - centered
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    
                    // Main title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AutoSizeText(
                        'Choose your username',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                        'This is your unique username that your friends can find you with',
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(onboardingService),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        // Username field with inline loader
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            focusNode: _focusNode,
                            onChanged: _onUsernameChanged,
                            textAlign: TextAlign.center,
                            maxLength: 30,
                            inputFormatters: [
                              // Filter out spaces and convert to lowercase
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              LowerCaseTextFormatter(),
                              // Only allow letters, numbers, periods, and underscores
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                            ],
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'username',
                              counterText: '', // Hide character counter
                              hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textSecondary.withOpacity(0.5),
                                fontWeight: FontWeight.w400,
                                fontSize: 20,
                              ),
                              suffixIcon: onboardingService.isLoading && _validationError == null
                                  ? Container(
                                      width: 20,
                                      height: 20,
                                      padding: const EdgeInsets.all(12),
                                      child: PlatformLoader(
                                        size: 16,
                                        color: AppColors.primary.withOpacity(0.6),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (onboardingService.canProceedFromCurrentStep() && _validationError == null) {
                                onboardingService.nextStep();
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
            
            // Bottom button - keep as is
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
              child: Consumer<OnboardingService>(
                builder: (context, onboardingService, child) {
                  final canProceed = onboardingService.canProceedFromCurrentStep() && 
                                   _validationError == null &&
                                   _usernameController.text.isNotEmpty;
                  
                  return PrimaryButton(
                    text: 'Continue',
                    onPressed: canProceed ? onboardingService.nextStep : null,
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