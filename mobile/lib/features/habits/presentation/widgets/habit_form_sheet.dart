import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/habit.dart';

class HabitFormSheet extends StatefulWidget {
  final void Function(HabitEntity habit) onSubmit;
  final VoidCallback? onDelete;
  final HabitEntity? initial;

  const HabitFormSheet({
    super.key,
    required this.onSubmit,
    this.onDelete,
    this.initial,
  });

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late HabitFrequency _frequency;
  late HabitDifficulty _difficulty;
  late Set<int> _customDays;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _categoryController = TextEditingController(text: initial?.category ?? '');
    _frequency = initial?.frequency ?? HabitFrequency.daily;
    _difficulty = initial?.difficulty ?? HabitDifficulty.medium;
    _customDays = {...?initial?.customDays};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: p.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _isEditing ? 'Edit habit' : 'New habit',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildField(
            context,
            label: 'Title',
            controller: _titleController,
            hint: 'Evening walk',
          ),
          const SizedBox(height: 12),
          _buildField(
            context,
            label: 'Category',
            controller: _categoryController,
            hint: 'Wellness',
          ),
          const SizedBox(height: 16),
          Text(
            'Frequency',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _frequencyChip(context, HabitFrequency.daily, 'Daily'),
              _frequencyChip(context, HabitFrequency.weekly, 'Weekly'),
              _frequencyChip(context, HabitFrequency.custom, 'Custom'),
            ],
          ),
          if (_frequency == HabitFrequency.custom) ...[
            const SizedBox(height: 12),
            Text(
              'Days of week',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  _dayChip(context, d, _shortDayLabel(d)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Difficulty',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _difficultyChip(context, HabitDifficulty.easy, 'Easy'),
              _difficultyChip(context, HabitDifficulty.medium, 'Medium'),
              _difficultyChip(context, HabitDifficulty.hard, 'Hard'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.textPrimary,
                foregroundColor: p.primaryBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_isEditing ? 'Save changes' : 'Create habit'),
            ),
          ),
          if (_isEditing && widget.onDelete != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete habit'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.palette.secondaryBackground,
        title: const Text('Delete habit?'),
        content: Text(
          'This removes "${widget.initial?.title ?? 'this habit'}" and its progress. The action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    widget.onDelete?.call();
    Navigator.of(context).pop();
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodySmall,
            filled: true,
            fillColor: p.surfaceSoft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _frequencyChip(
      BuildContext context, HabitFrequency value, String label) {
    final isActive = _frequency == value;
    return _chip(
      context,
      isActive: isActive,
      label: label,
      onTap: () => setState(() => _frequency = value),
    );
  }

  Widget _difficultyChip(
      BuildContext context, HabitDifficulty value, String label) {
    final isActive = _difficulty == value;
    return _chip(
      context,
      isActive: isActive,
      label: label,
      onTap: () => setState(() => _difficulty = value),
    );
  }

  Widget _dayChip(BuildContext context, int weekday, String label) {
    final isActive = _customDays.contains(weekday);
    return _chip(
      context,
      isActive: isActive,
      label: label,
      onTap: () => setState(() {
        if (isActive) {
          _customDays.remove(weekday);
        } else {
          _customDays.add(weekday);
        }
      }),
    );
  }

  String _shortDayLabel(int weekday) {
    const labels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday];
  }

  Widget _chip(
    BuildContext context, {
    required bool isActive,
    required String label,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? p.surface : p.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? p.accentSteel : p.surfaceSoft,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? p.textPrimary : p.textSecondary,
              ),
        ),
      ),
    );
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final initial = widget.initial;
    final habit = HabitEntity(
      id: initial?.id ?? IdGenerator.habitId(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      frequency: _frequency,
      difficulty: _difficulty,
      customDays: _frequency == HabitFrequency.custom && _customDays.isNotEmpty
          ? {..._customDays}
          : null,
      currentStreak: initial?.currentStreak ?? 0,
      completedToday: initial?.completedToday ?? false,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
      deletedAt: initial?.deletedAt,
      lastCompletedAt: initial?.lastCompletedAt,
    );

    widget.onSubmit(habit);
    Navigator.of(context).pop();
  }
}
