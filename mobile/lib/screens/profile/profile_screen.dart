import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import '../../services/friends_service.dart';
import '../../theme/app_theme.dart';
import '../friends/friends_screen.dart';
import '../../widgets/cached_image.dart';
import '../../common/navigation/native_page_route.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'wishlist_management_screen.dart';
import '../onboarding/widgets/sign_in_bottom_sheet.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSearch;

  const ProfileScreen({super.key, this.onNavigateToSearch});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final friendsService = context.watch<FriendsService>();
    final user = authService.currentUser;
    final firebaseUser = authService.firebaseUser;

    // Check if user is anonymous
    if (firebaseUser != null && firebaseUser.isAnonymous) {
      return _buildSignInPrompt(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context, user),
              const SizedBox(height: 8),
              _buildMenuSection(
                context,
                'profile.account'.tr().toUpperCase(),
                [
                  _buildMenuItem(
                    context,
                    Icons.person_outline,
                    'profile.edit_profile'.tr(),
                    'profile.edit_profile_subtitle'.tr(),
                    () {
                      context.pushNative(const EditProfileScreen());
                    },
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.people_outline,
                    'profile.friends'.tr(),
                    'profile.friends_subtitle'.tr(),
                    () {
                      context.pushNative(
                        FriendsScreen(
                          onNavigateToSearch: () {
                            Navigator.of(context).pop();
                            onNavigateToSearch?.call();
                          },
                        ),
                      );
                    },
                    badgeCount: friendsService.pendingRequestsCount,
                  ),
                  _buildMenuDivider(),
                  _buildMenuItem(
                    context,
                    Icons.list_alt_outlined,
                    'profile.wishlist_management'.tr(),
                    'profile.wishlist_management_subtitle'.tr(),
                    () {
                      context.pushNative(const WishlistManagementScreen());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Text(
                      'profile.anonymous_teaser'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'profile.sign_in_title'.tr(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'profile.sign_in_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF8E8E93),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Benefits cards - more compact
                    _buildProfileBenefitCard(
                      icon: Icons.person_outline,
                      iconColor: AppTheme.primaryAccent,
                      title: 'profile.benefit_username'.tr(),
                      subtitle: 'profile.benefit_username_subtitle'.tr(),
                    ),
                    const SizedBox(height: 12),

                    _buildProfileBenefitCard(
                      icon: Icons.layers_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'profile.benefit_sync'.tr(),
                      subtitle: 'profile.benefit_sync_subtitle'.tr(),
                    ),
                    const SizedBox(height: 12),

                    _buildProfileBenefitCard(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'profile.benefit_friends'.tr(),
                      subtitle: 'profile.benefit_friends_subtitle'.tr(),
                    ),
                    const SizedBox(height: 12),

                    _buildProfileBenefitCard(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: 'profile.benefit_secure'.tr(),
                      subtitle: 'profile.benefit_secure_subtitle'.tr(),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Sign In Button at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    SignInBottomSheet.show(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'auth.sign_in'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBenefitCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Title and Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () {
                  context.pushNative(const SettingsScreen());
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Avatar and user info section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with edit button
              GestureDetector(
                onTap: () {
                  context.pushNative(const EditProfileScreen());
                },
                child: Stack(
                  children: [
                    CachedAvatarImage(
                      imageUrl: user?.avatarUrl,
                      radius: 48,
                      backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Name and username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (user?.username != null)
                      Text(
                        '@${user!.username}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8E8E93),
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Bio section
          if (user?.bio != null && user!.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Email
          if (user?.email != null)
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: Color(0xFF8E8E93),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    user!.email!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Profile Visibility
          if (user != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to Privacy Settings
                  Navigator.of(context).push(
                    NativePageRoute(
                      child: const PrivacySettingsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        user.isProfilePublic ? Icons.public : Icons.lock_outline,
                        size: 18,
                        color: user.isProfilePublic ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.isProfilePublic
                            ? 'profile.profile_public'.tr()
                            : 'profile.profile_private'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            color: user.isProfilePublic ? Colors.green.shade600 : Colors.orange.shade600,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: const Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    color: AppTheme.primaryAccent,
                    size: 24,
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
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

}
