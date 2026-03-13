import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/db_time.dart';
import '../../../core/storage/memory_store.dart';
import '../domain/notification_plan.dart';

class NotificationsLocalDataSource {
  Future<List<NotificationPlan>> listPlans() async {
    if (kIsWeb) {
      return List<NotificationPlan>.from(MemoryStore.instance.notifications);
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query('notifications', orderBy: 'scheduled_at ASC');
    return rows.map(_mapRow).toList();
  }

  Future<void> replacePlans(List<NotificationPlan> plans) async {
    if (kIsWeb) {
      MemoryStore.instance.notifications
        ..clear()
        ..addAll(plans);
      return;
    }

    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    batch.delete('notifications');
    for (final plan in plans) {
      batch.insert(
        'notifications',
        {
          'id': plan.id,
          'habit_id': plan.habitId,
          'type': plan.type.name,
          'message': plan.message,
          'scheduled_at': DbTime.format(plan.scheduledAt),
          'created_at': DbTime.format(plan.createdAt),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  NotificationPlan _mapRow(Map<String, Object?> row) {
    return NotificationPlan(
      id: row['id'] as String,
      habitId: row['habit_id'] as String?,
      type: NotificationType.values.firstWhere(
        (value) => value.name == row['type'],
        orElse: () => NotificationType.preemptiveReminder,
      ),
      message: row['message'] as String? ?? '',
      scheduledAt:
          DbTime.parse(row['scheduled_at'] as String?) ?? DateTime.now().toUtc(),
      createdAt:
          DbTime.parse(row['created_at'] as String?) ?? DateTime.now().toUtc(),
    );
  }
}
