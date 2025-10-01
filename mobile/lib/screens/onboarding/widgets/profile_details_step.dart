import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class ProfileDetailsStep extends StatefulWidget {
  const ProfileDetailsStep({super.key});

  @override
  State<ProfileDetailsStep> createState() => _ProfileDetailsStepState();
}

class _ProfileDetailsStepState extends State<ProfileDetailsStep> {
  DateTime? _selectedDate;
  String? _selectedGender;

  final List<Map<String, dynamic>> _genderOptions = [
    {
      'label': 'profile.gender_male'.tr(),
      'icon': Icons.male,
      'color': const Color(0xFF3B82F6), // Blue
    },
    {
      'label': 'profile.gender_female'.tr(),
      'icon': Icons.female,
      'color': const Color(0xFFEC4899), // Pink
    },
    {
      'label': 'profile.gender_other'.tr(),
      'icon': Icons.transgender,
      'color': const Color(0xFF8B5CF6), // Purple
    },
    {
      'label': 'profile.gender_prefer_not_to_say'.tr(),
      'icon': Icons.lock_outline,
      'color': const Color(0xFF6B7280), // Gray
    },
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    final canContinue = _selectedDate != null && _selectedGender != null;

    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // App bar with Skip button
              Container(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: topPadding + 16.0,
                  bottom: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => onboardingService.nextStep(),
                      child: Text(
                        'app.skip'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 0.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'profile.details_title'.tr(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'profile.details_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 48),

                      // Birthday Section
                      _buildSectionHeader(
                        title: 'profile.birthday_label'.tr(),
                        subtitle: 'profile.birthday_why'.tr(),
                      ),

                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () => _selectDate(context, onboardingService),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _selectedDate != null
                                      ? AppColors.textPrimary.withValues(
                                        alpha: 0.2,
                                      )
                                      : AppColors.outline.withValues(
                                        alpha: 0.3,
                                      ),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color:
                                    _selectedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _selectedDate != null
                                      ? DateFormat(
                                        'MMMM dd, yyyy',
                                      ).format(_selectedDate!)
                                      : 'profile.birthday_placeholder'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _selectedDate != null
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Gender Section
                      _buildSectionHeader(
                        title: 'profile.gender_label'.tr(),
                        subtitle: 'profile.gender_why'.tr(),
                      ),

                      const SizedBox(height: 12),

                      Column(
                        children: [
                          for (int i = 0; i < _genderOptions.length; i++) ...[
                            _buildGenderOption(
                              _genderOptions[i]['label'],
                              _genderOptions[i]['icon'],
                              _genderOptions[i]['color'],
                              onboardingService,
                            ),
                            if (i < _genderOptions.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),
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
                child: PrimaryButton(
                  onPressed:
                      canContinue ? () => onboardingService.nextStep() : null,
                  text: 'app.continue'.tr(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    String gender,
    IconData icon,
    Color color,
    OnboardingService onboardingService,
  ) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
        onboardingService.updateGender(gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    OnboardingService onboardingService,
  ) async {
    await _showBeautifulSpinnerPicker(context, onboardingService);
  }

  Future<void> _showBeautifulSpinnerPicker(
    BuildContext context,
    OnboardingService onboardingService,
  ) async {
    DateTime tempDate =
        _selectedDate ??
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
              height: 380,
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
              child: Column(
                children: [
                  // Header with handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.outline.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Text('🎂', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'profile.birthday_label'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                              _selectedDate = tempDate;
                            });
                            onboardingService.updateBirthday(tempDate);
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'app.done'.tr(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Spinners
                  Expanded(
                    child: Stack(
                      children: [
                        // Selection highlight
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Center(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
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
                                itemExtent: 50,
                                squeeze: 1.1,
                                useMagnifier: true,
                                magnification: 1.15,
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
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
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
                                itemExtent: 50,
                                squeeze: 1.1,
                                useMagnifier: true,
                                magnification: 1.15,
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
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
                                itemExtent: 50,
                                squeeze: 1.1,
                                useMagnifier: true,
                                magnification: 1.15,
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
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textPrimary,
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

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
