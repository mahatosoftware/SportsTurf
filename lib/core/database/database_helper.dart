import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/models/match_result.dart';
import '../../core/models/player.dart';
import '../../features/tournament/models/tournament.dart';
import '../../features/tournament/models/team.dart';

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
      version: 4, 
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

    await db.execute('''
CREATE TABLE tournaments (
  id $textType PRIMARY KEY,
  name $textType,
  sport $textType,
  status $textType,
  date $textType,
  data $textType
)
''');

    await db.execute('''
CREATE TABLE teams (
  id $textType PRIMARY KEY,
  name $textType,
  player_ids $textType
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

    if (oldVersion < 3) {
      const textType = 'TEXT NOT NULL';
      await db.execute('''
CREATE TABLE tournaments (
  id $textType PRIMARY KEY,
  name $textType,
  sport $textType,
  status $textType,
  date $textType,
  data $textType
)
''');
    }

    if (oldVersion < 4) {
      const textType = 'TEXT NOT NULL';
      await db.execute('''
CREATE TABLE teams (
  id $textType PRIMARY KEY,
  name $textType,
  player_ids $textType
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

  // Tournament CRUD
  Future<int> insertTournament(Tournament tournament) async {
    final db = await instance.database;
    final data = jsonEncode(tournament.toMap());
    
    return await db.insert(
      'tournaments',
      {
        'id': tournament.id,
        'name': tournament.name,
        'sport': tournament.sportType,
        'status': tournament.status.name,
        'date': tournament.createdAt.toIso8601String(),
        'data': data,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<Tournament>> getTournaments({String? sport}) async {
    final db = await instance.database;
    final orderBy = 'date DESC';
    
    final result = sport != null
        ? await db.query('tournaments', where: 'sport = ?', whereArgs: [sport], orderBy: orderBy)
        : await db.query('tournaments', orderBy: orderBy);
        
    return result.map((row) {
      final dataStr = row['data'] as String;
      final dataMap = jsonDecode(dataStr) as Map<String, dynamic>;
      return Tournament.fromMap(dataMap);
    }).toList();
  }
  
  Future<int> updateTournament(Tournament tournament) async {
     return await insertTournament(tournament); // Replace works as update due to conflictAlgorithm
  }
  
  Future<int> deleteTournament(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tournaments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Persistent Teams CRUD
  Future<int> insertTeam(Team team) async {
    final db = await instance.database;
    return await db.insert(
      'teams',
      {
        'id': team.id,
        'name': team.name,
        'player_ids': jsonEncode(team.playerIds),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Team>> getTeams() async {
    final db = await instance.database;
    final orderBy = 'name ASC';
    
    final result = await db.query('teams', orderBy: orderBy);
        
    return result.map((row) {
      return Team(
        id: row['id'] as String,
        name: row['name'] as String,
        playerIds: (jsonDecode(row['player_ids'] as String) as List).cast<String>(),
      );
    }).toList();
  }

  Future<int> updateTeam(Team team) async {
    return await insertTeam(team);
  }

  Future<int> deleteTeam(String id) async {
    final db = await instance.database;
    return await db.delete(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
