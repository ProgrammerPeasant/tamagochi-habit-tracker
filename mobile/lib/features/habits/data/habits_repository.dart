import '../domain/habit.dart';

abstract class HabitsRepository {
  Future<List<HabitEntity>> listHabits();
  Future<void> upsertHabit(HabitEntity habit);
  Future<void> deleteHabit(String id);
  Future<void> toggleCompleted(String id);
}
