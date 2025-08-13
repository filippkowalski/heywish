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
                'Guest User',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up to save your wishlists',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: () {
                        context.push('/auth/signup');
                      },
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        context.push('/auth/login');
                      },
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ),
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
}