import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../common/widgets/confirmation_bottom_sheet.dart';
import '../../common/navigation/native_page_route.dart';
import '../feedback/feedback_sheet_page.dart';
import 'privacy_settings_screen.dart';
import 'notifications_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS light gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'profile.settings'.tr(),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildMenuSection(
                context,
                'profile.settings'.tr().toUpperCase(),
                [
                  _buildLanguageMenuItem(context),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.notifications_none_outlined,
                    'profile.notifications'.tr(),
                    'profile.notifications_subtitle'.tr(),
                    () => _navigateToNotificationsSettings(context),
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.lock_outline,
                    'profile.privacy_security'.tr(),
                    'profile.privacy_subtitle'.tr(),
                    () => _navigateToPrivacySettings(context),
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'profile.help_support'.tr(),
                    'profile.help_subtitle'.tr(),
                    () => _openHelpSupport(context),
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.info_outline,
                    'profile.about'.tr(),
                    'profile.about_subtitle'.tr(),
                    () => _navigateToAbout(context),
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.feedback_outlined,
                    'feedback.title'.tr(),
                    'quick_actions.feedback_subtitle'.tr(),
                    () => _showFeedbackSheet(context),
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.attach_money_outlined,
                    'profile.affiliate_disclosure'.tr(),
                    'profile.affiliate_disclosure_subtitle'.tr(),
                    () => _showAffiliateDisclosure(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSignOutSection(context),
              const SizedBox(height: 32),
              _buildDangerZoneSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6D72), // iOS section header gray
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
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 52),
      height: 0.5,
      color: const Color(0xFFC6C6C8), // iOS separator color
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93), // iOS gray
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7CC), // iOS chevron color
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text(
            'DANGER ZONE',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6D6D72), // iOS section header gray
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeleteAccountDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_outlined,
                      color: Color(0xFFFF3B30), // iOS red
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.delete_account'.tr(),
                            style: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFFFF3B30), // iOS red
                            ),
                          ),
                          Text(
                            'profile.delete_account_subtitle'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93), // iOS gray
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFC7C7CC), // iOS chevron color
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAccountDialog(),
    );
  }

  Widget _buildLanguageMenuItem(BuildContext context) {
    // Get current language name
    String getCurrentLanguageName() {
      final locale = context.locale;
      if (locale.languageCode == 'en') return 'English';
      if (locale.languageCode == 'de') return 'Deutsch';
      if (locale.languageCode == 'es') return 'Español';
      if (locale.languageCode == 'fr') return 'Français';
      if (locale.languageCode == 'pt') return 'Português';
      return 'English';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageSelector(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              const Icon(
                Icons.language_outlined,
                color: AppTheme.primaryAccent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.language'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      getCurrentLanguageName(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93), // iOS gray
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC7C7CC), // iOS chevron color
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languages = [
      {'code': 'en', 'country': null, 'name': 'English', 'nativeName': 'English'},
      {'code': 'de', 'country': null, 'name': 'German', 'nativeName': 'Deutsch'},
      {'code': 'es', 'country': null, 'name': 'Spanish', 'nativeName': 'Español'},
      {'code': 'fr', 'country': null, 'name': 'French', 'nativeName': 'Français'},
      {'code': 'pt', 'country': 'BR', 'name': 'Portuguese', 'nativeName': 'Português (Brasil)'},
    ];

    NativeTransitions.showNativeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'settings.select_language'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scrollable language options
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: languages.map((lang) {
              final locale = lang['country'] != null
                  ? Locale(lang['code'] as String, lang['country'] as String)
                  : Locale(lang['code'] as String);
              final isSelected = context.locale == locale;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await context.setLocale(locale);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryAccent.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryAccent.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['nativeName'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.primaryAccent
                                          : AppTheme.primary,
                                    ),
                                  ),
                                  Text(
                                    lang['name'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.primaryAccent,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (lang != languages.last) const SizedBox(height: 12),
                ],
              );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    Navigator.of(context).push(
      NativePageRoute(
        child: const FeedbackSheetPage(
          clickSource: 'settings',
        ),
      ),
    );
  }

  void _navigateToPrivacySettings(BuildContext context) {
    Navigator.of(context).push(
      NativePageRoute(
        child: const PrivacySettingsScreen(),
      ),
    );
  }

  void _navigateToNotificationsSettings(BuildContext context) {
    Navigator.of(context).push(
      NativePageRoute(
        child: const NotificationsSettingsScreen(),
      ),
    );
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.of(context).push(
      NativePageRoute(
        child: const AboutScreen(),
      ),
    );
  }

  Future<void> _openHelpSupport(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'bobbyfisher77+jinnie@icloud.com',
      query: 'subject=Jinnie Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile.email_support_error'.tr()),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app. Please email us at bobbyfisher77+jinnie@icloud.com'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAffiliateDisclosure(BuildContext context) {
    NativeTransitions.showNativeModalBottomSheet(
      context: context,
      isScrollControlled: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          40 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Icon and Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.attach_money_rounded,
                      color: AppTheme.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          'profile.affiliate_disclosure_title'.tr(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Content Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  'profile.affiliate_disclosure_content'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'app.done'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final shouldSignOut = await ConfirmationBottomSheet.show<bool>(
              context: context,
              title: 'profile.sign_out_confirm_title'.tr(),
              message: 'profile.sign_out_confirm_message'.tr(),
              confirmText: 'auth.sign_out'.tr(),
              cancelText: 'app.cancel'.tr(),
              icon: Icons.logout,
              confirmColor: AppTheme.error,
              isDestructive: true,
            );

            if (shouldSignOut == true && context.mounted) {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                context.go('/');
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'auth.sign_out'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFFFF3B30), // iOS red
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _countdown = 5;
  Timer? _timer;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    final authService = context.read<AuthService>();
    final success = await authService.deleteAccount();

    if (success && mounted) {
      context.read<OnboardingService>().reset();
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // Pop settings screen too
      context.go('/');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.account_deleted'.tr()),
          backgroundColor: AppTheme.primaryAccent,
        ),
      );
    } else if (mounted) {
      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.account_delete_failed'.tr()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: AppTheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'profile.delete_account_title'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.delete_account_warning'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ${'profile.delete_account_list_wishlists'.tr()}'),
              Text('• ${'profile.delete_account_list_profile'.tr()}'),
              Text('• ${'profile.delete_account_list_friends'.tr()}'),
              Text('• ${'profile.delete_account_list_activity'.tr()}'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'profile.delete_account_info'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: Text('app.cancel'.tr()),
        ),
        FilledButton(
          onPressed: _countdown > 0 || _isDeleting ? null : _deleteAccount,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.error,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _countdown > 0
                      ? 'profile.delete_in_countdown'.tr(namedArgs: {'seconds': _countdown.toString()})
                      : 'profile.delete_forever'.tr(),
                ),
        ),
      ],
    );
  }
}
