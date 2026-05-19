import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/habits/domain/habit.dart';

HabitEntity _h({
  required HabitFrequency frequency,
  required DateTime createdAt,
}) {
  return HabitEntity(
    id: 'h',
    title: 't',
    category: 'c',
    frequency: frequency,
    currentStreak: 0,
    completedToday: false,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  // 2026-05-19 is a Tuesday.
  final tue = DateTime(2026, 5, 19);
  final wed = DateTime(2026, 5, 20);

  group('HabitScheduling.isDueOn', () {
    test('daily is always due', () {
      final h = _h(frequency: HabitFrequency.daily, createdAt: tue);
      expect(h.isDueOn(tue), isTrue);
      expect(h.isDueOn(wed), isTrue);
    });

    test('weekly is due on the same weekday it was created', () {
      final h = _h(frequency: HabitFrequency.weekly, createdAt: tue);
      expect(h.isDueOn(tue), isTrue);
      expect(h.isDueOn(wed), isFalse);
    });

    test('weekly is due on the matching weekday a week later', () {
      final h = _h(frequency: HabitFrequency.weekly, createdAt: tue);
      expect(h.isDueOn(tue.add(const Duration(days: 7))), isTrue);
    });

    test('custom currently has no rule and is always due', () {
      final h = _h(frequency: HabitFrequency.custom, createdAt: tue);
      expect(h.isDueOn(tue), isTrue);
      expect(h.isDueOn(wed), isTrue);
    });
  });
}
