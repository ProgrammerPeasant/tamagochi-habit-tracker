import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/theme/app_palette.dart';
import '../../habits/presentation/habits_controller.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../stats/presentation/stats_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final streaksAsync = ref.watch(streaksProvider);
    final syncState = ref.watch(syncControllerProvider);
    final habits = ref.watch(habitsProvider);
    final notifications = ref.watch(notificationsProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Studio identity',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Your quiet workspace, tuned to progress.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            _card(
              context,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: context.palette.surfaceSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_outline, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.email ?? 'Studio Owner',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authState.userId == null
                              ? 'Local-first profile'
                              : 'Signed in',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) {
                if (stats == null) {
                  return _card(
                    context,
                    child: Text(
                      'Complete a habit to unlock your studio metrics.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return Row(
                  children: [
                    _metricTile(context,
                        label: 'Completed',
                        value: stats.totalCompleted.toString()),
                    const SizedBox(width: 12),
                    _metricTile(context,
                        label: 'Active days',
                        value: stats.activeDays.toString()),
                  ],
                );
              },
              loading: () => _card(
                context,
                child: Text('Loading metrics...',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              error: (_, __) => _card(
                context,
                child: Text('Metrics unavailable.',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sync',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    syncState.isSyncing
                        ? 'Syncing...'
                        : (syncState.lastSyncedAt != null
                            ? 'Last synced ${syncState.lastSyncedAt!.toLocal()}'
                            : 'Not synced yet'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (syncState.error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      syncState.error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.palette.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (notifications.isEmpty)
                    Text('No reminders scheduled.',
                        style: Theme.of(context).textTheme.bodySmall)
                  else
                    Text(
                      '${notifications.first.message}\n${notifications.first.scheduledAt.toLocal()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Streak focus',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  streaksAsync.when(
                    data: (streaks) {
                      if (streaks.isEmpty) {
                        return Text('No streaks yet.',
                            style: Theme.of(context).textTheme.bodySmall);
                      }
                      final top = streaks.reduce((a, b) =>
                          a.currentStreak >= b.currentStreak ? a : b);
                      final habitTitle = habits.isEmpty
                          ? 'Habit'
                          : habits
                              .firstWhere(
                                (h) => h.id == top.habitId,
                                orElse: () => habits.first,
                              )
                              .title;
                      return Text(
                        '$habitTitle · ${top.currentStreak} days',
                        style: Theme.of(context).textTheme.bodyMedium,
                      );
                    },
                    loading: () => Text('Loading streaks...',
                        style: Theme.of(context).textTheme.bodySmall),
                    error: (_, __) => Text('Streaks unavailable.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferences',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _prefRow(context, 'Notifications', 'Enabled'),
                  const SizedBox(height: 8),
                  _prefRow(context, 'Local-first', 'Active'),
                  const SizedBox(height: 8),
                  _prefRow(context, 'Habits tracked', habits.length.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _metricTile(BuildContext context,
      {required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  Widget _prefRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
