import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/habit.dart';

class HabitFormSheet extends StatefulWidget {
  final void Function(HabitEntity habit) onSubmit;

  const HabitFormSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  HabitFrequency _frequency = HabitFrequency.daily;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'New habit',
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.primaryBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Create habit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
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
            fillColor: AppColors.surfaceSoft,
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
    return GestureDetector(
      onTap: () => setState(() => _frequency = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.accentSteel : AppColors.surfaceSoft,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    isActive ? AppColors.textPrimary : AppColors.textSecondary,
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
    final habit = HabitEntity(
      id: IdGenerator.habitId(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      frequency: _frequency,
      currentStreak: 0,
      completedToday: false,
      createdAt: now,
      updatedAt: now,
    );

    widget.onSubmit(habit);
    Navigator.of(context).pop();
  }
}
