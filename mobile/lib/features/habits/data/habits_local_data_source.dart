import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';
import '../../../core/utils/id_generator.dart';
import '../domain/habit.dart';

class HabitsLocalDataSource {
  HabitsLocalDataSource({bool forceMemoryStore = false})
      : _forceMemoryStore = forceMemoryStore;

  final bool _forceMemoryStore;

  Future<List<HabitEntity>> fetchHabits() async {
    if (kIsWeb || _forceMemoryStore) {
      final items = MemoryStore.instance.habits.values
          .where((habit) => habit.deletedAt == null)
          .toList();
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    }
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'habits',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at ASC',
    );
    return rows.map(_mapRow).toList();
  }

  Future<HabitEntity?> fetchHabit(String id) async {
    if (kIsWeb || _forceMemoryStore) {
      return MemoryStore.instance.habits[id];
    }
    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('habits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  Future<void> upsertHabit(HabitEntity habit) async {
    if (kIsWeb || _forceMemoryStore) {
      MemoryStore.instance.habits[habit.id] = habit;
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.insert(
      'habits',
      _mapHabit(habit),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHabit(String id, DateTime deletedAt) async {
    if (kIsWeb || _forceMemoryStore) {
      final existing = MemoryStore.instance.habits[id];
      if (existing == null) return;
      MemoryStore.instance.habits[id] = existing.copyWith(
        deletedAt: deletedAt,
        updatedAt: deletedAt,
      );
      return;
    }
    final db = await AppDatabase.instance.database;
    await db.update(
      'habits',
      {
        'deleted_at': DbTime.format(deletedAt),
        'updated_at': DbTime.format(deletedAt),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ToggleResult?> toggleCompletion(String id) async {
    if (kIsWeb || _forceMemoryStore) {
      final store = MemoryStore.instance;
      final current = store.habits[id];
      if (current == null) return null;
      final now = DateTime.now().toUtc();
      final nextCompleted = !current.completedToday;
      final next = current.copyWith(
        completedToday: nextCompleted,
        currentStreak: nextCompleted
            ? current.currentStreak + 1
            : (current.currentStreak > 0 ? current.currentStreak - 1 : 0),
        lastCompletedAt: nextCompleted ? now : null,
        updatedAt: now,
      );
      store.habits[id] = next;

      String? logId;
      if (nextCompleted) {
        logId = IdGenerator.habitLogId();
        store.habitLogs.add(
          HabitLogEntry(
            id: logId,
            habitId: id,
            date: now,
            completed: true,
            createdAt: now,
          ),
        );
      }

      return ToggleResult(updatedHabit: next, logId: logId);
    }

    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('habits', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    final current = rows.first;
    final completed = (current['completed_today'] as int?) == 1;
    final streak = current['current_streak'] as int? ?? 0;
    final now = DateTime.now().toUtc();
    final nextCompleted = !completed;

    await db.update(
      'habits',
      {
        'completed_today': nextCompleted ? 1 : 0,
        'current_streak':
            nextCompleted ? streak + 1 : (streak > 0 ? streak - 1 : 0),
        'last_completed_at': nextCompleted ? DbTime.format(now) : null,
        'updated_at': DbTime.format(now),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    String? logId;
    if (nextCompleted) {
      logId = IdGenerator.habitLogId();
      await db.insert(
        'habit_logs',
        {
          'id': logId,
          'habit_id': id,
          'date': DbTime.format(now),
          'completed': 1,
          'created_at': DbTime.format(now),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final updated = await fetchHabit(id);
    if (updated == null) return null;
    return ToggleResult(updatedHabit: updated, logId: logId);
  }

  HabitEntity _mapRow(Map<String, Object?> row) {
    return HabitEntity(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      frequency: HabitFrequency.values.firstWhere(
        (value) => value.name == row['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      currentStreak: row['current_streak'] as int? ?? 0,
      completedToday: (row['completed_today'] as int? ?? 0) == 1,
      createdAt:
          DbTime.parse(row['created_at'] as String?) ?? DateTime.now().toUtc(),
      updatedAt:
          DbTime.parse(row['updated_at'] as String?) ?? DateTime.now().toUtc(),
      deletedAt: DbTime.parse(row['deleted_at'] as String?),
      lastCompletedAt: DbTime.parse(row['last_completed_at'] as String?),
    );
  }

  Map<String, Object?> _mapHabit(HabitEntity habit) {
    return {
      'id': habit.id,
      'title': habit.title,
      'category': habit.category,
      'frequency': habit.frequency.name,
      'current_streak': habit.currentStreak,
      'completed_today': habit.completedToday ? 1 : 0,
      'last_completed_at': habit.lastCompletedAt != null
          ? DbTime.format(habit.lastCompletedAt!)
          : null,
      'created_at': DbTime.format(habit.createdAt),
      'updated_at': DbTime.format(habit.updatedAt),
      'deleted_at':
          habit.deletedAt != null ? DbTime.format(habit.deletedAt!) : null,
    };
  }
}

class ToggleResult {
  final HabitEntity updatedHabit;
  final String? logId;

  ToggleResult({required this.updatedHabit, required this.logId});
}
