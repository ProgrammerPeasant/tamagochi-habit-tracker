import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';
import '../domain/user_stats.dart';

class UserStatsLocalDataSource {
  static const _id = 'main';

  Future<UserStats?> getStats() async {
    if (kIsWeb) {
      return MemoryStore.instance.userStats;
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query('user_stats',
        where: 'id = ?', whereArgs: [_id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserStats(
      totalCompleted: row['total_completed'] as int? ?? 0,
      completionRate: (row['completion_rate'] as num?)?.toDouble() ?? 0.0,
      activeDays: row['active_days'] as int? ?? 0,
      updatedAt:
          DbTime.parse(row['updated_at'] as String?) ?? DateTime.now().toUtc(),
    );
  }

  Future<void> upsertStats(UserStats stats) async {
    if (kIsWeb) {
      MemoryStore.instance.userStats = stats;
      return;
    }

    final db = await AppDatabase.instance.database;
    await db.insert(
      'user_stats',
      {
        'id': _id,
        'total_completed': stats.totalCompleted,
        'completion_rate': stats.completionRate,
        'active_days': stats.activeDays,
        'updated_at': DbTime.format(stats.updatedAt),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
