import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../friends/friends_screen.dart';
import '../activity_screen.dart';
import '../../widgets/cached_image.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onNavigateToSearch;
  
  const ProfileScreen({super.key, this.onNavigateToSearch});

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
              icon: Icon(Icons.settings),
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
            CachedAvatarImage(
              imageUrl: user?.avatarUrl,
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.blue.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
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
          leading: Icon(Icons.people_outline),
          title: const Text('Friends'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => FriendsScreen(
                  onNavigateToSearch: () {
                    Navigator.of(context).pop();
                    onNavigateToSearch?.call();
                  },
                ),
              ),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: const Text('Activity'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ActivityScreen(),
              ),
            );
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.person_outline),
          title: const Text('Edit Profile'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to edit profile
          },
        ),
        ListTile(
          leading: Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to notifications settings
          },
        ),
        ListTile(
          leading: Icon(Icons.lock_outline),
          title: const Text('Privacy'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
        ListTile(
          leading: Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to help
          },
        ),
        ListTile(
          leading: Icon(Icons.info_outline),
          title: const Text('About'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Navigate to about
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
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
            context,
            icon: Icons.list_alt,
            title: 'Create Wishlists',
            subtitle: 'Add unlimited wishlists and items',
          ),
          _buildFeatureTile(
            context,
            icon: Icons.share,
            title: 'Share with Others',
            subtitle: 'Generate shareable links instantly',
          ),
          _buildFeatureTile(
            context,
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

  Widget _buildFeatureTile(BuildContext context, {
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
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