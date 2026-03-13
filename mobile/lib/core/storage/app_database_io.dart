import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    sqfliteFfiInit();
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'origamit.db');
    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        frequency TEXT NOT NULL,
        current_streak INTEGER NOT NULL,
        completed_today INTEGER NOT NULL,
        last_completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS streaks (
        habit_id TEXT PRIMARY KEY,
        current_streak INTEGER NOT NULL,
        best_streak INTEGER NOT NULL,
        last_completed TEXT,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pet_state (
        id TEXT PRIMARY KEY,
        level INTEGER NOT NULL,
        structure_complexity INTEGER NOT NULL,
        damage INTEGER NOT NULL,
        energy INTEGER NOT NULL,
        mood INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_stats (
        id TEXT PRIMARY KEY,
        total_completed INTEGER NOT NULL,
        completion_rate REAL NOT NULL,
        active_days INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        op TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        device_id TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_state (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        cursor TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
  }
}
