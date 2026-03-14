import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_controller.dart';
import '../data/local_notifications_service.dart';
import '../data/notifications_local_data_source.dart';
import '../data/notifications_planner.dart';
import '../domain/notification_plan.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<NotificationPlan>>(
  (ref) {
    final controller = NotificationsController(ref);
    ref.listen<List<HabitEntity>>(
      habitsProvider,
      (_, __) => controller.refresh(),
    );
    return controller;
  },
);

class NotificationsController extends StateNotifier<List<NotificationPlan>> {
  NotificationsController(this._ref) : super(const []) {
    refresh();
  }

  final Ref _ref;
  final NotificationsPlanner _planner = NotificationsPlanner();
  final NotificationsLocalDataSource _local = NotificationsLocalDataSource();
  final LocalNotificationsService _localNotifications =
      LocalNotificationsService();

  Future<void> refresh() async {
    final habits = _ref.read(habitsProvider);
    final plans = await _planner.buildPlans(habits);
    await _local.replacePlans(plans);
    await _localNotifications.syncPlans(plans);
    state = plans;
  }
}
