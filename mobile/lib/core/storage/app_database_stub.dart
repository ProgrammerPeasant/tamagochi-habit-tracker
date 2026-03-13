import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<Database> get database async {
    throw UnsupportedError('SQLite is disabled on web. Using in-memory store.');
  }
}
