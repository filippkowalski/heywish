import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final firebaseUser = authService.firebaseUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!authService.isAnonymous)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryColor,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            if (authService.isAnonymous) ...[
              Text(
                'Welcome to HeyWish!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create an account to sync your wishlists\nacross all your devices',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.coralColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create Your Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Save wishlists permanently\n• Access from any device\n• Share with friends & family',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.push('/auth/signup');
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/auth/login');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Log In'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildGuestFeatures(context),
            ] else ...[
              Text(
                user?.name ?? firebaseUser?.displayName ?? 'User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              if (user?.email != null)
                Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 32),
              _buildProfileMenu(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: const Text('Edit Profile'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to notifications settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to help
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to about
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            final shouldSignOut = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (shouldSignOut == true && context.mounted) {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                context.go('/');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'As a guest, you can:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureTile(
            icon: Icons.list_alt,
            title: 'Create Wishlists',
            subtitle: 'Add unlimited wishlists and items',
          ),
          _buildFeatureTile(
            icon: Icons.share,
            title: 'Share with Others',
            subtitle: 'Generate shareable links instantly',
          ),
          _buildFeatureTile(
            icon: Icons.star_outline,
            title: 'Set Priorities',
            subtitle: 'Organize items by importance',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Note: Guest data is stored locally and may be lost',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}