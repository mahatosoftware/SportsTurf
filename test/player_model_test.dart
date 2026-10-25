import 'package:flutter_test/flutter_test.dart';
import 'package:sports_turf/core/models/player.dart';

void main() {
  group('Player Model', () {
    test('should create player with correct values', () {
      final player = Player(id: '1', name: 'John Doe');
      expect(player.id, '1');
      expect(player.name, 'John Doe');
    });

    test('should convert to map', () {
      final player = Player(id: '1', name: 'John Doe');
      final map = player.toMap();
      expect(map['id'], '1');
      expect(map['name'], 'John Doe');
    });

    test('should create from map', () {
      final map = {'id': '1', 'name': 'John Doe'};
      final player = Player.fromMap(map);
      expect(player.id, '1');
      expect(player.name, 'John Doe');
    });

    test('should gracefully accept numeric id in constructor and map', () {
      final playerFromInt = Player(id: 42, name: 'Jane Doe');
      expect(playerFromInt.id, '42');

      final fromMapWithInt = Player.fromMap({'id': 99, 'name': 'Alex'});
      expect(fromMapWithInt.id, '99');
    });
  });
}
