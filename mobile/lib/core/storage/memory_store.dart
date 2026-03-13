import 'package:flutter/foundation.dart';

import '../../features/habits/domain/habit.dart';
import '../../features/pet/domain/pet_state.dart';
import '../../features/stats/domain/streak.dart';
import '../../features/stats/domain/user_stats.dart';
import '../sync/sync_models.dart';
import '../utils/id_generator.dart';

class MemoryStore {
  MemoryStore._();

  static final MemoryStore instance = MemoryStore._();

  final Map<String, HabitEntity> habits = {};
  final List<HabitLogEntry> habitLogs = [];
  final Map<String, Streak> streaks = {};
  UserStats? userStats;
  PetState? petState;

  final List<MemorySyncQueueItem> syncQueue = [];
  String deviceId = IdGenerator.deviceId();
  String cursor = '';
  DateTime syncUpdatedAt = DateTime.now().toUtc();

  void reset() {
    habits.clear();
    habitLogs.clear();
    streaks.clear();
    userStats = null;
    petState = null;
    syncQueue.clear();
    cursor = '';
    syncUpdatedAt = DateTime.now().toUtc();
  }
}

class HabitLogEntry {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;

  HabitLogEntry({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    required this.createdAt,
  });
}

class MemorySyncQueueItem {
  final String id;
  final SyncChange change;

  MemorySyncQueueItem({required this.id, required this.change});
}

bool isWebMemoryStoreEnabled() => kIsWeb;
