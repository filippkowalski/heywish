import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../common/widgets/primary_button.dart';

class NotificationsStep extends StatefulWidget {
  const NotificationsStep({super.key});

  @override
  State<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<NotificationsStep> {
  bool _systemNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkSystemNotificationStatus();
  }

  Future<void> _checkSystemNotificationStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _systemNotificationsEnabled = status == PermissionStatus.granted;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _systemNotificationsEnabled = status == PermissionStatus.granted;
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
            'Stay in the loop',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Get notified about birthdays, special deals, and friend activity',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // System Notifications Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _systemNotificationsEnabled 
                  ? AppColors.primaryLight.withOpacity(0.5)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _systemNotificationsEnabled 
                    ? AppColors.primary
                    : AppColors.outline,
                width: _systemNotificationsEnabled ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _systemNotificationsEnabled 
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  size: 48,
                  color: _systemNotificationsEnabled 
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _systemNotificationsEnabled
                      ? 'Notifications enabled!'
                      : 'Enable notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _systemNotificationsEnabled 
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _systemNotificationsEnabled
                      ? 'You\'ll receive important updates and reminders'
                      : 'Tap to allow notifications in your device settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (!_systemNotificationsEnabled) ...[
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: _requestNotificationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Enable Notifications'),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Notification Preferences
          Text(
            'What would you like to be notified about?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Consumer<OnboardingService>(
            builder: (context, onboardingService, child) {
              return Column(
                children: [
                  _buildNotificationOption(
                    context,
                    'birthday_notifications',
                    'Friend birthdays',
                    'Get reminded when it\'s your friends\' birthdays',
                    Icons.cake_outlined,
                    onboardingService.data.notificationPreferences['birthday_notifications'] ?? true,
                    onboardingService,
                  ),
                  
                  _buildNotificationOption(
                    context,
                    'coupon_notifications',
                    'Coupons & deals',
                    'Special discounts on items in your wishlists',
                    Icons.local_offer_outlined,
                    onboardingService.data.notificationPreferences['coupon_notifications'] ?? true,
                    onboardingService,
                  ),
                  
                  _buildNotificationOption(
                    context,
                    'discount_notifications',
                    'Price drops',
                    'When items on your wishlist go on sale',
                    Icons.trending_down,
                    onboardingService.data.notificationPreferences['discount_notifications'] ?? true,
                    onboardingService,
                  ),
                  
                  _buildNotificationOption(
                    context,
                    'friend_activity',
                    'Friend activity',
                    'When friends create new wishlists or add items',
                    Icons.people_outline,
                    onboardingService.data.notificationPreferences['friend_activity'] ?? true,
                    onboardingService,
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
          child: Column(
            children: [
              // Continue Button
              Consumer<OnboardingService>(
                builder: (context, onboardingService, child) {
                  return PrimaryButton(
                    text: 'Continue',
                    onPressed: onboardingService.nextStep,
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // Skip Button
              TextButton(
                onPressed: () {
                  context.read<OnboardingService>().nextStep();
                },
                child: Text(
                  'Skip for now',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationOption(
    BuildContext context,
    String key,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    OnboardingService onboardingService,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            icon,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              onboardingService.updateNotificationPreference(key, newValue);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}