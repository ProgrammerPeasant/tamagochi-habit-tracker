class UserStats {
  final int totalCompleted;
  final double completionRate;
  final int activeDays;
  final DateTime updatedAt;

  const UserStats({
    required this.totalCompleted,
    required this.completionRate,
    required this.activeDays,
    required this.updatedAt,
  });
}
