import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/match_result.dart';
import 'dart:convert';

void main() {
  test('MatchResult serialization', () {
    final date = DateTime(2023, 10, 26, 12, 0, 0);
    final match = MatchResult(
      sport: 'TestSport',
      date: date,
      teamA: 'A',
      teamB: 'B',
      scoreA: 2,
      scoreB: 1,
      winner: 'A',
      details: jsonEncode({'setScores': [21, 19]}),
    );

    final map = match.toMap();
    expect(map['sport'], 'TestSport');
    expect(map['date'], date.toIso8601String());
    
    final fromMap = MatchResult.fromMap(map);
    expect(fromMap.sport, 'TestSport');
    expect(fromMap.date, date);
    expect(fromMap.teamA, 'A');
    expect(fromMap.details, contains('21'));
  });
}
