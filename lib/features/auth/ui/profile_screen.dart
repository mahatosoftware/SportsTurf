import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../admin/ui/platform_admin_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out of Sports Turf?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Not Signed In',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage cloud tournaments, sync across devices, and share live matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text('SIGN IN / REGISTER'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: NavigationPadding.listInsets(context, horizontal: 20, top: 20),
              children: [
                // User Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.initials,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user.displayTitle,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.email!,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.authProvider == 'google'
                                ? Colors.red.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user.authProvider == 'google'
                                  ? Colors.red.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.authProvider == 'google'
                                    ? Icons.g_mobiledata
                                    : Icons.email_outlined,
                                size: 16,
                                color: user.authProvider == 'google'
                                    ? Colors.red
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.authProvider == 'google'
                                    ? 'Google Account'
                                    : 'Email & Password',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: user.authProvider == 'google'
                                      ? Colors.red.shade900
                                      : Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (user.isSuperAdmin) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.deepPurple.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.deepPurple.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
                      title: const Text('Platform Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Metrics, audit logs, and account moderation'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepPurple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlatformAdminScreen()),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Account Details
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('User ID'),
                        subtitle: Text(
                          user.id,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.date_range_outlined),
                        title: const Text('Member Since'),
                        subtitle: Text(DateFormat('MMMM d, yyyy').format(user.createdAt)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('SIGN OUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
    );
  }
}
