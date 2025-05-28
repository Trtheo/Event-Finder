// lib/db/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/local_event_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDB();
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'events.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        location TEXT,
        category TEXT,
        date TEXT,
        imageUrl TEXT,
        organizerName TEXT
      )
    ''');
  }

  /// Insert or update using a LocalEvent
  Future<void> insertOrUpdateEvent(LocalEvent event) async {
    final db = await database;
    await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert using Map (optional for flexibility)
  Future<void> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    await db.insert(
      'events',
      event,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all and return List<LocalEvent>
  Future<List<LocalEvent>> getEvents() async {
    final db = await database;
    final result = await db.query('events', orderBy: 'date ASC');
    return result.map((e) => LocalEvent.fromMap(e)).toList();
  }

  Future<void> deleteEvent(String id) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isEventSaved(String id) async {
    final db = await database;
    final result = await db.query('events', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }
}
