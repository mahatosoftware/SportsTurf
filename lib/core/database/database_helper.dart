import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/match_result.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sports_turf.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE match_history ( 
  id $idType, 
  sport $textType,
  date $textType,
  teamA $textType,
  teamB $textType,
  scoreA $intType,
  scoreB $intType,
  winner $textType,
  details $textType
  )
''');
  }

  Future<int> insertMatch(MatchResult match) async {
    final db = await instance.database;
    return await db.insert('match_history', match.toMap());
  }

  Future<List<MatchResult>> getMatches({String? sport}) async {
    final db = await instance.database;
    
    final orderBy = 'date DESC';
    final result = sport != null 
        ? await db.query('match_history', where: 'sport = ?', whereArgs: [sport], orderBy: orderBy)
        : await db.query('match_history', orderBy: orderBy);

    return result.map((json) => MatchResult.fromMap(json)).toList();
  }

  Future<int> deleteMatch(int id) async {
    final db = await instance.database;
    return await db.delete(
      'match_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllMatches() async {
    final db = await instance.database;
    return await db.delete('match_history');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
