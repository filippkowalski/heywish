import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../common/theme/app_colors.dart';

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
          Text(
            'onboarding.checking_profile'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}