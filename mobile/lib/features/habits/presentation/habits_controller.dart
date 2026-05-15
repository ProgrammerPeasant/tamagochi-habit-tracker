import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_controller.dart';
import '../data/habits_repository.dart';
import '../data/habits_repository_impl.dart';
import '../domain/habit.dart';

final habitsProvider =
    StateNotifierProvider<HabitsController, List<HabitEntity>>(
  (ref) => HabitsController(ref),
);

class HabitsController extends StateNotifier<List<HabitEntity>> {
  HabitsController(this._ref) : super(const []) {
    _load();
  }

  final Ref _ref;

  HabitsRepository get _repo => _ref.read(habitsRepositoryProvider);

  Future<void> _load() async {
    final items = await _repo.listHabits();
    if (items.isEmpty) {
      await _seed();
      state = await _repo.listHabits();
      return;
    }
    state = items;
  }

  Future<void> toggleCompleted(String id, {String? notes}) async {
    await _repo.toggleCompleted(id, notes: notes);
    state = await _repo.listHabits();
    unawaited(_ref.read(syncControllerProvider.notifier).sync());
  }

  Future<void> addHabit(HabitEntity habit) async {
    await _repo.upsertHabit(habit);
    state = await _repo.listHabits();
    unawaited(_ref.read(syncControllerProvider.notifier).sync());
  }

  Future<void> updateHabit(HabitEntity habit) async {
    await _repo.upsertHabit(habit);
    state = await _repo.listHabits();
    unawaited(_ref.read(syncControllerProvider.notifier).sync());
  }

  Future<void> deleteHabit(String id) async {
    await _repo.deleteHabit(id);
    state = await _repo.listHabits();
    unawaited(_ref.read(syncControllerProvider.notifier).sync());
  }

  Future<void> _seed() async {
    final now = DateTime.now().toUtc();
    final seed = [
      HabitEntity(
        id: 'hab_1',
        title: 'Morning reading',
        category: 'Learning',
        frequency: HabitFrequency.daily,
        currentStreak: 6,
        completedToday: true,
        createdAt: now,
        updatedAt: now,
      ),
      HabitEntity(
        id: 'hab_2',
        title: 'Evening walk',
        category: 'Wellness',
        frequency: HabitFrequency.daily,
        currentStreak: 3,
        completedToday: false,
        createdAt: now,
        updatedAt: now,
      ),
      HabitEntity(
        id: 'hab_3',
        title: 'Sketch study',
        category: 'Creativity',
        frequency: HabitFrequency.weekly,
        currentStreak: 2,
        completedToday: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final habit in seed) {
      await _repo.upsertHabit(habit);
    }
  }
}
