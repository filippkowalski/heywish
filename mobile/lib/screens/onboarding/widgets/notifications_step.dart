import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../services/onboarding_service.dart';
import '../../../services/fcm_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/navigation/native_page_route.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsStep extends StatefulWidget {
  const NotificationsStep({super.key});

  @override
  State<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<NotificationsStep> {
  Future<void> _requestNotificationPermissionAndContinue() async {
    final onboardingService = context.read<OnboardingService>();

    try {
      // Use FCM's own permission request (it handles both iOS and Android properly)
      debugPrint('📱 Requesting notification permission via FCM...');

      final granted = await FCMService().requestPermission();

      if (granted) {
        debugPrint('✅ Notification permission granted and token registered');
      } else {
        debugPrint('⚠️ Notification permission denied');

        // Check if permanently denied on iOS
        if (Platform.isIOS) {
          final currentStatus = await Permission.notification.status;
          if (currentStatus == PermissionStatus.permanentlyDenied) {
            if (mounted) {
              _showPermissionDeniedDialog();
              return; // Don't continue automatically
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
    }

    // Small delay to ensure permission dialog is handled
    await Future.delayed(const Duration(milliseconds: 500));

    // Continue to next step regardless of permission result
    onboardingService.nextStep();
  }

  void _toggleNotificationPreference(String key, bool value) {
    context.read<OnboardingService>().updateNotificationPreference(key, value);
  }

  void _showPermissionDeniedDialog() {
    NativeTransitions.showNativeDialog(
      context: context,
      child: AlertDialog(
        title: const Text('Notification Permission'),
        content: const Text(
          'Notifications were previously denied. To enable them:\n\n'
          '1. Open iPhone Settings\n'
          '2. Find "Jinnie" in the app list\n'
          '3. Tap "Notifications"\n'
          '4. Turn on "Allow Notifications"\n\n'
          'You can continue without notifications for now.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue with onboarding
              context.read<OnboardingService>().nextStep();
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open iOS settings
              Permission.notification.request().then((_) {
                openAppSettings();
              });
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        return Container(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Top section with skip button
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => onboardingService.nextStep(),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.all(12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'app.skip'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
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
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 0.0,
                    bottom: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      const Text(
                        'Stay in the loop 🔔',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'Get notified about friend\'s birthdays, coupons, and price discounts',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 32),

                      // Notification options
                      _buildNotificationOption(
                        icon: '🎂',
                        title: 'Friend\'s Birthdays',
                        subtitle: 'Get notified when your friends have birthdays',
                        value:
                            onboardingService
                                .data
                                .notificationPreferences['birthday_notifications'] ??
                            true,
                        onChanged:
                            (value) => _toggleNotificationPreference(
                              'birthday_notifications',
                              value,
                            ),
                        color: const Color(0xFFEC4899), // Pink
                      ),

                      const SizedBox(height: 8),

                      _buildNotificationOption(
                        icon: '🎟️',
                        title: 'Coupons',
                        subtitle: 'Get notified when coupons are available',
                        value:
                            onboardingService
                                .data
                                .notificationPreferences['coupon_notifications'] ??
                            false,
                        onChanged:
                            (value) => _toggleNotificationPreference(
                              'coupon_notifications',
                              value,
                            ),
                        color: const Color(0xFF10B981), // Green
                      ),

                      const SizedBox(height: 8),

                      _buildNotificationOption(
                        icon: '💰',
                        title: 'Price Discounts',
                        subtitle: 'Get notified when prices drop on items you\'re watching',
                        value:
                            onboardingService
                                .data
                                .notificationPreferences['discount_notifications'] ??
                            true,
                        onChanged:
                            (value) => _toggleNotificationPreference(
                              'discount_notifications',
                              value,
                            ),
                        color: const Color(0xFF3B82F6), // Blue
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Fixed footer
              Container(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 0.0,
                  bottom: 16.0,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Permission info text
                    const Text(
                      'You will be asked for notification permission',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Continue button
                    PrimaryButton(
                      text: 'Enable Notifications',
                      onPressed: _requestNotificationPermissionAndContinue,
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationOption({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              value
                  ? color.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  value
                      ? color.withValues(alpha: 0.15)
                      : AppColors.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),

          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Toggle switch
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
