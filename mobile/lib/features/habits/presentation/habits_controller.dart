import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/habit.dart';

final habitsProvider = StateNotifierProvider<HabitsController, List<HabitEntity>>(
  (ref) => HabitsController(),
);

class HabitsController extends StateNotifier<List<HabitEntity>> {
  HabitsController() : super(_seed());

  void toggleCompleted(String id) {
    state = [
      for (final habit in state)
        if (habit.id == id)
          habit.copyWith(
            completedToday: !habit.completedToday,
            currentStreak: habit.completedToday
                ? (habit.currentStreak > 0 ? habit.currentStreak - 1 : 0)
                : habit.currentStreak + 1,
          )
        else
          habit,
    ];
  }

  void addHabit(HabitEntity habit) {
    state = [...state, habit];
  }

  static List<HabitEntity> _seed() {
    return const [
      HabitEntity(
        id: 'hab_1',
        title: 'Morning reading',
        category: 'Learning',
        frequency: HabitFrequency.daily,
        currentStreak: 6,
        completedToday: true,
      ),
      HabitEntity(
        id: 'hab_2',
        title: 'Evening walk',
        category: 'Wellness',
        frequency: HabitFrequency.daily,
        currentStreak: 3,
        completedToday: false,
      ),
      HabitEntity(
        id: 'hab_3',
        title: 'Sketch study',
        category: 'Creativity',
        frequency: HabitFrequency.weekly,
        currentStreak: 2,
        completedToday: false,
      ),
    ];
  }
}

