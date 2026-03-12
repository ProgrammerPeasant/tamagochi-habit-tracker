class HabitEntity {
  final String id;
  final String title;
  final String category;
  final HabitFrequency frequency;
  final int currentStreak;
  final bool completedToday;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    required this.currentStreak,
    required this.completedToday,
  });

  HabitEntity copyWith({
    String? title,
    String? category,
    HabitFrequency? frequency,
    int? currentStreak,
    bool? completedToday,
  }) {
    return HabitEntity(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      currentStreak: currentStreak ?? this.currentStreak,
      completedToday: completedToday ?? this.completedToday,
    );
  }
}

enum HabitFrequency { daily, weekly, custom }
