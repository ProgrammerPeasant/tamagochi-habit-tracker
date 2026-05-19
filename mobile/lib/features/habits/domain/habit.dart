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

extension HabitCompletionRollover on HabitEntity {
  /// Returns the habit with `completedToday` cleared if the last completion
  /// happened before the current local calendar day. Storage keeps the flag
  /// as-is after a completion, so without this rollover yesterday's "done"
  /// would still read as completed on the next morning's first load.
  HabitEntity withTodayRollover() {
    if (!completedToday) return this;
    final last = lastCompletedAt?.toLocal();
    if (last == null) return copyWith(completedToday: false);
    final now = DateTime.now();
    final sameDay = last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    return sameDay ? this : copyWith(completedToday: false);
  }
}

extension HabitScheduling on HabitEntity {
  /// Whether the habit is scheduled for the given calendar day.
  ///
  /// - `daily`: always.
  /// - `weekly`: same weekday as the habit's creation date.
  /// - `custom`: no rule in the current schema → treated as always due.
  bool isDueOn(DateTime day) {
    switch (frequency) {
      case HabitFrequency.daily:
      case HabitFrequency.custom:
        return true;
      case HabitFrequency.weekly:
        return day.weekday == createdAt.toLocal().weekday;
    }
  }
}
