import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/player.dart';
import 'package:sports_turf/features/players/services/player_import_export_service.dart';

void main() {
  group('Player Import & Export Service Tests', () {
    final testPlayers = [
      Player(id: 1, name: 'Carlos Alcaraz', contact: 'carlos@tennis.org', seed: 1),
      Player(id: 2, name: 'Jannik Sinner', contact: 'jannik@tennis.org', seed: 2),
      Player(id: 3, name: 'Alexander Zverev', seed: 3),
      Player(id: 4, name: 'Novak, Djokovic'), // Tests comma escaping
    ];

    test('exportToCsv produces valid CSV with escaped fields', () {
      final csv = PlayerImportExportService.exportToCsv(testPlayers);
      expect(csv.contains('Name,Contact,Seed'), isTrue);
      expect(csv.contains('Carlos Alcaraz,carlos@tennis.org,1'), isTrue);
      expect(csv.contains('Alexander Zverev,,3'), isTrue);
      expect(csv.contains('"Novak, Djokovic",,'), isTrue);
    });

    test('exportToJson produces valid JSON array', () {
      final jsonStr = PlayerImportExportService.exportToJson(testPlayers);
      expect(jsonStr.startsWith('['), isTrue);
      expect(jsonStr.contains('"name": "Carlos Alcaraz"'), isTrue);
      expect(jsonStr.contains('"seed": 1'), isTrue);
    });

    test('parseImportText parses CSV with header and seeds', () {
      const csvInput = '''
Name,Contact,Seed
Alex Morgan,alex@sport.com,1
Megan Rapinoe,megan@sport.com,2
Marta Vieira,,3
''';
      final result = PlayerImportExportService.parseImportText(csvInput);
      expect(result.players.length, 3);
      expect(result.players[0].name, 'Alex Morgan');
      expect(result.players[0].contact, 'alex@sport.com');
      expect(result.players[0].seed, 1);
      expect(result.players[2].name, 'Marta Vieira');
      expect(result.players[2].seed, 3);
    });

    test('parseImportText parses plain newline-separated names', () {
      const rawNames = '''
Roger Federer
Rafael Nadal
Novak Djokovic
''';
      final result = PlayerImportExportService.parseImportText(rawNames);
      expect(result.players.length, 3);
      expect(result.players[0].name, 'Roger Federer');
      expect(result.players[1].name, 'Rafael Nadal');
      expect(result.players[2].name, 'Novak Djokovic');
    });

    test('parseImportText parses JSON input correctly', () {
      const jsonInput = '''
[
  {"name": "Virat Kohli", "contact": "virat@cricket.in", "seed": 18},
  {"name": "Rohit Sharma", "seed": 45}
]
''';
      final result = PlayerImportExportService.parseImportText(jsonInput);
      expect(result.players.length, 2);
      expect(result.players[0].name, 'Virat Kohli');
      expect(result.players[0].seed, 18);
      expect(result.players[1].name, 'Rohit Sharma');
      expect(result.players[1].seed, 45);
    });

    test('parseImportText handles empty text safely', () {
      final result = PlayerImportExportService.parseImportText('');
      expect(result.players.isEmpty, isTrue);
      expect(result.warnings.isNotEmpty, isTrue);
    });
  });
}
