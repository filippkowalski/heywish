import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class GenderStep extends StatefulWidget {
  const GenderStep({super.key});

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  String? selectedGender;

  final List<Map<String, dynamic>> genderOptions = [
    {'value': 'female', 'label': 'Woman', 'icon': '👩'},
    {'value': 'male', 'label': 'Man', 'icon': '👨'},
    {'value': 'non_binary', 'label': 'Non-binary', 'icon': '🌟'},
    {'value': 'prefer_not_to_say', 'label': 'Prefer not to say', 'icon': '✨'},
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill if gender already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingService = context.read<OnboardingService>();
      if (onboardingService.data.gender != null) {
        setState(() {
          selectedGender = onboardingService.data.gender;
        });
      }
    });
  }

  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
    context.read<OnboardingService>().updateGender(gender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top section with skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: () {
                    context.read<OnboardingService>().nextStep();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
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
                        'How do you identify?',
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
                        'This helps us personalize your experience',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        minFontSize: 13,
                        maxFontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Gender options
                    Column(
                      children:
                          genderOptions.map((option) {
                            final isSelected =
                                selectedGender == option['value'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectGender(option['value']),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1)
                                              : Colors.white,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.1)
                                                    : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              option['icon'],
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            option['label'],
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              color:
                                                  isSelected
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  context.read<OnboardingService>().nextStep();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
