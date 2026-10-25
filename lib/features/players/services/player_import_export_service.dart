import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/player.dart';

class PlayerImportResult {
  final List<Player> players;
  final List<String> warnings;
  final String formatDetected;

  const PlayerImportResult({
    required this.players,
    this.warnings = const [],
    this.formatDetected = 'CSV',
  });
}

class PlayerImportExportService {
  /// Converts a list of players to standard CSV format.
  static String exportToCsv(List<Player> players) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Contact,Seed');
    for (final player in players) {
      final name = _escapeCsvField(player.name);
      final contact = _escapeCsvField(player.contact ?? '');
      final seed = player.seed?.toString() ?? '';
      buffer.writeln('$name,$contact,$seed');
    }
    return buffer.toString().trim();
  }

  /// Converts a list of players to pretty-printed JSON.
  static String exportToJson(List<Player> players) {
    final list = players.map((p) => {
      'name': p.name,
      if (p.contact != null && p.contact!.isNotEmpty) 'contact': p.contact,
      if (p.seed != null) 'seed': p.seed,
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// Smartly parses raw text input in CSV or JSON format.
  static PlayerImportResult parseImportText(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const PlayerImportResult(players: [], warnings: ['Input text is empty.']);
    }

    // Try parsing as JSON first
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is List) {
          final List<Player> result = [];
          for (final item in decoded) {
            if (item is Map) {
              final name = item['name']?.toString().trim();
              if (name != null && name.isNotEmpty) {
                final contact = item['contact']?.toString().trim();
                final seed = item['seed'] is int
                    ? item['seed'] as int
                    : int.tryParse(item['seed']?.toString() ?? '');
                result.add(Player(name: name, contact: contact, seed: seed));
              }
            }
          }
          return PlayerImportResult(players: result, formatDetected: 'JSON');
        }
      } catch (_) {
        // Fall back to CSV parsing below
      }
    }

    // Parse as CSV or plain newline-separated text
    final lines = const LineSplitter().convert(trimmed);
    final List<Player> result = [];
    final List<String> warnings = [];

    int startIndex = 0;
    if (lines.isNotEmpty) {
      final firstLine = lines.first.toLowerCase();
      if (firstLine.contains('name') || firstLine.startsWith('player')) {
        startIndex = 1; // Skip header
      }
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final tokens = _parseCsvLine(line);
      if (tokens.isEmpty) continue;

      final name = tokens[0].trim();
      if (name.isEmpty) {
        warnings.add('Line ${i + 1}: Skipped row with empty name.');
        continue;
      }

      String? contact;
      int? seed;

      if (tokens.length > 1 && tokens[1].trim().isNotEmpty) {
        contact = tokens[1].trim();
      }
      if (tokens.length > 2 && tokens[2].trim().isNotEmpty) {
        seed = int.tryParse(tokens[2].trim());
      }

      result.add(Player(
        name: name,
        contact: contact,
        seed: seed,
      ));
    }

    return PlayerImportResult(players: result, warnings: warnings);
  }

  /// Sample template for user guidance
  static String get sampleCsvTemplate {
    return 'Name,Contact,Seed\n'
        'Carlos Alcaraz,carlos@tennis.org,1\n'
        'Jannik Sinner,jannik@tennis.org,2\n'
        'Novak Djokovic,novak@tennis.org,3\n'
        'Alexander Zverev,,4\n'
        'Daniil Medvedev,,5';
  }

  /// Saves the sample CSV template file to the device's storage.
  /// Prefers Android /storage/emulated/0/Download when available,
  /// falling back to getDownloadsDirectory() or getApplicationDocumentsDirectory().
  static Future<File> saveTemplateFile() async {
    Directory? targetDir;
    try {
      if (Platform.isAndroid) {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        if (await publicDownloads.exists()) {
          targetDir = publicDownloads;
        }
      }
    } catch (_) {}

    try {
      targetDir ??= await getDownloadsDirectory();
    } catch (_) {}

    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/sports_turf_players_template.csv');
    await file.writeAsString(sampleCsvTemplate);
    return file;
  }

  /// Opens the system share sheet with the CSV template file.
  static Future<void> shareTemplateFile() async {
    final file = await saveTemplateFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: 'sports_turf_players_template.csv')],
      text: 'Sports Turf - Player Database CSV Template',
    );
  }

  /// Saves exported players to a CSV file.
  static Future<File> savePlayersCsvFile(List<Player> players) async {
    Directory? targetDir;
    try {
      if (Platform.isAndroid) {
        final publicDownloads = Directory('/storage/emulated/0/Download');
        if (await publicDownloads.exists()) {
          targetDir = publicDownloads;
        }
      }
    } catch (_) {}

    try {
      targetDir ??= await getDownloadsDirectory();
    } catch (_) {}

    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/sports_turf_players_export.csv');
    await file.writeAsString(exportToCsv(players));
    return file;
  }

  /// Shares exported players CSV file.
  static Future<void> sharePlayersCsvFile(List<Player> players) async {
    final file = await savePlayersCsvFile(players);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv', name: 'sports_turf_players_export.csv')],
      text: 'Sports Turf - Exported Players',
    );
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> tokens = [];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    // Detect delimiter (comma, semicolon, or tab)
    String delimiter = ',';
    if (!line.contains(',') && line.contains('\t')) {
      delimiter = '\t';
    } else if (!line.contains(',') && line.contains(';')) {
      delimiter = ';';
    }

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == delimiter && !insideQuotes) {
        tokens.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    tokens.add(buffer.toString());
    return tokens;
  }
}
