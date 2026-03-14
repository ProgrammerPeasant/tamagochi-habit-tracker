import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/storage/memory_store.dart';
import 'package:origamit/features/habits/data/habits_local_data_source.dart';
import 'package:origamit/features/habits/domain/habit.dart';

HabitEntity _habit(String id) {
  final now = DateTime.now().toUtc();
  return HabitEntity(
    id: id,
    title: 'Habit $id',
    category: 'Test',
    frequency: HabitFrequency.daily,
    currentStreak: 0,
    completedToday: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUp(() => MemoryStore.instance.reset());

  test('upsert + fetch + delete uses memory store', () async {
    final dataSource = HabitsLocalDataSource(forceMemoryStore: true);
    final habit = _habit('hab_1');

    await dataSource.upsertHabit(habit);
    final fetched = await dataSource.fetchHabit('hab_1');

    expect(fetched, isNotNull);
    expect(fetched!.title, habit.title);

    await dataSource.deleteHabit('hab_1', DateTime.now().toUtc());
    final all = await dataSource.fetchHabits();
    expect(all, isEmpty);
  });

  test('toggleCompletion updates streak and logs', () async {
    final dataSource = HabitsLocalDataSource(forceMemoryStore: true);
    final habit = _habit('hab_2');

    await dataSource.upsertHabit(habit);

    final firstToggle = await dataSource.toggleCompletion('hab_2');
    expect(firstToggle, isNotNull);
    expect(firstToggle!.updatedHabit.completedToday, isTrue);
    expect(firstToggle.updatedHabit.currentStreak, 1);
    expect(firstToggle.logId, isNotNull);
    expect(MemoryStore.instance.habitLogs.length, 1);

    final secondToggle = await dataSource.toggleCompletion('hab_2');
    expect(secondToggle, isNotNull);
    expect(secondToggle!.updatedHabit.completedToday, isFalse);
    expect(secondToggle.updatedHabit.currentStreak, 0);
    expect(MemoryStore.instance.habitLogs.length, 1);
  });
}
