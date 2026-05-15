import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_controller.dart';
import 'stats_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final streaksAsync = ref.watch(streaksProvider);
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress ledger',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Synced from your studio timeline.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              statsAsync.when(
                data: (stats) {
                  if (stats == null) {
                    return _emptyCard(
                        context, 'No stats yet. Complete a habit to begin.');
                  }
                  return Row(
                    children: [
                      _statTile(
                        context,
                        label: 'Completed',
                        value: stats.totalCompleted.toString(),
                      ),
                      const SizedBox(width: 12),
                      _statTile(
                        context,
                        label: 'Active days',
                        value: stats.activeDays.toString(),
                      ),
                      const SizedBox(width: 12),
                      _statTile(
                        context,
                        label: 'Rate',
                        value: '${(stats.completionRate * 100).round()}%',
                      ),
                    ],
                  );
                },
                loading: () => _emptyCard(context, 'Loading stats...'),
                error: (_, __) => _emptyCard(context, 'Stats unavailable.'),
              ),
              const SizedBox(height: 20),
              Text(
                'Streaks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: streaksAsync.when(
                  data: (streaks) {
                    if (streaks.isEmpty) {
                      return _emptyCard(context, 'No streaks yet.');
                    }
                    return ListView.separated(
                      itemCount: streaks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final streak = streaks[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _habitLabel(habits, streak.habitId),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${streak.currentStreak} / ${streak.bestStreak}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => _emptyCard(context, 'Loading streaks...'),
                  error: (_, __) => _emptyCard(context, 'Streaks unavailable.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _habitLabel(List<HabitEntity> habits, String id) {
    for (final item in habits) {
      if (item.id == id) {
        return item.title;
      }
    }
    return 'Habit $id';
  }

  Widget _statTile(BuildContext context,
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

  Widget _emptyCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

