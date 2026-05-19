import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/features/habits/domain/habit.dart';

HabitEntity _h({
  required HabitFrequency frequency,
  required DateTime createdAt,
  Set<int>? customDays,
}) {
  return HabitEntity(
    id: 'h',
    title: 't',
    category: 'c',
    frequency: frequency,
    customDays: customDays,
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

    test('custom with empty / null customDays falls back to always due', () {
      final h = _h(frequency: HabitFrequency.custom, createdAt: tue);
      expect(h.isDueOn(tue), isTrue);
      expect(h.isDueOn(wed), isTrue);
      final h2 = _h(
          frequency: HabitFrequency.custom, createdAt: tue, customDays: {});
      expect(h2.isDueOn(tue), isTrue);
    });

    test('custom respects customDays bitmask', () {
      // 2026-05-19 is Tuesday (ISO weekday=2). 5/20 = Wed=3. 5/22 = Fri=5.
      final h = _h(
        frequency: HabitFrequency.custom,
        createdAt: tue,
        customDays: {2, 5}, // Tue + Fri
      );
      expect(h.isDueOn(tue), isTrue);
      expect(h.isDueOn(wed), isFalse);
      expect(h.isDueOn(DateTime(2026, 5, 22)), isTrue);
      expect(h.isDueOn(DateTime(2026, 5, 24)), isFalse); // Sun
    });
  });
}
