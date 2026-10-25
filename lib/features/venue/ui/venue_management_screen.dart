import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/venue.dart';
import '../providers/venue_providers.dart';
import '../../league/providers/league_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';

class VenueManagementScreen extends ConsumerStatefulWidget {
  final String? leagueId;
  final String? leagueName;

  const VenueManagementScreen({
    super.key,
    this.leagueId,
    this.leagueName,
  });

  @override
  ConsumerState<VenueManagementScreen> createState() => _VenueManagementScreenState();
}

class _VenueManagementScreenState extends ConsumerState<VenueManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final venuesAsync = widget.leagueId != null
        ? ref.watch(leagueVenuesProvider(widget.leagueId!))
        : ref.watch(venuesStreamProvider);
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isLeagueAdmin = widget.leagueId != null
        ? (currentUser != null && (ref.watch(singleLeagueProvider(widget.leagueId!)).value?.isAdmin(currentUser.id) ?? false))
        : false;
    final canManageVenues = currentUser != null && (isSuperAdmin || (widget.leagueId != null ? isLeagueAdmin : true));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName != null ? '${widget.leagueName} Venues' : 'Venue Management'),
        actions: [
          if (canManageVenues)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Venue',
              onPressed: () => _openVenueDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!canManageVenues)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Spectator Mode: View-only venues, grounds, and courts.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                  ),
                ],
              ),
            ),
          Expanded(
            child: venuesAsync.when(
              data: (venues) {
                if (venues.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stadium_outlined, size: 72, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'No Venues Added Yet',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add venues, grounds, courts, or tables to manage tournament fixtures and prevent scheduling overlaps.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (canManageVenues) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => _openVenueDialog(context),
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Add First Venue'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: NavigationPadding.listInsets(context, horizontal: 16, top: 16, hasFab: canManageVenues),
                  itemCount: venues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    final canManageVenue = canManageVenues || (currentUser != null && venue.managerUserIds.contains(currentUser.id));
                    return _VenueCard(
                      venue: venue,
                      canManage: canManageVenue,
                      onEdit: () => _openVenueDialog(context, existingVenue: venue),
                      onDelete: () => _confirmDelete(context, venue),
                      onManageAreas: () => _openPlayingAreasSheet(context, venue, canManage: canManageVenue),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading venues: $err', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canManageVenues
          ? FloatingActionButton.extended(
              onPressed: () => _openVenueDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Venue'),
            )
          : null,
    );
  }

  void _openVenueDialog(BuildContext context, {Venue? existingVenue}) {
    showDialog(
      context: context,
      builder: (_) => _VenueFormDialog(
        existingVenue: existingVenue,
        leagueId: widget.leagueId,
      ),
    );
  }

  void _openPlayingAreasSheet(BuildContext context, Venue venue, {required bool canManage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlayingAreasBottomSheet(venue: venue, canManage: canManage),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Venue venue) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Venue?'),
        content: Text('Are you sure you want to delete "${venue.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(venueControllerProvider.notifier).deleteVenue(venue.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Venue "${venue.name}" deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageAreas;

  const _VenueCard({
    required this.venue,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAreas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableAreas = venue.playingAreas.where((a) => a.isAvailable).length;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.stadium, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (venue.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                venue.address,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'areas') onManageAreas();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'areas',
                      child: Text(canManage ? 'Manage Courts/Pitches' : 'View Courts/Pitches'),
                    ),
                    if (canManage) ...[
                      const PopupMenuItem(value: 'edit', child: Text('Edit Venue Details')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Venue', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Facilities / Sports Chips
            if (venue.facilities.isNotEmpty || venue.supportedSports.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...venue.supportedSports.map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  ...venue.facilities.map(
                    (f) => Chip(
                      avatar: const Icon(Icons.check, size: 12),
                      label: Text(f, style: const TextStyle(fontSize: 11)),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            const Divider(),
            // Playing Areas summary & action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.grid_view, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${venue.playingAreas.length} Playing Areas ($availableAreas Available)',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onManageAreas,
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: Text(canManage ? 'Courts & Availability' : 'View Courts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueFormDialog extends ConsumerStatefulWidget {
  final Venue? existingVenue;
  final String? leagueId;

  const _VenueFormDialog({this.existingVenue, this.leagueId});

  @override
  ConsumerState<_VenueFormDialog> createState() => _VenueFormDialogState();
}

class _VenueFormDialogState extends ConsumerState<_VenueFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _facilityController;
  late List<String> _facilities;
  late List<String> _supportedSports;

  static const List<String> _allSports = [
    'All Sports',
    'Badminton',
    'Tennis',
    'Cricket',
    'Football',
    'Volleyball',
    'Basketball',
    'Table Tennis',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingVenue?.name ?? '');
    _addressController = TextEditingController(text: widget.existingVenue?.address ?? '');
    _facilityController = TextEditingController();
    _facilities = List.from(widget.existingVenue?.facilities ?? ['Floodlights', 'Parking']);
    _supportedSports = List.from(widget.existingVenue?.supportedSports ?? ['All Sports']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingVenue != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Venue' : 'Create New Venue'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Venue / Turf Name *',
                    hintText: 'e.g. Smash Arena, Central Sports Complex',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter venue name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address / Location',
                    hintText: 'e.g. 104 Ring Road, Sector 5',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Supported Sports', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allSports.map((sport) {
                    final isSelected = _supportedSports.contains(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _supportedSports.add(sport);
                          } else {
                            _supportedSports.remove(sport);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Facilities', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _facilityController,
                        decoration: const InputDecoration(
                          hintText: 'Add facility (e.g. Changing Room)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: _addFacility,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addFacility(_facilityController.text),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _facilities.map((f) {
                    return Chip(
                      label: Text(f),
                      onDeleted: () => setState(() => _facilities.remove(f)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saveVenue,
          child: Text(isEdit ? 'Save Changes' : 'Create Venue'),
        ),
      ],
    );
  }

  void _addFacility(String val) {
    final trimmed = val.trim();
    if (trimmed.isNotEmpty && !_facilities.contains(trimmed)) {
      setState(() {
        _facilities.add(trimmed);
        _facilityController.clear();
      });
    }
  }

  Future<void> _saveVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final isEdit = widget.existingVenue != null;

    final venue = Venue(
      id: widget.existingVenue?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      leagueId: widget.leagueId ?? widget.existingVenue?.leagueId,
      facilities: _facilities,
      supportedSports: _supportedSports.isEmpty ? ['All Sports'] : _supportedSports,
      playingAreas: widget.existingVenue?.playingAreas ?? [
        const PlayingArea(id: 'area-1', name: 'Court 1'),
        const PlayingArea(id: 'area-2', name: 'Court 2'),
      ],
      managerUserIds: widget.existingVenue?.managerUserIds ?? (currentUser != null ? [currentUser.id] : []),
      createdAt: widget.existingVenue?.createdAt ?? DateTime.now(),
    );

    try {
      if (isEdit) {
        await ref.read(venueControllerProvider.notifier).updateVenue(venue);
      } else {
        await ref.read(venueControllerProvider.notifier).createVenue(venue);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venue "${venue.name}" saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save venue: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _PlayingAreasBottomSheet extends ConsumerStatefulWidget {
  final Venue venue;
  final bool canManage;

  const _PlayingAreasBottomSheet({required this.venue, this.canManage = true});

  @override
  ConsumerState<_PlayingAreasBottomSheet> createState() => _PlayingAreasBottomSheetState();
}

class _PlayingAreasBottomSheetState extends ConsumerState<_PlayingAreasBottomSheet> {
  late List<PlayingArea> _areas;
  final _areaNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _areas = List.from(widget.venue.playingAreas);
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Playing Areas & Courts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(widget.venue.name, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              if (widget.canManage) ...[
                const SizedBox(height: 16),
                // Add Area row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _areaNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Court 3, Pitch B, Table 1',
                          labelText: 'Add Playing Area',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addArea(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _addArea,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text('Courts & Availability', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_areas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No playing areas configured yet.')),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _areas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final area = _areas[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: area.isAvailable
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.errorContainer,
                          child: Icon(
                            area.isAvailable ? Icons.check_circle_outline : Icons.block,
                            color: area.isAvailable ? theme.colorScheme.primary : theme.colorScheme.error,
                            size: 20,
                          ),
                        ),
                        title: Text(area.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          area.isAvailable ? 'Available for booking & fixtures' : 'Under maintenance / Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: area.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                        trailing: widget.canManage
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: area.isAvailable,
                                    onChanged: (val) {
                                      setState(() {
                                        _areas[index] = PlayingArea(
                                          id: area.id,
                                          name: area.name,
                                          sportType: area.sportType,
                                          isAvailable: val,
                                        );
                                      });
                                      _persistAreas();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() => _areas.removeAt(index));
                                      _persistAreas();
                                    },
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: area.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: area.isAvailable ? Colors.green.shade300 : Colors.red.shade300,
                                  ),
                                ),
                                child: Text(
                                  area.isAvailable ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: area.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addArea() {
    final text = _areaNameController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _areas.add(PlayingArea(
        id: const Uuid().v4(),
        name: text,
      ));
      _areaNameController.clear();
    });
    _persistAreas();
  }

  Future<void> _persistAreas() async {
    final updatedVenue = widget.venue.copyWith(playingAreas: _areas);
    try {
      await ref.read(venueControllerProvider.notifier).updateVenue(updatedVenue);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update area: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
