import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/habits/domain/habit.dart';
import 'package:origamit/features/notifications/data/habit_log_reader.dart';
import 'package:origamit/features/notifications/data/notifications_planner.dart';
import 'package:origamit/features/notifications/domain/notification_plan.dart';

class FakeHabitLogReader extends HabitLogReader {
  FakeHabitLogReader(this._logs);

  final List<HabitLogRecord> _logs;

  @override
  Future<List<HabitLogRecord>> listLogs({String? habitId, int limit = 50}) async {
    final filtered = _logs
        .where((log) => habitId == null || log.habitId == habitId)
        .toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.take(limit).toList();
  }
}

HabitEntity _habit({
  required String id,
  required bool completedToday,
  required int currentStreak,
  DateTime? lastCompletedAt,
}) {
  final now = DateTime.now();
  return HabitEntity(
    id: id,
    title: 'Habit $id',
    category: 'Wellness',
    frequency: HabitFrequency.daily,
    currentStreak: currentStreak,
    completedToday: completedToday,
    createdAt: now.subtract(const Duration(days: 7)),
    updatedAt: now,
    lastCompletedAt: lastCompletedAt,
  );
}

void main() {
  test('plans missed habit notification when overdue', () async {
    final now = DateTime.now();
    final habit = _habit(
      id: 'h1',
      completedToday: false,
      currentStreak: 1,
      lastCompletedAt: now.subtract(const Duration(days: 2, minutes: 5)),
    );

    final planner = NotificationsPlanner(logs: FakeHabitLogReader(const []));
    final plans = await planner.buildPlans([habit]);

    expect(plans.length, 1);
    expect(plans.first.type, NotificationType.missedHabit);
    expect(plans.first.habitId, habit.id);

    final scheduled = plans.first.scheduledAt.toUtc();
    final diff = scheduled.difference(now.toUtc()).inMinutes;
    expect(diff >= 1 && diff <= 3, isTrue);
  });

  test('plans preemptive reminder based on typical completion time', () async {
    final now = DateTime.now();
    final habit = _habit(
      id: 'h2',
      completedToday: true,
      currentStreak: 3,
      lastCompletedAt: now,
    );

    final base = now.add(const Duration(hours: 2));
    final logs = List.generate(
      5,
      (index) => HabitLogRecord(
        id: 'log_$index',
        habitId: habit.id,
        date: base.subtract(Duration(days: index)),
        completed: true,
        createdAt: base.subtract(Duration(days: index)),
      ),
    );

    final planner = NotificationsPlanner(logs: FakeHabitLogReader(logs));
    final plans = await planner.buildPlans([habit]);

    expect(plans.length, 1);
    expect(plans.first.type, NotificationType.preemptiveReminder);
    expect(plans.first.scheduledAt.isAfter(now.toUtc()), isTrue);
  });

  test('plans streak praise for 7+ day streaks completed today', () async {
    final now = DateTime.now();
    final habit = _habit(
      id: 'h3',
      completedToday: true,
      currentStreak: 7,
      lastCompletedAt: now,
    );

    final planner = NotificationsPlanner(logs: FakeHabitLogReader(const []));
    final plans = await planner.buildPlans([habit]);

    expect(plans.length, 1);
    expect(plans.first.type, NotificationType.streakPraise);
  });

  test('plans are sorted by scheduled time', () async {
    final now = DateTime.now();
    final missed = _habit(
      id: 'h4',
      completedToday: false,
      currentStreak: 1,
      lastCompletedAt: now.subtract(const Duration(days: 3)),
    );
    final praise = _habit(
      id: 'h5',
      completedToday: true,
      currentStreak: 7,
      lastCompletedAt: now,
    );

    final planner = NotificationsPlanner(logs: FakeHabitLogReader(const []));
    final plans = await planner.buildPlans([missed, praise]);

    expect(plans.length, 2);
    expect(
      plans.first.scheduledAt.isBefore(plans.last.scheduledAt) ||
          plans.first.scheduledAt.isAtSameMomentAs(plans.last.scheduledAt),
      isTrue,
    );
  });
}
