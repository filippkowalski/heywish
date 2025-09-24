import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import '../../../services/onboarding_service.dart';
import '../../../common/theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../common/widgets/primary_button.dart';
import '../../../common/widgets/skip_button.dart';

class NotificationsStep extends StatefulWidget {
  const NotificationsStep({super.key});

  @override
  State<NotificationsStep> createState() => _NotificationsStepState();
}

class _NotificationsStepState extends State<NotificationsStep> {
  
  Future<void> _requestNotificationPermissionAndContinue() async {
    final onboardingService = context.read<OnboardingService>();
    
    try {
      if (Platform.isIOS) {
        // For iOS, check current status first
        debugPrint('🍎 Requesting iOS notification permission...');
        
        var currentStatus = await Permission.notification.status;
        debugPrint('🍎 Current notification permission status: $currentStatus');
        
        // If already permanently denied, show the settings dialog
        if (currentStatus == PermissionStatus.permanentlyDenied) {
          debugPrint('🍎 Notifications already permanently denied, showing settings dialog');
          if (mounted) {
            _showPermissionDeniedDialog();
            return; // Don't continue automatically
          }
        }
        
        // If denied (but not permanently), request permission
        if (currentStatus == PermissionStatus.denied) {
          final status = await Permission.notification.request();
          debugPrint('🍎 iOS notification permission request result: $status');
          
          // Handle the response
          if (status == PermissionStatus.permanentlyDenied) {
            if (mounted) {
              _showPermissionDeniedDialog();
              return; // Don't continue automatically
            }
          } else if (status == PermissionStatus.granted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Notifications enabled!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            }
          }
        } else if (currentStatus == PermissionStatus.granted) {
          debugPrint('🍎 Notifications already granted');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ Notifications already enabled!'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green.shade600,
              ),
            );
          }
        }
        
      } else {
        // Android approach
        debugPrint('🤖 Requesting Android notification permission...');
        final status = await Permission.notification.request();
        debugPrint('🤖 Android notification permission status: $status');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == PermissionStatus.granted 
                ? '✅ Notifications enabled!' 
                : '⚠️ Notifications ${status.toString()}'),
              duration: const Duration(seconds: 2),
              backgroundColor: status == PermissionStatus.granted
                ? Colors.green.shade600
                : Colors.orange.shade600,
            ),
          );
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification Permission'),
          content: const Text(
            'Notifications were previously denied. To enable them:\n\n'
            '1. Open iPhone Settings\n'
            '2. Find "HeyWish" in the app list\n'
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SkipButton(
              text: 'Skip',
              onPressed: () {
                context.read<OnboardingService>().nextStep();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                        'Stay in the loop',
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
                        'Get notified about friend\'s birthdays, coupons, and price discounts.',
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
                
                const SizedBox(height: 32),
                
                // Notification options
                Consumer<OnboardingService>(
                  builder: (context, onboardingService, child) {
                    return Column(
                      children: [
                        _buildNotificationOption(
                          'Friend\'s Birthdays',
                          'Get notified when your friends have birthdays.',
                          onboardingService.data.notificationPreferences['birthday_notifications'] ?? true,
                          (value) => _toggleNotificationPreference('birthday_notifications', value),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildNotificationOption(
                          'Coupons',
                          'Get notified when coupons are available.',
                          onboardingService.data.notificationPreferences['coupon_notifications'] ?? false,
                          (value) => _toggleNotificationPreference('coupon_notifications', value),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildNotificationOption(
                          'Price Discounts',
                          'Get notified when prices drop on items you\'re watching.',
                          onboardingService.data.notificationPreferences['discount_notifications'] ?? true,
                          (value) => _toggleNotificationPreference('discount_notifications', value),
                        ),
                      ],
                    );
                  },
                ),
                    
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
            
            // Bottom section
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: Column(
                children: [
                  // Permission warning text
                  Text(
                    'You will be asked for notification permission',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Continue Button
                  PrimaryButton(
                    text: 'Continue',
                    onPressed: _requestNotificationPermissionAndContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
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
            onChanged: onChanged,
            activeColor: AppTheme.primaryAccent,
            activeTrackColor: AppTheme.primaryAccent.withOpacity(0.3),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}