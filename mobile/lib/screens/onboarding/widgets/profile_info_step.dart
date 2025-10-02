import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

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
    DateTime tempDate =
        _selectedBirthday ??
        DateTime.now().subtract(const Duration(days: 365 * 20));

    // Generate lists for spinners
    final months = List.generate(
      12,
      (index) => DateFormat.MMMM().format(DateTime(2000, index + 1)),
    );
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (index) => currentYear - index);

    int selectedMonth = tempDate.month - 1;
    int selectedDay = tempDate.day - 1;
    int selectedYear = years.indexOf(tempDate.year);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with handle
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title section with improved spacing
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🎂',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Select Birthday',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              tempDate = DateTime(
                                years[selectedYear],
                                selectedMonth + 1,
                                (selectedDay + 1).clamp(
                                  1,
                                  DateTime(
                                    years[selectedYear],
                                    selectedMonth + 2,
                                    0,
                                  ).day,
                                ),
                              );
                              setState(() {
                                _selectedBirthday = tempDate;
                              });
                              context.read<OnboardingService>().updateBirthday(
                                tempDate,
                              );
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subtle divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Spinners with improved layout
                    SizedBox(
                      height: 240,
                      child: Stack(
                        children: [
                          // Enhanced selection highlight with gradient
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                height: 48,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.06),
                                      AppColors.primary.withValues(alpha: 0.12),
                                      AppColors.primary.withValues(alpha: 0.06),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Top fade gradient
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom fade gradient
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Spinners row
                          Row(
                            children: [
                              // Month spinner
                              Expanded(
                                flex: 3,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: selectedMonth,
                                  ),
                                  itemExtent: 48,
                                  squeeze: 1.05,
                                  useMagnifier: true,
                                  magnification: 1.1,
                                  diameterRatio: 1.5,
                                  onSelectedItemChanged: (int index) {
                                    setModalState(() {
                                      selectedMonth = index;
                                      // Adjust day if invalid for new month
                                      final maxDays =
                                          DateTime(
                                            years[selectedYear],
                                            index + 2,
                                            0,
                                          ).day;
                                      if (selectedDay >= maxDays) {
                                        selectedDay = maxDays - 1;
                                      }
                                    });
                                  },
                                  children:
                                      months
                                          .map(
                                            (month) => Center(
                                              child: Text(
                                                month,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),

                              // Day spinner
                              Expanded(
                                flex: 2,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: selectedDay,
                                  ),
                                  itemExtent: 48,
                                  squeeze: 1.05,
                                  useMagnifier: true,
                                  magnification: 1.1,
                                  diameterRatio: 1.5,
                                  onSelectedItemChanged: (int index) {
                                    setModalState(() {
                                      selectedDay = index;
                                    });
                                  },
                                  children: List.generate(
                                    DateTime(
                                      years[selectedYear],
                                      selectedMonth + 2,
                                      0,
                                    ).day,
                                    (index) => Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Year spinner
                              Expanded(
                                flex: 2,
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: selectedYear,
                                  ),
                                  itemExtent: 48,
                                  squeeze: 1.05,
                                  useMagnifier: true,
                                  magnification: 1.1,
                                  diameterRatio: 1.5,
                                  onSelectedItemChanged: (int index) {
                                    setModalState(() {
                                      selectedYear = index;
                                      // Adjust day if invalid for new year (leap year changes)
                                      final maxDays =
                                          DateTime(
                                            years[index],
                                            selectedMonth + 2,
                                            0,
                                          ).day;
                                      if (selectedDay >= maxDays) {
                                        selectedDay = maxDays - 1;
                                      }
                                    });
                                  },
                                  children:
                                      years
                                          .map(
                                            (year) => Center(
                                              child: Text(
                                                '$year',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textPrimary,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
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
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color:
                                    _selectedBirthday != null
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

                  const SizedBox(
                    height: 40,
                  ), // Less spacing since button is now fixed
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
                onPressed:
                    onboardingService.canProceedFromCurrentStep()
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
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
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
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
