import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../friends/friends_screen.dart';
import '../../widgets/cached_image.dart';
import '../../common/navigation/native_page_route.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'wishlist_management_screen.dart';
import '../onboarding/widgets/sign_in_bottom_sheet.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSearch;

  const ProfileScreen({super.key, this.onNavigateToSearch});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
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
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 40,
                    color: AppTheme.primaryAccent,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'auth.sign_in_title'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'auth.sign_in_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Sign In Button
                SizedBox(
                  width: double.infinity,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'auth.sign_in'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

          const SizedBox(height: 28),

          // Stats section - now full width and properly spaced
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('0', 'profile.wishlists_count'.tr()),
                _buildStatDivider(),
                _buildStatItem('0', 'profile.friends_count'.tr()),
                _buildStatDivider(),
                _buildStatItem('0', 'profile.wishes_count'.tr()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE5E5EA),
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

}
