enum NotificationType {
  missedHabit,
  preemptiveReminder,
  streakPraise,
}

class NotificationPlan {
  final String id;
  final String? habitId;
  final NotificationType type;
  final String message;
  final DateTime scheduledAt;
  final DateTime createdAt;

  const NotificationPlan({
    required this.id,
    required this.habitId,
    required this.type,
    required this.message,
    required this.scheduledAt,
    required this.createdAt,
  });
}
