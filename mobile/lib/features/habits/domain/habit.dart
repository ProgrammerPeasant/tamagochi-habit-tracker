class HabitEntity {
  final String id;
  final String title;
  final String category;
  final HabitFrequency frequency;
  final HabitDifficulty difficulty;
  /// Selected ISO weekdays (1=Mon … 7=Sun) for `HabitFrequency.custom`.
  /// Null/empty for daily and weekly habits.
  final Set<int>? customDays;
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
    this.customDays,
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
    Set<int>? customDays,
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
      customDays: customDays ?? this.customDays,
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

  /// Returns the habit with `currentStreak` zeroed if a full local day has
  /// passed since `lastCompletedAt` (i.e. at least one day was skipped).
  /// Only applies to daily habits; weekly/custom have no per-day rule yet.
  HabitEntity withStaleStreakReset() {
    if (currentStreak == 0) return this;
    if (frequency != HabitFrequency.daily) return this;
    final last = lastCompletedAt?.toLocal();
    if (last == null) return copyWith(currentStreak: 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final gapDays = today.difference(lastDay).inDays;
    if (gapDays >= 2) return copyWith(currentStreak: 0);
    return this;
  }
}

extension HabitScheduling on HabitEntity {
  /// Whether the habit is scheduled for the given calendar day.
  ///
  /// - `daily`: always.
  /// - `weekly`: same weekday as the habit's creation date.
  /// - `custom`: any weekday selected in `customDays` (ISO: 1=Mon … 7=Sun).
  ///   An empty/null `customDays` falls back to "always due" so habits that
  ///   predate the schema migration keep working.
  bool isDueOn(DateTime day) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekly:
        return day.weekday == createdAt.toLocal().weekday;
      case HabitFrequency.custom:
        final days = customDays;
        if (days == null || days.isEmpty) return true;
        return days.contains(day.weekday);
    }
  }
}
