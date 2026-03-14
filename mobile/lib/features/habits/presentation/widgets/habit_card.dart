import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/habit.dart';

class HabitCard extends StatelessWidget {
  final HabitEntity habit;
  final VoidCallback onToggle;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        habit.completedToday ? AppColors.accentGold : AppColors.surfaceSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withAlpha(102)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withAlpha(179),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      habit.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _frequencyLabel(habit.frequency),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: habit.completedToday
                        ? AppColors.accentGold.withAlpha(51)
                        : AppColors.surfaceSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withAlpha(153)),
                  ),
                  child: Icon(
                    habit.completedToday
                        ? Icons.check_rounded
                        : Icons.circle_outlined,
                    color: habit.completedToday
                        ? AppColors.accentGold
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${habit.currentStreak} day',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _frequencyLabel(HabitFrequency frequency) {
    switch (frequency) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}
