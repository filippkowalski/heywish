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

}