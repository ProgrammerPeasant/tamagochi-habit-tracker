import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/habits/domain/habit.dart';

HabitEntity _h({
  required int streak,
  required HabitFrequency frequency,
  DateTime? lastCompletedAt,
}) {
  final now = DateTime.now().toUtc();
  return HabitEntity(
    id: 'h',
    title: 't',
    category: 'c',
    frequency: frequency,
    currentStreak: streak,
    completedToday: false,
    createdAt: now.subtract(const Duration(days: 14)),
    updatedAt: now,
    lastCompletedAt: lastCompletedAt,
  );
}

void main() {
  group('HabitCompletionRollover.withStaleStreakReset', () {
    test('no-op when streak is already zero', () {
      final h = _h(streak: 0, frequency: HabitFrequency.daily);
      expect(h.withStaleStreakReset(), same(h));
    });

    test('no-op for weekly habits', () {
      final stale =
          DateTime.now().subtract(const Duration(days: 5));
      final h = _h(
          streak: 4,
          frequency: HabitFrequency.weekly,
          lastCompletedAt: stale);
      expect(h.withStaleStreakReset().currentStreak, 4);
    });

    test('keeps streak when last completion was yesterday', () {
      final now = DateTime.now();
      final yesterdayEvening = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(hours: 4));
      final h = _h(
          streak: 5,
          frequency: HabitFrequency.daily,
          lastCompletedAt: yesterdayEvening);
      expect(h.withStaleStreakReset().currentStreak, 5);
    });

    test('zeros streak after a fully missed day', () {
      final now = DateTime.now();
      final twoDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1, hours: 12));
      final h = _h(
          streak: 5,
          frequency: HabitFrequency.daily,
          lastCompletedAt: twoDaysAgo);
      expect(h.withStaleStreakReset().currentStreak, 0);
    });

    test('zeros streak when lastCompletedAt is null', () {
      final h = _h(
          streak: 3,
          frequency: HabitFrequency.daily,
          lastCompletedAt: null);
      expect(h.withStaleStreakReset().currentStreak, 0);
    });
  });
}
