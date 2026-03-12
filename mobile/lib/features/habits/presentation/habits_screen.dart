import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'habits_controller.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_form_sheet.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habits studio',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Shape a calmer rhythm by making each fold deliberate.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _SummaryRow(habitsCount: habits.length),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return HabitCard(
                      habit: habit,
                      onToggle: () => ref.read(habitsProvider.notifier).toggleCompleted(habit.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.primaryBackground,
        label: const Text('New habit'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => HabitFormSheet(
        onSubmit: (habit) => ref.read(habitsProvider.notifier).addHabit(habit),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int habitsCount;

  const _SummaryRow({required this.habitsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SummaryPill(
            label: 'Active habits',
            value: habitsCount.toString(),
          ),
          const SizedBox(width: 12),
          _SummaryPill(
            label: 'Focus',
            value: 'Daily',
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
