import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/match_result.dart';
import '../../core/models/player.dart';

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

    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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

    await db.execute('''
CREATE TABLE players ( 
  id $idType, 
  name $textType
  )
''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      
      await db.execute('''
CREATE TABLE players ( 
  id $idType, 
  name $textType
  )
''');
    }
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

  // Player CRUD Operations
  Future<int> insertPlayer(Player player) async {
    final db = await instance.database;
    return await db.insert('players', player.toMap());
  }

  Future<List<Player>> getPlayers() async {
    final db = await instance.database;
    final orderBy = 'name ASC';
    final result = await db.query('players', orderBy: orderBy);

    return result.map((json) => Player.fromMap(json)).toList();
  }

  Future<int> updatePlayer(Player player) async {
    final db = await instance.database;
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
