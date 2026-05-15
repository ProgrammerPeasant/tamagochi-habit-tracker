class HabitEntity {
  final String id;
  final String title;
  final String category;
  final HabitFrequency frequency;
  final HabitDifficulty difficulty;
  final int currentStreak;
  final bool completedToday;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? lastCompletedAt;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    this.difficulty = HabitDifficulty.medium,
    required this.currentStreak,
    required this.completedToday,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastCompletedAt,
  });

  HabitEntity copyWith({
    String? title,
    String? category,
    HabitFrequency? frequency,
    HabitDifficulty? difficulty,
    int? currentStreak,
    bool? completedToday,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? lastCompletedAt,
  }) {
    return HabitEntity(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      currentStreak: currentStreak ?? this.currentStreak,
      completedToday: completedToday ?? this.completedToday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}

enum HabitFrequency { daily, weekly, custom }

enum HabitDifficulty { easy, medium, hard }
