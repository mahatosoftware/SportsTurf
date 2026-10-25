import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/tournament.dart';
import '../models/tournament_registration.dart';
import '../providers/registration_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';

class RegistrationManagementScreen extends ConsumerStatefulWidget {
  final Tournament tournament;

  const RegistrationManagementScreen({
    super.key,
    required this.tournament,
  });

  @override
  ConsumerState<RegistrationManagementScreen> createState() => _RegistrationManagementScreenState();
}

class _RegistrationManagementScreenState extends ConsumerState<RegistrationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registrationsAsync = ref.watch(tournamentRegistrationsProvider(widget.tournament.id));
    final currentUser = ref.watch(currentUserProvider);
    final isOrganizer = currentUser != null &&
        (currentUser.isSuperAdmin ||
         widget.tournament.creatorId == currentUser.id ||
         widget.tournament.isManager(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrations & Waitlist'),
            Text(
              widget.tournament.name,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Waitlist'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: registrationsAsync.when(
        data: (allRegistrations) {
          final pending = allRegistrations.where((r) => r.status == RegistrationStatus.pending).toList();
          final approved = allRegistrations.where((r) => r.status == RegistrationStatus.approved).toList();
          final waitlist = allRegistrations.where((r) => r.status == RegistrationStatus.waitlisted).toList();
          final rejected = allRegistrations.where((r) => r.status == RegistrationStatus.rejected).toList();

          return Column(
            children: [
              // Mode Banner for Spectator
              if (!isOrganizer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Spectator Mode: View-only participant registrations and waitlist.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              // Capacity & Metrics Card
              _buildMetricsHeader(context, allRegistrations, approved.length),
              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRegistrationList(allRegistrations, 'No registrations found.', isOrganizer),
                    _buildRegistrationList(pending, 'No pending registrations to review.', isOrganizer),
                    _buildRegistrationList(approved, 'No approved registrations yet.', isOrganizer),
                    _buildRegistrationList(waitlist, 'Waitlist is currently empty.', isOrganizer),
                    _buildRegistrationList(rejected, 'No rejected registrations.', isOrganizer),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading registrations: $err', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsHeader(BuildContext context, List<TournamentRegistration> list, int approvedCount) {
    final theme = Theme.of(context);
    final maxPart = widget.tournament.maxParticipants;
    final capacityText = maxPart > 0 ? '$approvedCount / $maxPart' : '$approvedCount Approved';
    final isFull = maxPart > 0 && approvedCount >= maxPart;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isFull ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isFull ? Colors.orange.shade700 : Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Capacity: $capacityText',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isFull) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'FULL - Waitlist active',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ],
          ),
          if (widget.tournament.entryFee > 0)
            Text(
              'Fee: ${widget.tournament.currency} ${widget.tournament.entryFee.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrationList(List<TournamentRegistration> items, String emptyMessage, bool isOrganizer) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reg = items[index];
        return _RegistrationCard(
          registration: reg,
          dateFormat: _dateFormat,
          isOrganizer: isOrganizer,
          onApprove: () => _updateStatus(reg, RegistrationStatus.approved),
          onWaitlist: () => _updateStatus(reg, RegistrationStatus.waitlisted),
          onReject: () => _updateStatus(reg, RegistrationStatus.rejected),
        );
      },
    );
  }

  Future<void> _updateStatus(TournamentRegistration reg, RegistrationStatus targetStatus) async {
    final currentUser = ref.read(currentUserProvider);
    final isOrganizer = currentUser != null &&
        (currentUser.isSuperAdmin ||
         widget.tournament.creatorId == currentUser.id ||
         widget.tournament.isManager(currentUser.id));

    if (!isOrganizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Only tournament organizers can approve or reject registrations.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final noteController = TextEditingController();
    final actionName = targetStatus == RegistrationStatus.approved
        ? 'Approve'
        : targetStatus == RegistrationStatus.waitlisted
            ? 'Waitlist'
            : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionName "${reg.participantName}"?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set status to ${targetStatus.displayName}. Add reviewer notes if applicable:'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Reviewer Notes / Reason',
                hintText: 'e.g. Eligibility verified, Roster checked',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final currentUser = ref.read(currentUserProvider);
      final notes = noteController.text.trim();
      final controller = ref.read(registrationControllerProvider.notifier);

      try {
        if (targetStatus == RegistrationStatus.approved) {
          await controller.approveRegistration(reg.id, reviewerId: currentUser?.id, notes: notes);
        } else if (targetStatus == RegistrationStatus.waitlisted) {
          await controller.waitlistRegistration(reg.id, reviewerId: currentUser?.id, notes: notes);
        } else if (targetStatus == RegistrationStatus.rejected) {
          await controller.rejectRegistration(reg.id, reviewerId: currentUser?.id, notes: notes);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration updated to ${targetStatus.displayName}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _RegistrationCard extends StatelessWidget {
  final TournamentRegistration registration;
  final DateFormat dateFormat;
  final bool isOrganizer;
  final VoidCallback onApprove;
  final VoidCallback onWaitlist;
  final VoidCallback onReject;

  const _RegistrationCard({
    required this.registration,
    required this.dateFormat,
    required this.isOrganizer,
    required this.onApprove,
    required this.onWaitlist,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reg = registration;

    Color statusColor;
    switch (reg.status) {
      case RegistrationStatus.approved:
        statusColor = Colors.green;
        break;
      case RegistrationStatus.pending:
        statusColor = Colors.orange;
        break;
      case RegistrationStatus.waitlisted:
        statusColor = Colors.blue;
        break;
      case RegistrationStatus.rejected:
        statusColor = Colors.red;
        break;
      case RegistrationStatus.withdrawn:
        statusColor = Colors.grey;
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    reg.isTeam ? Icons.groups_outlined : Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reg.participantName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${reg.isTeam ? "Team" : "Individual"} • Submitted ${dateFormat.format(reg.submittedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    reg.status.displayName,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (reg.rosterPlayerIds.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.badge_outlined, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${reg.rosterPlayerIds.length} players listed on roster',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            if (reg.reviewNotes != null && reg.reviewNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Notes: ${reg.reviewNotes}',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (isOrganizer) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (reg.status != RegistrationStatus.rejected)
                    TextButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16, color: Colors.red),
                      label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    ),
                  if (reg.status != RegistrationStatus.waitlisted) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onWaitlist,
                      icon: const Icon(Icons.hourglass_empty, size: 16),
                      label: const Text('Waitlist'),
                    ),
                  ],
                  if (reg.status != RegistrationStatus.approved) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
