import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/league.dart';
import '../providers/league_providers.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/widgets/bottom_navigation_padding.dart';
import '../../auth/ui/login_screen.dart';
import 'league_dashboard_screen.dart';

class LeagueSetupScreen extends ConsumerStatefulWidget {
  final League? existingLeague;

  const LeagueSetupScreen({super.key, this.existingLeague});

  @override
  ConsumerState<LeagueSetupScreen> createState() => _LeagueSetupScreenState();
}

class _LeagueSetupScreenState extends ConsumerState<LeagueSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _organizerController = TextEditingController();
  final _venueController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  bool _isPublic = true;
  LeagueStatus _status = LeagueStatus.upcoming;

  final List<String> _availableSports = [
    'All Sports',
    'Badminton',
    'Cricket',
    'Tennis',
    'Table Tennis',
    'Volleyball',
  ];
  final Set<String> _selectedSports = {'All Sports'};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLeague != null) {
      final l = widget.existingLeague!;
      _nameController.text = l.name;
      _descController.text = l.description;
      _organizerController.text = l.organizerName;
      _venueController.text = l.venue;
      _startDate = l.startDate ?? _startDate;
      _endDate = l.endDate ?? _endDate;
      _isPublic = l.isPublic;
      _status = l.status;
      _selectedSports.clear();
      _selectedSports.addAll(l.sportTypes);
    } else {
      final user = ref.read(currentUserProvider);
      if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
        _organizerController.text = user.displayName!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _organizerController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initial = isStartDate ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeague() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);

      if (widget.existingLeague != null) {
        final hasPermission = currentUser != null &&
            (currentUser.isSuperAdmin || widget.existingLeague!.isAdmin(currentUser.id));
        if (!hasPermission) {
          setState(() => _isSubmitting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission Denied: Only league owners or administrators can edit this league.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final leagueId = widget.existingLeague?.id ?? const Uuid().v4();
      final shareCode = widget.existingLeague?.shareCode ?? League.generateShareCode(leagueId);

      var creatorId = widget.existingLeague?.creatorId ?? currentUser?.id;
      if (creatorId == null || creatorId.isEmpty) {
        // Fallback to Firebase Auth user directly or authenticate anonymously
        try {
          final authRepo = ref.read(authRepositoryProvider);
          final user = authRepo.currentUser ?? await authRepo.signInAnonymously();
          creatorId = user.id;
        } catch (_) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            final shouldSignIn = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign In Required'),
                content: const Text(
                  'To create and host a league in Firebase, please sign in with your email or Google account.',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign In / Register'),
                  ),
                ],
              ),
            );
            if (shouldSignIn == true && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          }
          return;
        }
      }

      final league = League(
        id: leagueId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        organizerName: _organizerController.text.trim().isEmpty
            ? 'League Committee'
            : _organizerController.text.trim(),
        venue: _venueController.text.trim().isEmpty
            ? 'Multiple Arenas'
            : _venueController.text.trim(),
        creatorId: creatorId,
        shareCode: shareCode,
        isPublic: _isPublic,
        sportTypes: _selectedSports.isEmpty ? ['All Sports'] : _selectedSports.toList(),
        tournamentIds: widget.existingLeague?.tournamentIds ?? [],
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.existingLeague?.createdAt ?? DateTime.now(),
      );

      try {
        await ref.read(leagueControllerProvider.notifier).createLeague(league);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingLeague == null
                  ? 'League created successfully!'
                  : 'League updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LeagueDashboardScreen(league: league),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved locally, but Firebase sync failed: $e'),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 4),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LeagueDashboardScreen(league: league),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save league: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingLeague != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit League' : 'Setup New League'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: NavigationPadding.listInsets(context, horizontal: 20, top: 20),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League Banner Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Multi-Tournament League',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Host multiple tournaments (Cricket, Badminton, etc.) under one overarching championship.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'League Details',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'League Name *',
                  hintText: 'e.g. Corporate Sports Championship 2026',
                  prefixIcon: Icon(Icons.shield_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a league name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _organizerController,
                decoration: const InputDecoration(
                  labelText: 'Organizer / Federation Name',
                  hintText: 'e.g. Metro Sports Club or HR Team',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Primary Venue / Complex',
                  hintText: 'e.g. Sports Turf Hub, Bay Arena',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Sports Included in League',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSports.map((sport) {
                  final isSelected = _selectedSports.contains(sport);
                  return FilterChip(
                    label: Text(sport),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (sport == 'All Sports') {
                          if (selected) {
                            _selectedSports.clear();
                            _selectedSports.add('All Sports');
                          }
                        } else {
                          _selectedSports.remove('All Sports');
                          if (selected) {
                            _selectedSports.add(sport);
                          } else {
                            _selectedSports.remove(sport);
                            if (_selectedSports.isEmpty) {
                              _selectedSports.add('All Sports');
                            }
                          }
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              Text(
                'Duration & Schedule',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Starts: ${DateFormat('MMM d, y').format(_startDate)}'),
                      onPressed: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined),
                      label: Text('Ends: ${DateFormat('MMM d, y').format(_endDate)}'),
                      onPressed: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<LeagueStatus>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'League Status',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: LeagueStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Public League'),
                subtitle: const Text('Allow public discovery and spectators to follow this league'),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
                secondary: const Icon(Icons.public),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / League Guidelines',
                  hintText: 'Brief about the participating teams, eligibility, overall points scoring...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitLeague,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditing ? Icons.save : Icons.add_circle),
                  label: Text(
                    _isSubmitting
                        ? 'Saving League...'
                        : (isEditing ? 'Save Changes' : 'Create League & Open Hub'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const BottomNavSpacing(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
