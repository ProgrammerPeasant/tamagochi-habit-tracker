import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';
import '../domain/streak.dart';

class StreaksLocalDataSource {
  Future<List<Streak>> listStreaks() async {
    if (kIsWeb) {
      final items = MemoryStore.instance.streaks.values.toList();
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query('streaks', orderBy: 'updated_at DESC');
    return rows.map(_mapRow).toList();
  }

  Future<void> upsertStreaks(List<Streak> streaks) async {
    if (kIsWeb) {
      for (final streak in streaks) {
        MemoryStore.instance.streaks[streak.habitId] = streak;
      }
      return;
    }

    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (final streak in streaks) {
      batch.insert(
        'streaks',
        {
          'habit_id': streak.habitId,
          'current_streak': streak.currentStreak,
          'best_streak': streak.bestStreak,
          'last_completed': streak.lastCompleted != null
              ? DbTime.format(streak.lastCompleted!)
              : null,
          'updated_at': DbTime.format(streak.updatedAt),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Streak _mapRow(Map<String, Object?> row) {
    return Streak(
      habitId: row['habit_id'] as String,
      currentStreak: row['current_streak'] as int? ?? 0,
      bestStreak: row['best_streak'] as int? ?? 0,
      lastCompleted: DbTime.parse(row['last_completed'] as String?),
      updatedAt:
          DbTime.parse(row['updated_at'] as String?) ?? DateTime.now().toUtc(),
    );
  }
}
