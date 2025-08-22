import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/text_input_field.dart';

class UsernameStep extends StatefulWidget {
  const UsernameStep({super.key});

  @override
  State<UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<UsernameStep> {
  final _usernameController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

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

  void _onUsernameChanged(String value) {
    final onboardingService = context.read<OnboardingService>();
    onboardingService.updateUsername(value);
    
    // Debounce the API call
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty) {
        onboardingService.checkUsernameAvailability(value);
      }
    });
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Choose your username',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'This is how friends will find and recognize you',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Username Input
          Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextInputField(
                          controller: _usernameController,
                          focusNode: _focusNode,
                          hintText: 'Enter username',
                          prefixText: '@',
                          onChanged: _onUsernameChanged,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (onboardingService.canProceedFromCurrentStep()) {
                              onboardingService.nextStep();
                            }
                          },
                        ),
                      ),
                      
                      // Inline loading indicator
                      if (onboardingService.isLoading) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status Message
                  if (onboardingService.usernameCheckResult != null)
                    Row(
                      children: [
                        Icon(
                          onboardingService.usernameCheckResult == 'Available'
                              ? Icons.check_circle
                              : onboardingService.usernameCheckResult == 'Username taken'
                                  ? Icons.error
                                  : Icons.info,
                          size: 16,
                          color: onboardingService.usernameCheckResult == 'Available'
                              ? Colors.green
                              : onboardingService.usernameCheckResult == 'Username taken'
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          onboardingService.usernameCheckResult!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: onboardingService.usernameCheckResult == 'Available'
                                ? Colors.green
                                : onboardingService.usernameCheckResult == 'Username taken'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    
                  // Username Suggestions
                  if (onboardingService.usernameSuggestions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Suggestions:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: onboardingService.usernameSuggestions
                              .map((suggestion) => _buildSuggestionChip(suggestion))
                              .toList(),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 40), // Less spacing since button is now fixed
                ],
              ),
            ),
          ),
        ),
        
        // Fixed bottom section
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          child: Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              return PrimaryButton(
                text: 'Continue',
                onPressed: onboardingService.canProceedFromCurrentStep()
                    ? onboardingService.nextStep
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _usernameController.text = suggestion;
        _onUsernameChanged(suggestion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outline,
            width: 1,
          ),
        ),
        child: Text(
          '@$suggestion',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}