import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_plan.dart';

class LocalNotificationsService {
  LocalNotificationsService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> syncPlans(List<NotificationPlan> plans) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    final nowUtc = DateTime.now().toUtc();
    final upcoming = plans.where((plan) => plan.scheduledAt.isAfter(nowUtc));
    final desiredIds = <int>{};
    for (final plan in upcoming) {
      desiredIds.add(_hashId(plan.id));
    }

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (!desiredIds.contains(request.id)) {
        await _plugin.cancel(request.id);
      }
    }

    for (final plan in upcoming) {
      await _schedule(plan);
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const macos = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      macOS: macos,
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    await macos?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _schedule(NotificationPlan plan) async {
    final id = _hashId(plan.id);
    final scheduled = tz.TZDateTime.from(plan.scheduledAt, tz.UTC);

    await _plugin.zonedSchedule(
      id,
      'Origamit',
      plan.message,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'origamit_reminders',
          'Reminders',
          channelDescription: 'Habit reminders and streak praise',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _hashId(String id) {
    var hash = 0;
    for (final unit in id.codeUnits) {
      hash = 31 * hash + unit;
    }
    return hash & 0x7fffffff;
  }
}
