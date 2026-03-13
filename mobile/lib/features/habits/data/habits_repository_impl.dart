import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/db_time.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_state.dart';
import '../../pet/data/pet_local_data_source.dart';
import '../../stats/data/streaks_local_data_source.dart';
import '../../stats/data/user_stats_local_data_source.dart';
import '../../stats/domain/streak.dart';
import '../../stats/domain/user_stats.dart';
import '../domain/habit.dart';
import 'habits_local_data_source.dart';
import 'habits_remote_data_source.dart';
import 'habits_repository.dart';

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepositoryImpl();
});

class HabitsRepositoryImpl implements HabitsRepository {
  HabitsRepositoryImpl();

  final HabitsLocalDataSource _local = HabitsLocalDataSource();
  final HabitsRemoteDataSource _remote = HabitsRemoteDataSource();
  final SyncQueueDao _queue = SyncQueueDao();
  final SyncStateDao _syncState = SyncStateDao();
  final UserStatsLocalDataSource _statsLocal = UserStatsLocalDataSource();
  final StreaksLocalDataSource _streaksLocal = StreaksLocalDataSource();
  final PetLocalDataSource _petLocal = PetLocalDataSource();

  @override
  Future<List<HabitEntity>> listHabits() async {
    final local = await _local.fetchHabits();
    if (local.isNotEmpty) {
      return local;
    }
    try {
      final remote = await _remote.fetchHabits();
      for (final habit in remote) {
        await _local.upsertHabit(habit);
      }
      return remote;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<void> upsertHabit(HabitEntity habit) async {
    final existing = await _local.fetchHabit(habit.id);
    await _local.upsertHabit(habit);

    try {
      final updated = existing == null
          ? await _remote.createHabit(habit)
          : await _remote.updateHabit(habit);
      await _local.upsertHabit(updated);
    } catch (_) {
      await _enqueueHabit(habit, 'upsert');
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    final now = DateTime.now().toUtc();
    await _local.deleteHabit(id, now);

    try {
      await _remote.deleteHabit(id);
    } catch (_) {
      final state = await _syncState.getState();
      await _queue.enqueue(
        deviceId: state.deviceId,
        entity: 'habit',
        op: 'delete',
        entityId: id,
        updatedAt: now,
        payload: {},
      );
    }
  }

  @override
  Future<void> toggleCompleted(String id) async {
    final result = await _local.toggleCompletion(id);
    if (result == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    await _refreshLocalDerived(id, result.updatedHabit, now);

    try {
      final completion = await _remote.completeHabit(id, now);
      await _streaksLocal.upsertStreaks([completion.streak]);
      await _statsLocal.upsertStats(completion.stats);
      await _petLocal.upsertPetState(
          completion.petState, completion.stats.updatedAt);
    } catch (_) {
      if (result.logId != null) {
        final state = await _syncState.getState();
        await _queue.enqueue(
          deviceId: state.deviceId,
          entity: 'habit_log',
          op: 'upsert',
          entityId: result.logId!,
          updatedAt: now,
          payload: {
            'habit_id': id,
            'date': DbTime.format(now),
            'completed': true,
            'created_at': DbTime.format(now),
          },
        );
      }
      await _enqueueHabit(result.updatedHabit, 'upsert');
    }
  }

  Future<void> _refreshLocalDerived(
      String habitId, HabitEntity updatedHabit, DateTime now) async {
    final existingStreak = await _streaksLocal.getStreak(habitId);
    final bestStreak =
        max(existingStreak?.bestStreak ?? 0, updatedHabit.currentStreak);
    final streak = Streak(
      habitId: habitId,
      currentStreak: updatedHabit.currentStreak,
      bestStreak: bestStreak,
      lastCompleted: updatedHabit.lastCompletedAt,
      updatedAt: now,
    );
    await _streaksLocal.upsertStreaks([streak]);

    final habits = await _local.fetchHabits();
    final totalCompleted = await _statsLocal.countTotalCompleted();
    final activeDays = await _statsLocal.countActiveDays();
    final completionRate = habits.isEmpty
        ? 0.0
        : habits.where((habit) => habit.completedToday).length / habits.length;
    final stats = UserStats(
      totalCompleted: totalCompleted,
      completionRate: completionRate,
      activeDays: activeDays,
      updatedAt: now,
    );
    await _statsLocal.upsertStats(stats);
  }

  Future<void> _enqueueHabit(HabitEntity habit, String op) async {
    final state = await _syncState.getState();
    await _queue.enqueue(
      deviceId: state.deviceId,
      entity: 'habit',
      op: op,
      entityId: habit.id,
      updatedAt: habit.updatedAt,
      payload: {
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
      },
    );
  }
}

