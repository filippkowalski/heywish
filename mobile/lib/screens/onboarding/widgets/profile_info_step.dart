import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/text_input_field.dart';

class ProfileInfoStep extends StatefulWidget {
  const ProfileInfoStep({super.key});

  @override
  State<ProfileInfoStep> createState() => _ProfileInfoStepState();
}

class _ProfileInfoStepState extends State<ProfileInfoStep> {
  DateTime? _selectedBirthday;
  String? _selectedGender;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    
    // Pre-fill existing data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingService = context.read<OnboardingService>();
      if (onboardingService.data.birthday != null) {
        _selectedBirthday = onboardingService.data.birthday;
      }
      if (onboardingService.data.gender != null) {
        _selectedGender = onboardingService.data.gender;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectBirthday() async {
    final initialDate = _selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 20));
    final firstDate = DateTime(1950);
    final lastDate = DateTime.now().subtract(const Duration(days: 365 * 13)); // 13+ years old

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        _selectedBirthday = selectedDate;
      });
      context.read<OnboardingService>().updateBirthday(selectedDate);
    }
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
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'This helps us personalize your experience (all optional)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Birthday Selection
          GestureDetector(
            onTap: _selectBirthday,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.outline,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cake_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedBirthday != null
                          ? _formatDate(_selectedBirthday!)
                          : 'Select your birthday',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _selectedBirthday != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Birthday explanation
          Text(
            "We'll use this to notify your friends about your birthday",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Gender Selection
          Text(
            'Gender',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ..._genderOptions.map((gender) => _buildGenderOption(gender)),
          
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

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
        context.read<OnboardingService>().updateGender(gender);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              gender,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}