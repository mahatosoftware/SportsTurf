import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/player.dart';
import '../../core/providers/auth_providers.dart';
import 'services/player_import_export_service.dart';
import '../../core/widgets/bottom_navigation_padding.dart';
import 'providers/player_providers.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Add / Edit Player
  // ---------------------------------------------------------------------------
  Future<void> _addOrEditPlayer({Player? player}) async {
    final currentUser = ref.read(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final canManagePlayer = isSuperAdmin ||
        (currentUser != null && (player == null || player.userId == null || player.userId == currentUser.id));

    if (!canManagePlayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Spectators cannot modify other player profiles.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: player?.name ?? '');
    final contactController = TextEditingController(text: player?.contact ?? '');
    final seedController = TextEditingController(text: player?.seed?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              player == null ? Icons.person_add : Icons.edit,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(player == null ? 'Add Player' : 'Edit Player'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Player Name *',
                  hintText: 'e.g. Roger Federer',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact / Phone (Optional)',
                  hintText: 'e.g. +91 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: seedController,
                decoration: const InputDecoration(
                  labelText: 'Seed Number (Optional)',
                  hintText: 'e.g. 1 for top seed',
                  prefixIcon: Icon(Icons.military_tech_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final contact = contactController.text.trim();
                final seed = int.tryParse(seedController.text.trim());

                if (player == null) {
                  await ref.read(playerControllerProvider.notifier).addPlayer(
                        Player(
                          name: name,
                          contact: contact.isEmpty ? null : contact,
                          seed: seed,
                        ),
                      );
                } else {
                  await ref.read(playerControllerProvider.notifier).updatePlayer(
                        Player(
                          id: player.id,
                          name: name,
                          contact: contact.isEmpty ? null : contact,
                          seed: seed,
                        ),
                      );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Download CSV Template Dialog
  // ---------------------------------------------------------------------------
  Future<void> _showDownloadTemplateDialog() async {
    final templateText = PlayerImportExportService.sampleCsvTemplate;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Download Template'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use this standard CSV template to organize your players in Excel, Google Sheets, or Numbers before importing:',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    templateText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Columns: Name (required), Contact (optional), Seed (optional, 1 = top seed)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: templateText));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Template copied to clipboard.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_download, size: 16),
            label: const Text('Download / Share File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final file = await PlayerImportExportService.saveTemplateFile();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Template saved: ${file.path}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Open',
                        textColor: Colors.white,
                        onPressed: () {
                          PlayerImportExportService.shareTemplateFile();
                        },
                      ),
                    ),
                  );
                }
                await PlayerImportExportService.shareTemplateFile();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save template: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Export Players Dialog
  // ---------------------------------------------------------------------------
  Future<void> _showExportDialog(List<Player> allPlayers) async {
    if (allPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No players to export.')),
      );
      return;
    }

    String exportFormat = 'csv';
    String exportedContent = PlayerImportExportService.exportToCsv(allPlayers);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setExportState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.file_upload_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Export Players'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose format and copy or save file:',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'csv', label: Text('CSV (Excel)'), icon: Icon(Icons.table_chart)),
                        ButtonSegment(value: 'json', label: Text('JSON'), icon: Icon(Icons.code)),
                      ],
                      selected: {exportFormat},
                      onSelectionChanged: (Set<String> newSelection) {
                        setExportState(() {
                          exportFormat = newSelection.first;
                          if (exportFormat == 'csv') {
                            exportedContent = PlayerImportExportService.exportToCsv(allPlayers);
                          } else {
                            exportedContent = PlayerImportExportService.exportToJson(allPlayers);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          exportedContent,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${allPlayers.length} players ready to export (${exportedContent.length} chars)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share File'),
                onPressed: () async {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await PlayerImportExportService.sharePlayersCsvFile(allPlayers);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: exportedContent));
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied ${allPlayers.length} players to clipboard ($exportFormat).'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Import Players Dialog
  // ---------------------------------------------------------------------------
  Future<void> _showImportDialog(List<Player> allPlayers) async {
    final textController = TextEditingController();
    bool skipDuplicates = true;
    bool isImporting = false;
    PlayerImportResult parsed = PlayerImportExportService.parseImportText('');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setImportState) {
          final validCount = parsed.players.length;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Import Players'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paste CSV, line-separated names, or JSON array below:',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.paste, size: 16),
                            label: const Text('Paste'),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                textController.text = data!.text!;
                                setImportState(() {
                                  parsed = PlayerImportExportService.parseImportText(data.text!);
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.replay, size: 16),
                            label: const Text('Load Sample'),
                            onPressed: () {
                              textController.text = PlayerImportExportService.sampleCsvTemplate;
                              setImportState(() {
                                parsed = PlayerImportExportService.parseImportText(
                                  PlayerImportExportService.sampleCsvTemplate,
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Get Template'),
                            onPressed: () => _showDownloadTemplateDialog(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      maxLines: 7,
                      decoration: InputDecoration(
                        hintText: "Name, Contact, Seed\nCarlos Alcaraz, carlos@tennis.org, 1\nJannik Sinner, jannik@tennis.org, 2\n...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      onChanged: (val) {
                        setImportState(() {
                          parsed = PlayerImportExportService.parseImportText(val);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: skipDuplicates,
                          onChanged: (val) => setImportState(() => skipDuplicates = val ?? true),
                        ),
                        const Expanded(
                          child: Text(
                            'Skip duplicate names if already in database',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (validCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$validCount valid player${validCount > 1 ? 's' : ''} detected (${parsed.formatDetected})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: (validCount == 0 || isImporting)
                    ? null
                    : () async {
                        setImportState(() => isImporting = true);
                        final existingNames =
                            allPlayers.map((p) => p.name.trim().toLowerCase()).toSet();
                        final List<Player> toAdd = [];
                        int skippedCount = 0;

                        for (final player in parsed.players) {
                          final normalized = player.name.trim().toLowerCase();
                          if (skipDuplicates && existingNames.contains(normalized)) {
                            skippedCount++;
                            continue;
                          }
                          toAdd.add(player);
                          existingNames.add(normalized);
                        }

                        if (toAdd.isNotEmpty) {
                          await ref
                              .read(playerControllerProvider.notifier)
                              .bulkAddPlayers(toAdd);
                        }

                        if (dialogContext.mounted) Navigator.pop(dialogContext);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Import complete: ${toAdd.length} added${skippedCount > 0 ? ', $skippedCount duplicates skipped' : ''}.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                child: isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Import ($validCount)'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePlayer(Player player) async {
    final currentUser = ref.read(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final canManagePlayer = isSuperAdmin ||
        (currentUser != null && (player.userId == null || player.userId == currentUser.id));

    if (!canManagePlayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission Denied: Spectators cannot delete players.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Are you sure you want to delete ${player.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && player.id != null) {
      await ref.read(playerControllerProvider.notifier).deletePlayer(player.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isSpectator = currentUser == null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Player Database'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Download CSV Template',
            onPressed: _showDownloadTemplateDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export Players',
            onPressed: () {
              final players = playersAsync.value ?? [];
              _showExportDialog(players);
            },
          ),
          if (!isSpectator)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Import Players',
              onPressed: () {
                final players = playersAsync.value ?? [];
                _showImportDialog(players);
              },
            ),
        ],
      ),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading players: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(playersStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (allPlayers) {
          final filteredPlayers = _searchQuery.isEmpty
              ? allPlayers
              : allPlayers.where((p) {
                  final nameMatch = p.name.toLowerCase().contains(_searchQuery);
                  final contactMatch = p.contact?.toLowerCase().contains(_searchQuery) ?? false;
                  return nameMatch || contactMatch;
                }).toList();

          return Column(
            children: [
              if (isSpectator)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Spectator Mode: View-only player directory and player profiles.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              // Search & Quick Action Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or contact...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.swap_vert, size: 18),
                      label: const Text('Import/Export'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (bottomSheetContext) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.description_outlined, color: Colors.orange),
                                  title: const Text('Download CSV Template (Excel)'),
                                  subtitle: const Text('Download ready-to-fill spreadsheet template'),
                                  onTap: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showDownloadTemplateDialog();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.file_download_outlined, color: Colors.green),
                                  title: const Text('Import Players (CSV / JSON)'),
                                  subtitle: const Text('Paste from clipboard, spreadsheet, or sample template'),
                                  onTap: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showImportDialog(allPlayers);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.file_upload_outlined, color: Colors.blue),
                                  title: const Text('Export Players (CSV / JSON)'),
                                  subtitle: const Text('Copy to clipboard or share spreadsheet file'),
                                  onTap: () {
                                    Navigator.pop(bottomSheetContext);
                                    _showExportDialog(allPlayers);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Player List
              Expanded(
                child: filteredPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No players registered yet' : 'No matching players found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Tap "Add Player" below or "Import" to load players in bulk.'
                                  : 'Try adjusting your search query.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.description_outlined),
                                    label: const Text('Download Template'),
                                    onPressed: _showDownloadTemplateDialog,
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.file_download_outlined),
                                    label: const Text('Import Roster'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _showImportDialog(allPlayers),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: NavigationPadding.listInsets(context, horizontal: 16, top: 12, hasFab: true),
                        itemCount: filteredPlayers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          return Card(
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(30),
                                    foregroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      player.name.isNotEmpty
                                          ? player.name.trim()[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (player.seed != null)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#${player.seed}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (player.seed != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Text(
                                        'Seed #${player.seed}',
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: player.contact != null && player.contact!.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            player.contact!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              trailing: isSpectator || (!isSuperAdmin && (player.userId != null && player.userId != currentUser.id))
                                  ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          color: Colors.grey.shade700,
                                          tooltip: 'Edit Player',
                                          onPressed: () => _addOrEditPlayer(player: player),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20),
                                          color: Colors.red.shade400,
                                          tooltip: 'Delete Player',
                                          onPressed: () => _deletePlayer(player),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !isSpectator
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditPlayer(),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
            )
          : null,
    );
  }
}
