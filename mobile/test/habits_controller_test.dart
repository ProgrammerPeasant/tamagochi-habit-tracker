import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/sync/sync_controller.dart';
import 'package:origamit/features/habits/data/habits_repository.dart';
import 'package:origamit/features/habits/data/habits_repository_impl.dart';
import 'package:origamit/features/habits/domain/habit.dart';
import 'package:origamit/features/habits/presentation/habits_controller.dart';

class FakeHabitsRepository implements HabitsRepository {
  final List<HabitEntity> _items = [];

  @override
  Future<List<HabitEntity>> listHabits() async => List.of(_items);

  @override
  Future<void> upsertHabit(HabitEntity habit) async {
    final index = _items.indexWhere((item) => item.id == habit.id);
    if (index >= 0) {
      _items[index] = habit;
    } else {
      _items.add(habit);
    }
  }

  @override
  Future<void> deleteHabit(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> toggleCompleted(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = _items[index];
    final nextCompleted = !current.completedToday;
    _items[index] = current.copyWith(
      completedToday: nextCompleted,
      currentStreak: nextCompleted
          ? current.currentStreak + 1
          : (current.currentStreak > 0 ? current.currentStreak - 1 : 0),
    );
  }
}

class FakeSyncController extends SyncController {
  FakeSyncController() : super();

  int syncCalls = 0;

  @override
  Future<void> sync() async {
    syncCalls += 1;
  }
}

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
  test('seeds habits when repository is empty', () async {
    final repo = FakeHabitsRepository();
    final container = ProviderContainer(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(repo),
        syncControllerProvider.overrideWith((ref) => FakeSyncController()),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(habitsProvider.notifier);
    await _waitFor(() => repo._items.length == 3);

    expect(repo._items.length, 3);
    expect(controller.state.length, 3);
  });

  test('mutations trigger sync', () async {
    final repo = FakeHabitsRepository();
    final sync = FakeSyncController();
    final container = ProviderContainer(
      overrides: [
        habitsRepositoryProvider.overrideWithValue(repo),
        syncControllerProvider.overrideWith((ref) => sync),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(habitsProvider.notifier);
    await controller.addHabit(_habit('hab_test'));
    expect(sync.syncCalls, 1);

    await controller.toggleCompleted('hab_test');
    expect(sync.syncCalls, 2);

    await controller.deleteHabit('hab_test');
    expect(sync.syncCalls, 3);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 1));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Condition not met in time');
}
