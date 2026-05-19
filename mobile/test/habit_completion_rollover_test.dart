import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/habits/domain/habit.dart';

HabitEntity _h({
  required bool completedToday,
  DateTime? lastCompletedAt,
}) {
  final now = DateTime.now().toUtc();
  return HabitEntity(
    id: 'h',
    title: 't',
    category: 'c',
    frequency: HabitFrequency.daily,
    currentStreak: completedToday ? 3 : 0,
    completedToday: completedToday,
    createdAt: now.subtract(const Duration(days: 7)),
    updatedAt: now,
    lastCompletedAt: lastCompletedAt,
  );
}

void main() {
  group('HabitCompletionRollover.withTodayRollover', () {
    test('returns same instance when not completed', () {
      final h = _h(completedToday: false);
      expect(h.withTodayRollover(), same(h));
    });

    test('clears completedToday when lastCompletedAt is yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(hours: 4));
      final h = _h(completedToday: true, lastCompletedAt: yesterday);
      expect(h.withTodayRollover().completedToday, isFalse);
    });

    test('clears completedToday when lastCompletedAt is null', () {
      final h = _h(completedToday: true, lastCompletedAt: null);
      expect(h.withTodayRollover().completedToday, isFalse);
    });

    test('keeps completedToday when lastCompletedAt is earlier today', () {
      final now = DateTime.now();
      final earlierToday = DateTime(now.year, now.month, now.day, 6, 30);
      final h = _h(completedToday: true, lastCompletedAt: earlierToday);
      expect(h.withTodayRollover().completedToday, isTrue);
    });

    test('treats UTC lastCompletedAt as local for the comparison', () {
      // Construct a UTC timestamp that resolves to "today" in local time even
      // when local !== UTC — this protects against accidental UTC date drift
      // making a today's completion read as yesterday.
      final localNow = DateTime.now();
      final localStartOfDay =
          DateTime(localNow.year, localNow.month, localNow.day, 9, 0);
      final utc = localStartOfDay.toUtc();
      final h = _h(completedToday: true, lastCompletedAt: utc);
      expect(h.withTodayRollover().completedToday, isTrue);
    });
  });
}
