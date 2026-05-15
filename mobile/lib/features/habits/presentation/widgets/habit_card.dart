import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../domain/habit.dart';

class HabitCard extends StatelessWidget {
  final HabitEntity habit;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = habit.completedToday ? p.accentGold : p.surfaceSoft;

    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: p.shadowSoft,
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.7),
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
                      const SizedBox(width: 12),
                      Text(
                        _difficultyLabel(habit.difficulty),
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
                          ? p.accentGold.withOpacity(0.2)
                          : p.surfaceSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withOpacity(0.6)),
                    ),
                    child: Icon(
                      habit.completedToday
                          ? Icons.check_rounded
                          : Icons.circle_outlined,
                      color: habit.completedToday
                          ? p.accentGold
                          : p.textMuted,
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

  String _difficultyLabel(HabitDifficulty difficulty) {
    switch (difficulty) {
      case HabitDifficulty.easy:
        return 'Easy';
      case HabitDifficulty.medium:
        return 'Medium';
      case HabitDifficulty.hard:
        return 'Hard';
    }
  }
}
