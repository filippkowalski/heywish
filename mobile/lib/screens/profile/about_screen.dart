import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'profile.about'.tr(),
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

              // App Info Section
              _buildSection(
                context,
                'app.name'.tr().toUpperCase(),
                [
                  _buildInfoItem(
                    context,
                    Icons.info_outline,
                    'about.app_version'.tr(),
                    '1.0.0',
                  ),
                  _buildDivider(),
                  _buildInfoItem(
                    context,
                    Icons.copyright_outlined,
                    'about.copyright'.tr(),
                    '© 2025 Jinnie',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Legal Section
              _buildSection(
                context,
                'about.legal'.tr().toUpperCase(),
                [
                  _buildActionItem(
                    context,
                    Icons.description_outlined,
                    'about.terms_of_service'.tr(),
                    () => _launchUrl('https://jinnie.co/terms'),
                  ),
                  _buildDivider(),
                  _buildActionItem(
                    context,
                    Icons.privacy_tip_outlined,
                    'about.privacy_policy'.tr(),
                    () => _launchUrl('https://jinnie.co/privacy'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Support Section
              _buildSection(
                context,
                'about.support'.tr().toUpperCase(),
                [
                  _buildActionItem(
                    context,
                    Icons.email_outlined,
                    'about.contact_us'.tr(),
                    () => _launchUrl('mailto:support@jinnie.co'),
                  ),
                  _buildDivider(),
                  _buildActionItem(
                    context,
                    Icons.language_outlined,
                    'about.website'.tr(),
                    () => _launchUrl('https://jinnie.co'),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
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
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String title,
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFD1D1D6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 52),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE5E5EA),
      ),
    );
  }
}
