import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_controller.dart';
import '../../pet/domain/pet_state.dart';
import '../../pet/presentation/origami_companion.dart';
import '../../pet/presentation/pet_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final pending = habits.where((habit) => !habit.completedToday).toList();
    final petState = ref.watch(petStateProvider);
    final debugState = ref.watch(petDebugProvider);
    final effectiveState = applyDebugOverrides(petState, debugState);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Origamit',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'A calm studio for deliberate folds.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surface,
                        AppColors.secondaryBackground,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 30,
                        offset: Offset(-12, 18),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onLongPress: () =>
                        _openDebugSheet(context, ref, habits, petState),
                    child: _CompanionStage(state: effectiveState),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${pending.length} pending',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    for (final habit in pending.take(2))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.accentSteel,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                habit.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              habit.category,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    if (pending.isEmpty)
                      Text(
                        'All folds are complete for today.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDebugSheet(
    BuildContext context,
    WidgetRef ref,
    List<HabitEntity> habits,
    PetState petState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final debugState = ref.watch(petDebugProvider);
          final effectiveState = applyDebugOverrides(petState, debugState);

          return _PetDebugSheet(
            habits: habits,
            petState: petState,
            effectiveState: effectiveState,
            debugState: debugState,
            onToggle: (id) =>
                ref.read(habitsProvider.notifier).toggleCompleted(id),
            onAdjust: (action) => action(ref.read(petDebugProvider.notifier)),
            onReset: () => ref.read(petDebugProvider.notifier).reset(),
            onEnable: (value) =>
                ref.read(petDebugProvider.notifier).setEnabled(value),
          );
        },
      ),
    );
  }
}

class _CompanionStage extends StatelessWidget {
  final PetState state;

  const _CompanionStage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 32,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Companion',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Stage ${state.level}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Center(
          child: OrigamiCompanion(state: state),
        ),
        Positioned(
          left: 24,
          bottom: 24,
          child: _StatPill(label: 'Energy', value: state.energy),
        ),
        Positioned(
          right: 24,
          bottom: 24,
          child: _StatPill(label: 'Mood', value: state.mood),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;

  const _StatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _PetDebugSheet extends StatelessWidget {
  final List<HabitEntity> habits;
  final PetState petState;
  final PetState effectiveState;
  final PetDebugState debugState;
  final void Function(String id) onToggle;
  final void Function(void Function(PetDebugController controller) action)
      onAdjust;
  final VoidCallback onReset;
  final void Function(bool value) onEnable;

  const _PetDebugSheet({
    required this.habits,
    required this.petState,
    required this.effectiveState,
    required this.debugState,
    required this.onToggle,
    required this.onAdjust,
    required this.onReset,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final completed = habits.where((habit) => habit.completedToday).length;
    final ratio = habits.isEmpty ? 0 : (completed / habits.length);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Origami Debug',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                TextButton(
                  onPressed: onReset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _debugRow(context, 'Stage', _stageLabel(effectiveState.stage)),
            _debugRow(context, 'Level', effectiveState.level.toString()),
            _debugRow(context, 'Complexity',
                effectiveState.structureComplexity.toString()),
            _debugRow(context, 'Energy', effectiveState.energy.toString()),
            _debugRow(context, 'Damage', effectiveState.damage.toString()),
            _debugRow(context, 'Mood', effectiveState.mood.toString()),
            _debugRow(context, 'Completion', '${(ratio * 100).round()}%'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enable overrides',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Switch(
                  value: debugState.enabled,
                  onChanged: onEnable,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: debugState.enabled ? 1 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual overrides',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _adjustRow(
                    context,
                    label: 'Complexity',
                    value: (debugState.structureComplexity ??
                            petState.structureComplexity)
                        .toString(),
                    onMinus: () => onAdjust((c) => c.adjustComplexity(-10)),
                    onPlus: () => onAdjust((c) => c.adjustComplexity(10)),
                  ),
                  _adjustRow(
                    context,
                    label: 'Energy',
                    value: (debugState.energy ?? petState.energy).toString(),
                    onMinus: () => onAdjust((c) => c.adjustEnergy(-5)),
                    onPlus: () => onAdjust((c) => c.adjustEnergy(5)),
                  ),
                  _adjustRow(
                    context,
                    label: 'Damage',
                    value: (debugState.damage ?? petState.damage).toString(),
                    onMinus: () => onAdjust((c) => c.adjustDamage(-5)),
                    onPlus: () => onAdjust((c) => c.adjustDamage(5)),
                  ),
                  _adjustRow(
                    context,
                    label: 'Mood',
                    value: (debugState.mood ?? petState.mood).toString(),
                    onMinus: () => onAdjust((c) => c.adjustMood(-5)),
                    onPlus: () => onAdjust((c) => c.adjustMood(5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap a habit to toggle completion:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final habit in habits)
                  GestureDetector(
                    onTap: () => onToggle(habit.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: habit.completedToday
                            ? AppColors.accentGold.withAlpha(51)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: habit.completedToday
                              ? AppColors.accentGold.withAlpha(153)
                              : AppColors.surfaceSoft,
                        ),
                      ),
                      child: Text(
                        habit.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: habit.completedToday
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _debugRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _adjustRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          _adjustButton(context, Icons.remove, onMinus),
          const SizedBox(width: 8),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          _adjustButton(context, Icons.add, onPlus),
        ],
      ),
    );
  }

  Widget _adjustButton(
      BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }

  String _stageLabel(PetStage stage) {
    switch (stage) {
      case PetStage.flatSheet:
        return 'Flat sheet';
      case PetStage.simpleFold:
        return 'Basic fold';
      case PetStage.geometricAnimal:
        return 'Primitive form';
      case PetStage.complexSculpture:
        return 'Advanced sculpture';
      case PetStage.architectural:
        return 'Architectural';
    }
  }
}
