import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/fcm_service.dart';
import '../../theme/app_theme.dart';
import '../../common/navigation/native_page_route.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _isLoading = true;
  bool _permissionGranted = false;

  // Notification preferences - will be loaded from backend later
  bool _birthdayNotifications = true;
  bool _couponNotifications = false;
  bool _discountNotifications = true;
  bool _friendRequestNotifications = true;
  bool _wishlistActivityNotifications = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      setState(() {
        _permissionGranted = status.isGranted || status.isProvisional;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final granted = await FCMService().requestPermission();
      setState(() {
        _permissionGranted = granted;
      });

      if (!granted && mounted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('❌ Error requesting permission: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    NativeTransitions.showNativeDialog(
      context: context,
      child: AlertDialog(
        title: Text('settings.notifications_permission_required'.tr()),
        content: Text('settings.notifications_permission_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('app.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('settings.open_settings'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'settings.notifications'.tr(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryAccent, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Permission status section
                    _buildPermissionSection(),

                    const SizedBox(height: 32),

                    // Notification channels section (only if permission granted)
                    if (_permissionGranted) ...[
                      _buildNotificationChannelsSection(),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPermissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text(
            'settings.permission_status'.tr().toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6D72),
              letterSpacing: -0.08,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _permissionGranted
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFFF3B30).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _permissionGranted ? Icons.notifications_active : Icons.notifications_off,
                  color: _permissionGranted ? const Color(0xFF10B981) : const Color(0xFFFF3B30),
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _permissionGranted
                          ? 'settings.notifications_enabled'.tr()
                          : 'settings.notifications_disabled'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _permissionGranted
                          ? 'settings.notifications_enabled_desc'.tr()
                          : 'settings.notifications_disabled_desc'.tr(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Enable button (only if disabled)
              if (!_permissionGranted)
                ElevatedButton(
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'settings.enable'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationChannelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text(
            'settings.notification_types'.tr().toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6D72),
              letterSpacing: -0.08,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildNotificationToggle(
                icon: '🎂',
                title: 'settings.birthday_notifications'.tr(),
                subtitle: 'settings.birthday_notifications_desc'.tr(),
                value: _birthdayNotifications,
                onChanged: (value) => setState(() => _birthdayNotifications = value),
                color: const Color(0xFFEC4899),
              ),
              _buildDivider(),
              _buildNotificationToggle(
                icon: '👥',
                title: 'settings.friend_request_notifications'.tr(),
                subtitle: 'settings.friend_request_notifications_desc'.tr(),
                value: _friendRequestNotifications,
                onChanged: (value) => setState(() => _friendRequestNotifications = value),
                color: const Color(0xFF8B5CF6),
              ),
              _buildDivider(),
              _buildNotificationToggle(
                icon: '🎁',
                title: 'settings.wishlist_activity_notifications'.tr(),
                subtitle: 'settings.wishlist_activity_notifications_desc'.tr(),
                value: _wishlistActivityNotifications,
                onChanged: (value) => setState(() => _wishlistActivityNotifications = value),
                color: const Color(0xFF3B82F6),
              ),
              _buildDivider(),
              _buildNotificationToggle(
                icon: '💰',
                title: 'settings.discount_notifications'.tr(),
                subtitle: 'settings.discount_notifications_desc'.tr(),
                value: _discountNotifications,
                onChanged: (value) => setState(() => _discountNotifications = value),
                color: const Color(0xFF10B981),
              ),
              _buildDivider(),
              _buildNotificationToggle(
                icon: '🎟️',
                title: 'settings.coupon_notifications'.tr(),
                subtitle: 'settings.coupon_notifications_desc'.tr(),
                value: _couponNotifications,
                onChanged: (value) => setState(() => _couponNotifications = value),
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha: 0.15) : const Color(0xFFF2F2F7),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
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

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 58),
      height: 0.5,
      color: const Color(0xFFC6C6C8),
    );
  }
}
