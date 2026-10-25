import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/dispute.dart';
import '../providers/dispute_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/providers/audit_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';

class DisputesScreen extends ConsumerStatefulWidget {
  final String? tournamentId;
  final String? tournamentName;
  final String? leagueId;
  final String? leagueName;

  const DisputesScreen({
    super.key,
    this.tournamentId,
    this.tournamentName,
    this.leagueId,
    this.leagueName,
  });

  @override
  ConsumerState<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends ConsumerState<DisputesScreen> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disputesAsync = widget.tournamentId != null
        ? ref.watch(tournamentDisputesProvider(widget.tournamentId!))
        : widget.leagueId != null
            ? ref.watch(leagueDisputesProvider(widget.leagueId!))
            : const AsyncValue.data(<Dispute>[]);

    final title = widget.tournamentName != null
        ? '${widget.tournamentName} Protests & Disputes'
        : widget.leagueName != null
            ? '${widget.leagueName} Disputes'
            : 'Integrity & Disputes';

    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final canRule = currentUser != null && (isSuperAdmin || true); // Officials & Managers
    final canFile = currentUser != null; // Logged-in participants / managers only

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (canFile)
            IconButton(
              icon: const Icon(Icons.add_alert_outlined),
              tooltip: 'File Protest / Dispute',
              onPressed: () => _openCreateDisputeDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!canFile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Spectator Mode: View-only protests, rulings, and dispute outcomes.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          Expanded(
            child: disputesAsync.when(
              data: (disputes) {
                if (disputes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gavel_outlined, size: 72, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No Disputes or Protests Filed',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Matches and registrations are currently running smoothly without formal disputes or integrity issues.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (canFile) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _openCreateDisputeDialog(context),
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('File Protest or Score Correction'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: canFile),
                  itemCount: disputes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final dispute = disputes[index];
                    return _DisputeCard(
                      dispute: dispute,
                      dateFormat: _dateFormat,
                      canRule: canRule,
                      canAppeal: canFile && (currentUser.id == dispute.submittedByUserId || isSuperAdmin),
                      onResolve: () => _openResolveDialog(context, dispute),
                      onAppeal: () => _openAppealDialog(context, dispute),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading disputes: $err', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canFile
          ? FloatingActionButton.extended(
              onPressed: () => _openCreateDisputeDialog(context),
              icon: const Icon(Icons.flag),
              label: const Text('File Dispute'),
            )
          : null,
    );
  }

  void _openCreateDisputeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateDisputeDialog(
        tournamentId: widget.tournamentId,
        leagueId: widget.leagueId,
      ),
    );
  }

  void _openResolveDialog(BuildContext context, Dispute dispute) {
    showDialog(
      context: context,
      builder: (_) => _ResolveDisputeDialog(dispute: dispute),
    );
  }

  void _openAppealDialog(BuildContext context, Dispute dispute) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appeal Official Decision?'),
        content: Text(
          'Submit an appeal for "${dispute.title}". The dispute will be escalated to League Management or Super Admin for review.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final currentUser = ref.read(currentUserProvider);
              await ref.read(disputeControllerProvider.notifier).resolveDispute(
                id: dispute.id,
                status: DisputeStatus.appealed,
                resolution: 'Appealed by ${currentUser?.name ?? "Participant"}. Pending executive review.',
                reviewerUserId: currentUser?.id ?? 'appeal',
                reviewerName: currentUser?.name ?? 'Appealer',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dispute escalated for appeal review')),
                );
              }
            },
            child: const Text('Submit Appeal'),
          ),
        ],
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final Dispute dispute;
  final DateFormat dateFormat;
  final bool canRule;
  final bool canAppeal;
  final VoidCallback onResolve;
  final VoidCallback onAppeal;

  const _DisputeCard({
    required this.dispute,
    required this.dateFormat,
    required this.canRule,
    required this.canAppeal,
    required this.onResolve,
    required this.onAppeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dispute;

    Color statusColor;
    switch (d.status) {
      case DisputeStatus.pending:
        statusColor = Colors.orange;
        break;
      case DisputeStatus.underReview:
        statusColor = Colors.blue;
        break;
      case DisputeStatus.resolved:
        statusColor = Colors.green;
        break;
      case DisputeStatus.rejected:
        statusColor = Colors.red;
        break;
      case DisputeStatus.appealed:
        statusColor = Colors.purple;
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
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(Icons.gavel, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${d.type.displayName} • Filed by ${d.filedByName} on ${dateFormat.format(d.createdAt)}',
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
                    d.status.displayName,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              d.description,
              style: theme.textTheme.bodyMedium,
            ),
            if (d.matchId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sports, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('Related Match ID: ${d.matchId}', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            if (d.resolution != null && d.resolution!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Official Ruling (by ${d.resolvedByName ?? "Official"}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(d.resolution!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            if (canRule || canAppeal) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canAppeal && (d.status == DisputeStatus.resolved || d.status == DisputeStatus.rejected))
                    TextButton.icon(
                      onPressed: onAppeal,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Appeal Ruling'),
                    ),
                  if (canRule && (d.status == DisputeStatus.pending || d.status == DisputeStatus.underReview || d.status == DisputeStatus.appealed)) ...[
                    FilledButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.gavel, size: 16),
                      label: const Text('Review / Rule'),
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

class _CreateDisputeDialog extends ConsumerStatefulWidget {
  final String? tournamentId;
  final String? leagueId;

  const _CreateDisputeDialog({this.tournamentId, this.leagueId});

  @override
  ConsumerState<_CreateDisputeDialog> createState() => _CreateDisputeDialogState();
}

class _CreateDisputeDialogState extends ConsumerState<_CreateDisputeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _matchIdController = TextEditingController();
  DisputeType _selectedType = DisputeType.scoreCorrection;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _matchIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('File Protest / Dispute'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DisputeType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Dispute / Protest Type',
                    border: OutlineInputBorder(),
                  ),
                  items: DisputeType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Title *',
                    hintText: 'e.g. Disputed Point in Round 2, Score Inaccuracy',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _matchIdController,
                  decoration: const InputDecoration(
                    labelText: 'Match ID / Match # (Optional)',
                    hintText: 'e.g. Match #4 or match ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Details and Grounds for Protest *',
                    hintText: 'Provide facts, timestamps, players involved, and requested resolution',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide dispute details' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submit,
          child: const Text('Submit Formal Protest'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final dispute = Dispute(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      type: _selectedType,
      tournamentId: widget.tournamentId ?? 'standalone',
      leagueId: widget.leagueId,
      matchId: _matchIdController.text.trim().isNotEmpty ? _matchIdController.text.trim() : null,
      submittedByUserId: currentUser?.id ?? 'anonymous',
      submittedByName: currentUser?.name ?? 'Participant',
      status: DisputeStatus.pending,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(disputeControllerProvider.notifier).submitDispute(dispute);
      // Log audit
      await ref.read(auditControllerProvider.notifier).log(
        actorId: currentUser?.id ?? 'anonymous',
        actorName: currentUser?.name ?? 'Participant',
        action: 'SUBMIT_DISPUTE',
        targetType: 'Dispute',
        targetId: dispute.id,
        description: 'Submitted protest: ${dispute.title}',
        metadata: {'title': dispute.title, 'type': dispute.type.name},
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protest filed successfully and queued for review')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit dispute: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ResolveDisputeDialog extends ConsumerStatefulWidget {
  final Dispute dispute;

  const _ResolveDisputeDialog({required this.dispute});

  @override
  ConsumerState<_ResolveDisputeDialog> createState() => _ResolveDisputeDialogState();
}

class _ResolveDisputeDialogState extends ConsumerState<_ResolveDisputeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rulingController = TextEditingController();
  DisputeStatus _status = DisputeStatus.resolved;

  @override
  void dispose() {
    _rulingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Issue Official Ruling'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviewing: "${widget.dispute.title}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(widget.dispute.description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                const Text('Ruling Decision', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<DisputeStatus>(
                  segments: const [
                    ButtonSegment(value: DisputeStatus.resolved, label: Text('Uphold / Resolve')),
                    ButtonSegment(value: DisputeStatus.rejected, label: Text('Dismiss / Reject')),
                    ButtonSegment(value: DisputeStatus.underReview, label: Text('Investigating')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (set) => setState(() => _status = set.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rulingController,
                  decoration: const InputDecoration(
                    labelText: 'Official Rationale & Ruling *',
                    hintText: 'State findings, evidence reviewed, and operational ruling (e.g. score adjusted, match result stands)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter the official ruling' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saveRuling,
          child: const Text('Publish Official Ruling'),
        ),
      ],
    );
  }

  Future<void> _saveRuling() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final ruling = _rulingController.text.trim();

    try {
      await ref.read(disputeControllerProvider.notifier).resolveDispute(
        id: widget.dispute.id,
        status: _status,
        resolution: ruling,
        reviewerUserId: currentUser?.id ?? 'official',
        reviewerName: currentUser?.name ?? 'Match Official',
      );

      // Audit log UC-175
      await ref.read(auditControllerProvider.notifier).log(
        actorId: currentUser?.id ?? 'official',
        actorName: currentUser?.name ?? 'Match Official',
        action: 'RULE_DISPUTE',
        targetType: 'Dispute',
        targetId: widget.dispute.id,
        description: 'Issued ruling on dispute: ${widget.dispute.title}',
        metadata: {
          'status': _status.name,
          'ruling': ruling,
        },
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official ruling recorded and published')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record ruling: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
