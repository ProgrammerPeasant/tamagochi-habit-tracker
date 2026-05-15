import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../domain/habit.dart';
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
        backgroundColor: context.palette.primaryBackground,
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
                      onToggle: () => _onToggle(context, ref, habit),
                      onEdit: () => _openForm(context, ref, initial: habit),
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
        backgroundColor: context.palette.textPrimary,
        foregroundColor: context.palette.primaryBackground,
        label: const Text('New habit'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    HabitEntity habit,
  ) async {
    if (habit.completedToday) {
      await ref.read(habitsProvider.notifier).toggleCompleted(habit.id);
      return;
    }
    final notes = await _askForNotes(context);
    if (!context.mounted) return;
    await ref
        .read(habitsProvider.notifier)
        .toggleCompleted(habit.id, notes: notes);
  }

  Future<String?> _askForNotes(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogContext.palette.secondaryBackground,
          title: const Text('Add a note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'How did it go? (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop(controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _openForm(
    BuildContext context,
    WidgetRef ref, {
    HabitEntity? initial,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => HabitFormSheet(
        initial: initial,
        onSubmit: (habit) {
          final notifier = ref.read(habitsProvider.notifier);
          if (initial == null) {
            notifier.addHabit(habit);
          } else {
            notifier.updateHabit(habit);
          }
        },
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
        color: context.palette.surfaceSoft,
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
          color: context.palette.surface,
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
