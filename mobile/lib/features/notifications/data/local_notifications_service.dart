import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_plan.dart';

class LocalNotificationsService {
  LocalNotificationsService._();

  static final LocalNotificationsService instance =
      LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (_initialized || !isSupported) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> rescheduleAll(List<NotificationPlan> plans) async {
    if (!isSupported) return;
    await init();

    await _plugin.cancelAll();

    for (final plan in plans) {
      final scheduled = tz.TZDateTime.from(plan.scheduledAt.toLocal(), tz.local);
      if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
        continue;
      }

      final id = plan.id.hashCode & 0x7fffffff;
      try {
        await _plugin.zonedSchedule(
          id,
          _titleFor(plan.type),
          plan.message,
          scheduled,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'origamit.reminders',
              'Origamit reminders',
              channelDescription:
                  'Habit reminders, missed-habit nudges, streak praise',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Swallow scheduling errors so failures don't block the UI flow.
      }
    }
  }

  String _titleFor(NotificationType type) {
    switch (type) {
      case NotificationType.missedHabit:
        return 'Your companion misses you';
      case NotificationType.preemptiveReminder:
        return 'Time for a fold';
      case NotificationType.streakPraise:
        return 'Streak alive';
    }
  }
}
