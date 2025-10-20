import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class BirthdayStep extends StatefulWidget {
  const BirthdayStep({super.key});

  @override
  State<BirthdayStep> createState() => _BirthdayStepState();
}

class _BirthdayStepState extends State<BirthdayStep> {
  DateTime selectedDate = DateTime(2000, 1, 1);

  @override
  void initState() {
    super.initState();
    
    // Pre-fill if birthday already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingService = context.read<OnboardingService>();
      if (onboardingService.data.birthday != null) {
        setState(() {
          selectedDate = onboardingService.data.birthday!;
        });
      }
    });
  }

  void _updateBirthday(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    context.read<OnboardingService>().updateBirthday(date);
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
                        'When\'s your birthday?',
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
                        'We\'ll use this to remind your friends about your birthday.',
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
                
                const SizedBox(height: 48),
                
                // Native date picker
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Platform.isIOS
                      ? CupertinoTheme(
                          data: CupertinoThemeData(
                            brightness: Brightness.light,
                            primaryColor: AppColors.textPrimary,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: TextStyle(
                                fontSize: 18,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: selectedDate,
                            minimumDate: DateTime(1950),
                            maximumDate: DateTime.now(),
                            onDateTimeChanged: _updateBirthday,
                          ),
                        )
                      : Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppColors.textPrimary,
                              onSurface: AppColors.textPrimary,
                              surface: Colors.white,
                            ),
                            textTheme: Theme.of(context).textTheme.copyWith(
                              bodyLarge: TextStyle(color: AppColors.textPrimary),
                              bodyMedium: TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                            onDateChanged: _updateBirthday,
                          ),
                        ),
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