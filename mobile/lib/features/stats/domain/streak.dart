class Streak {
  final String habitId;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCompleted;
  final DateTime updatedAt;

  const Streak({
    required this.habitId,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastCompleted,
    required this.updatedAt,
  });
}
