import 'package:flutter/foundation.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';

class HabitLogRecord {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;

  HabitLogRecord({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.createdAt,
  });
}

class HabitLogReader {
  Future<List<HabitLogRecord>> listLogs({String? habitId, int limit = 50}) async {
    if (kIsWeb) {
      final logs = MemoryStore.instance.habitLogs
          .where((log) => habitId == null || log.habitId == habitId)
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs
          .take(limit)
          .map((log) => HabitLogRecord(
                id: log.id,
                habitId: log.habitId,
                date: log.date,
                completed: log.completed,
                createdAt: log.createdAt,
              ))
          .toList();
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'habit_logs',
      where: habitId != null ? 'habit_id = ?' : null,
      whereArgs: habitId != null ? [habitId] : null,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_mapRow).toList();
  }

  HabitLogRecord _mapRow(Map<String, Object?> row) {
    return HabitLogRecord(
      id: row['id'] as String,
      habitId: row['habit_id'] as String,
      date: DbTime.parse(row['date'] as String?) ?? DateTime.now().toUtc(),
      completed: (row['completed'] as int? ?? 0) == 1,
      createdAt:
          DbTime.parse(row['created_at'] as String?) ?? DateTime.now().toUtc(),
    );
  }
}

