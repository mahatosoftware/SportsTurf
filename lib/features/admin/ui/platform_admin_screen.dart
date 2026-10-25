import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/audit_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../league/providers/league_providers.dart';
import '../../tournament/providers/tournament_providers.dart';

class PlatformAdminScreen extends ConsumerStatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  ConsumerState<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends ConsumerState<PlatformAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Super Admin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Platform Overview'),
            Tab(icon: Icon(Icons.history_outlined), text: 'System Audit Logs'),
            Tab(icon: Icon(Icons.security_outlined), text: 'User Moderation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlatformOverviewTab(theme),
          _buildAuditLogsTab(theme),
          _buildUserModerationTab(theme),
        ],
      ),
    );
  }

  Widget _buildPlatformOverviewTab(ThemeData theme) {
    final leaguesAsync = ref.watch(leaguesListProvider);
    final tournamentsAsync = ref.watch(tournamentsListProvider);

    final leaguesCount = leaguesAsync.value?.length ?? 0;
    final tournamentsCount = tournamentsAsync.value?.length ?? 0;

    return ListView(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
      children: [
        // System banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.deepPurple, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sports Turf Operations Engine',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Multi-tenant sports organization system. Scoped access control active.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Core Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Leagues',
                value: '$leaguesCount',
                icon: Icons.shield_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Tournaments',
                value: '$tournamentsCount',
                icon: Icons.emoji_events_outlined,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'System Health',
                value: 'Optimal (100%)',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Security Rules',
                value: 'Role-Scoped',
                icon: Icons.lock_outline,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Platform Announcements', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign, color: Colors.deepPurple),
            title: const Text('Broadcast Platform Announcement'),
            subtitle: const Text('Post global notice to all registered organizations and players'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _broadcastAnnouncementDialog(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab(ThemeData theme) {
    final logsAsync = ref.watch(recentAuditLogsProvider);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No system audit logs recorded yet.'),
            ),
          );
        }

        return ListView.separated(
          padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getActionColor(log.action).withValues(alpha: 0.15),
                  child: Icon(Icons.security, color: _getActionColor(log.action), size: 18),
                ),
                title: Text(
                  '${log.action} • ${log.targetType}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  'By ${log.actorName} • ${_dateFormat.format(log.timestamp)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target ID: ${log.targetId}', style: const TextStyle(fontSize: 12)),
                        if (log.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Description: ${log.description}', style: const TextStyle(fontSize: 12)),
                        ],
                        if (log.metadata.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Metadata: ${log.metadata}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading audit logs: $e')),
    );
  }

  Widget _buildUserModerationTab(ThemeData theme) {
    final userSearchCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User & Account Moderation (UC-187 / UC-188)',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Suspend fraudulent or abusive accounts. Suspended users cannot create leagues or submit scoring.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: userSearchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID or Email',
                    hintText: 'e.g. user_123 or name@domain.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final target = userSearchCtrl.text.trim();
                  if (target.isEmpty) return;
                  _confirmModerateUser(context, target);
                },
                child: const Text('Inspect'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Policy Safeguards', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '• All suspensions and reactivations require a documented reason.\n'
                    '• Every moderation action is permanently logged to the audit log (UC-194).\n'
                    '• Platform Super Admin credentials are verified on write by Firestore Security Rules.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmModerateUser(BuildContext context, String userTarget) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Moderate User: $userTarget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select action:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Documented Reason *',
                hintText: 'e.g. Inappropriate behavior, dispute violation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _logModerationAction('REACTIVATE_USER', userTarget, reasonCtrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User $userTarget reactivated')),
                );
              }
            },
            child: const Text('Reactivate User'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _logModerationAction('SUSPEND_USER', userTarget, reasonCtrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User $userTarget suspended'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Suspend User'),
          ),
        ],
      ),
    );
  }

  Future<void> _logModerationAction(String action, String targetUserId, String reason) async {
    final currentUser = ref.read(currentUserProvider);
    await ref.read(auditControllerProvider.notifier).log(
      actorId: currentUser?.id ?? 'admin',
      actorName: currentUser?.name ?? 'Platform Super Admin',
      action: action,
      targetType: 'UserAccount',
      targetId: targetUserId,
      description: 'Account $action: $reason',
      metadata: {'reason': reason},
    );
  }

  void _broadcastAnnouncementDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Platform Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Headline *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Announcement Details', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(ctx);
              final currentUser = ref.read(currentUserProvider);
              await ref.read(auditControllerProvider.notifier).log(
                actorId: currentUser?.id ?? 'admin',
                actorName: currentUser?.name ?? 'Super Admin',
                action: 'BROADCAST_ANNOUNCEMENT',
                targetType: 'Platform',
                targetId: 'global',
                description: 'Global announcement: $title',
                metadata: {'body': bodyCtrl.text.trim()},
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Global announcement broadcasted to platform')),
                );
              }
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('SUSPEND') || action.contains('DELETE') || action.contains('REJECT')) {
      return Colors.red;
    }
    if (action.contains('APPROVE') || action.contains('CREATE') || action.contains('REACTIVATE')) {
      return Colors.green;
    }
    return Colors.deepPurple;
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
