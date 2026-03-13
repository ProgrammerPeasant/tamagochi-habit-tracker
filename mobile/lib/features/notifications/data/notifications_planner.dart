import '../../habits/domain/habit.dart';
import '../domain/notification_plan.dart';
import 'habit_log_reader.dart';

class NotificationsPlanner {
  NotificationsPlanner();

  final HabitLogReader _logs = HabitLogReader();

  Future<List<NotificationPlan>> buildPlans(List<HabitEntity> habits) async {
    final now = DateTime.now();
    final plans = <NotificationPlan>[];

    for (final habit in habits) {
      final lastCompleted = habit.lastCompletedAt?.toLocal();
      final daysSince = lastCompleted == null
          ? 999
          : now.difference(lastCompleted).inDays;

      if (!habit.completedToday && daysSince >= 2) {
        final scheduled = now.add(const Duration(minutes: 2));
        plans.add(_plan(
          habitId: habit.id,
          type: NotificationType.missedHabit,
          message: 'Gentle nudge: ${habit.title} is waiting.',
          scheduledAt: scheduled,
        ));
      }

      final typicalMinutes = await _typicalMinutesForHabit(habit.id);
      if (typicalMinutes != null) {
        final planned = _nextPlannedTime(now, typicalMinutes)
            .subtract(const Duration(minutes: 20));
        if (planned.isAfter(now)) {
          plans.add(_plan(
            habitId: habit.id,
            type: NotificationType.preemptiveReminder,
            message: 'Upcoming: ${habit.title} in 20 minutes.',
            scheduledAt: planned,
          ));
        }
      }

      if (habit.currentStreak >= 7 && habit.completedToday) {
        final scheduled = now.add(const Duration(minutes: 1));
        plans.add(_plan(
          habitId: habit.id,
          type: NotificationType.streakPraise,
          message: 'Streak ${habit.currentStreak} days. Keep folding.',
          scheduledAt: scheduled,
        ));
      }
    }

    return _dedupe(plans);
  }

  Future<int?> _typicalMinutesForHabit(String habitId) async {
    final logs = await _logs.listLogs(habitId: habitId, limit: 5);
    if (logs.isEmpty) return null;
    var sum = 0;
    for (final log in logs) {
      final local = log.date.toLocal();
      sum += local.hour * 60 + local.minute;
    }
    return (sum / logs.length).round();
  }

  DateTime _nextPlannedTime(DateTime now, int minutesOfDay) {
    final hour = minutesOfDay ~/ 60;
    final minute = minutesOfDay % 60;
    var planned = DateTime(now.year, now.month, now.day, hour, minute);
    if (!planned.isAfter(now)) {
      planned = planned.add(const Duration(days: 1));
    }
    return planned;
  }

  NotificationPlan _plan({
    required String habitId,
    required NotificationType type,
    required String message,
    required DateTime scheduledAt,
  }) {
    final normalized = scheduledAt.toUtc();
    return NotificationPlan(
      id: _buildId(habitId, type, normalized),
      habitId: habitId,
      type: type,
      message: message,
      scheduledAt: normalized,
      createdAt: DateTime.now().toUtc(),
    );
  }

  String _buildId(String habitId, NotificationType type, DateTime when) {
    final stamp = when.toIso8601String().substring(0, 16);
    return 'notif_${habitId}_${type.name}_$stamp';
  }

  List<NotificationPlan> _dedupe(List<NotificationPlan> plans) {
    final seen = <String>{};
    final result = <NotificationPlan>[];
    for (final plan in plans) {
      if (seen.add(plan.id)) {
        result.add(plan);
      }
    }
    result.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return result;
  }
}

