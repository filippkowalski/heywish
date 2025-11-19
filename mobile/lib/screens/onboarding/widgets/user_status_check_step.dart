import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/rotating_loading_messages.dart';

class UserStatusCheckStep extends StatelessWidget {
  const UserStatusCheckStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          RotatingLoadingMessages(
            messages: [
              'onboarding.checking_profile_1'.tr(),
              'onboarding.checking_profile_2'.tr(),
              'onboarding.checking_profile_3'.tr(),
              'onboarding.checking_profile_4'.tr(),
              'onboarding.checking_profile_5'.tr(),
            ],
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            messageDuration: const Duration(seconds: 3),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ],
      ),
    );
  }
}