import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../habits/domain/habit.dart';
import '../../habits/presentation/habits_controller.dart';
import '../domain/pet_state.dart';

final petStateProvider = Provider<PetState>((ref) {
  final habits = ref.watch(habitsProvider);
  return _computePetState(habits);
});

final petDebugProvider = StateNotifierProvider<PetDebugController, PetDebugState>(
  (ref) => PetDebugController(),
);

class PetDebugState {
  final bool enabled;
  final int? structureComplexity;
  final int? damage;
  final int? energy;
  final int? mood;

  const PetDebugState({
    this.enabled = false,
    this.structureComplexity,
    this.damage,
    this.energy,
    this.mood,
  });

  PetDebugState copyWith({
    bool? enabled,
    int? structureComplexity,
    int? damage,
    int? energy,
    int? mood,
  }) {
    return PetDebugState(
      enabled: enabled ?? this.enabled,
      structureComplexity: structureComplexity ?? this.structureComplexity,
      damage: damage ?? this.damage,
      energy: energy ?? this.energy,
      mood: mood ?? this.mood,
    );
  }
}

class PetDebugController extends StateNotifier<PetDebugState> {
  PetDebugController() : super(const PetDebugState());

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  void adjustComplexity(int delta) {
    final next = _clamp((state.structureComplexity ?? 0) + delta, 0, 100);
    state = state.copyWith(structureComplexity: next, enabled: true);
  }

  void adjustDamage(int delta) {
    final next = _clamp((state.damage ?? 0) + delta, 0, 100);
    state = state.copyWith(damage: next, enabled: true);
  }

  void adjustEnergy(int delta) {
    final next = _clamp((state.energy ?? 0) + delta, 0, 100);
    state = state.copyWith(energy: next, enabled: true);
  }

  void adjustMood(int delta) {
    final next = _clamp((state.mood ?? 0) + delta, 0, 100);
    state = state.copyWith(mood: next, enabled: true);
  }

  void reset() {
    state = const PetDebugState();
  }
}

PetState applyDebugOverrides(PetState base, PetDebugState debug) {
  if (!debug.enabled) {
    return base;
  }

  final complexity = debug.structureComplexity ?? base.structureComplexity;
  final damage = debug.damage ?? base.damage;
  final energy = debug.energy ?? base.energy;
  final mood = debug.mood ?? base.mood;

  return base.copyWith(
    level: levelForComplexity(complexity),
    structureComplexity: complexity,
    damage: damage,
    energy: energy,
    mood: mood,
    stage: stageForComplexity(complexity),
  );
}

PetState _computePetState(List<HabitEntity> habits) {
  if (habits.isEmpty) {
    return const PetState(
      level: 1,
      structureComplexity: 0,
      damage: 0,
      energy: 20,
      mood: 40,
      stage: PetStage.flatSheet,
    );
  }

  final total = habits.length;
  final completed = habits.where((habit) => habit.completedToday).length;
  final streakSum = habits.fold<int>(0, (sum, habit) => sum + habit.currentStreak);
  final completionRatio = completed / max(total, 1);

  final complexity = _clamp(10 + streakSum * 3 + completed * 10, 0, 100);
  final energy = _clamp((completionRatio * 100).round() + (streakSum ~/ 2), 0, 100);
  final damage = _clamp(((1 - completionRatio) * 70).round() - (streakSum ~/ 3), 0, 100);
  final mood = _clamp(40 + (energy ~/ 2) - (damage ~/ 3), 0, 100);

  return PetState(
    level: levelForComplexity(complexity),
    structureComplexity: complexity,
    damage: damage,
    energy: energy,
    mood: mood,
    stage: stageForComplexity(complexity),
  );
}

int _clamp(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
