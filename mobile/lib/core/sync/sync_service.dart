import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../network/api_client.dart';
import '../network/api_config.dart';
import '../storage/app_database.dart';
import '../storage/db_time.dart';
import '../storage/memory_store.dart';
import '../../features/habits/domain/habit.dart';
import '../../features/pet/domain/pet_state.dart';
import '../../features/stats/domain/streak.dart';
import '../../features/stats/domain/user_stats.dart';
import 'sync_models.dart';
import 'sync_queue.dart';
import 'sync_state.dart';

class SyncService {
  SyncService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final SyncQueueDao _queueDao = SyncQueueDao();
  final SyncStateDao _stateDao = SyncStateDao();

  Future<SyncResult> syncNow({String userId = ApiConfig.defaultUserId}) async {
    final state = await _stateDao.getState();
    final pending = await _queueDao.listPending();

    final request = {
      'device_id': state.deviceId,
      'cursor': state.cursor,
      'changes': pending.map((row) => row.change.toJson()).toList(),
    };

    final responseJson =
        await _apiClient.postSync(userId: userId, body: request);
    final response = SyncResponse.fromJson(responseJson);

    if (pending.isNotEmpty) {
      await _queueDao.deleteByIds(pending.map((row) => row.id).toList());
    }

    await _applyInbound(response.changes);
    await _stateDao.updateCursor(response.cursor);

    return SyncResult(
      sent: pending.length,
      received: response.changes.length,
      cursor: response.cursor,
    );
  }

  Future<void> _applyInbound(List<SyncChange> changes) async {
    if (kIsWeb) {
      _applyInboundWeb(changes);
      return;
    }

    final db = await AppDatabase.instance.database;

    for (final change in changes) {
      switch (change.entity) {
        case 'habit':
          await _applyHabit(db, change);
          break;
        case 'habit_log':
          await _applyHabitLog(db, change);
          break;
        case 'streak':
          await _applyStreak(db, change);
          break;
        case 'pet_state':
          await _applyPetState(db, change);
          break;
        case 'user_stats':
          await _applyUserStats(db, change);
          break;
      }
    }
  }

  void _applyInboundWeb(List<SyncChange> changes) {
    final store = MemoryStore.instance;
    for (final change in changes) {
      switch (change.entity) {
        case 'habit':
          final existing = store.habits[change.id];
          if (change.op == 'delete') {
            if (existing != null) {
              store.habits[change.id] = existing.copyWith(
                deletedAt: DbTime.parse(change.updatedAt),
                updatedAt: DbTime.parse(change.updatedAt) ?? existing.updatedAt,
              );
            }
            break;
          }
          final createdAt =
              DbTime.parse(change.payload['created_at'] as String?) ??
                  existing?.createdAt ??
                  DbTime.parse(change.updatedAt) ??
                  DateTime.now().toUtc();
          final updatedAt =
              DbTime.parse(change.updatedAt) ?? DateTime.now().toUtc();
          final frequency = HabitFrequency.values.firstWhere(
            (value) => value.name == (change.payload['frequency'] ?? 'daily'),
            orElse: () => HabitFrequency.daily,
          );
          final difficulty = HabitDifficulty.values.firstWhere(
            (value) =>
                value.name ==
                ((change.payload['difficulty'] as String?)?.toLowerCase() ??
                    existing?.difficulty.name ??
                    'medium'),
            orElse: () => HabitDifficulty.medium,
          );
          store.habits[change.id] = HabitEntity(
            id: change.id,
            title: (change.payload['title'] ?? existing?.title ?? '') as String,
            category: (change.payload['category'] ?? existing?.category ?? '')
                as String,
            frequency: frequency,
            difficulty: difficulty,
            customDays: _parseCustomDays(change.payload['custom_days']) ??
                existing?.customDays,
            currentStreak: _asInt(
                change.payload['current_streak'], existing?.currentStreak ?? 0),
            completedToday: _asInt(change.payload['completed_today'],
                    existing?.completedToday == true ? 1 : 0) ==
                1,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: DbTime.parse(change.payload['deleted_at'] as String?),
            lastCompletedAt:
                DbTime.parse(change.payload['last_completed_at'] as String?),
          );
          break;
        case 'streak':
          store.streaks[change.id] = Streak(
            habitId: change.id,
            currentStreak: _asInt(change.payload['current_streak'], 0),
            bestStreak: _asInt(change.payload['best_streak'], 0),
            lastCompleted:
                DbTime.parse(change.payload['last_completed'] as String?),
            updatedAt: DbTime.parse(change.updatedAt) ?? DateTime.now().toUtc(),
          );
          break;
        case 'pet_state':
          final complexity = _asInt(change.payload['structure_complexity'], 0);
          store.petState = PetState(
            level:
                _asInt(change.payload['level'], levelForComplexity(complexity)),
            structureComplexity: complexity,
            damage: _asInt(change.payload['damage'], 0),
            energy: _asInt(change.payload['energy'], 0),
            mood: _asInt(change.payload['mood'], 0),
            stage: stageForComplexity(complexity),
          );
          break;
        case 'user_stats':
          store.userStats = UserStats(
            totalCompleted: _asInt(change.payload['total_completed'], 0),
            completionRate: _asDouble(change.payload['completion_rate'], 0.0),
            activeDays: _asInt(change.payload['active_days'], 0),
            updatedAt: DbTime.parse(change.updatedAt) ?? DateTime.now().toUtc(),
          );
          break;
      }
    }
  }

  Future<void> _applyHabit(Database db, SyncChange change) async {
    final existing = await db.query(
      'habits',
      columns: ['updated_at'],
      where: 'id = ?',
      whereArgs: [change.id],
      limit: 1,
    );

    if (!_shouldApply(existing, change.updatedAt)) {
      return;
    }

    if (change.op == 'delete') {
      await db.update(
        'habits',
        {
          'deleted_at': change.updatedAt,
          'updated_at': change.updatedAt,
        },
        where: 'id = ?',
        whereArgs: [change.id],
      );
      return;
    }

    final payload = change.payload;
    await db.insert(
      'habits',
      {
        'id': change.id,
        'title': payload['title'] ?? '',
        'category': payload['category'] ?? '',
        'frequency': payload['frequency'] ?? 'daily',
        'difficulty': _normalizeDifficulty(payload['difficulty']),
        'custom_days': _encodeCustomDaysFromPayload(payload['custom_days']),
        'current_streak': payload['current_streak'] ?? 0,
        'completed_today': payload['completed_today'] ?? 0,
        'last_completed_at': payload['last_completed_at'],
        'created_at': payload['created_at'] ?? change.updatedAt,
        'updated_at': change.updatedAt,
        'deleted_at': payload['deleted_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _normalizeDifficulty(Object? raw) {
    if (raw is String) {
      final v = raw.toLowerCase().trim();
      if (v == 'easy' || v == 'medium' || v == 'hard') return v;
    }
    return 'medium';
  }

  /// Payload may carry custom_days as `List<int>` (from local enqueue) or
  /// `List<dynamic>` of `int`/`num` (from JSON-decoded server change).
  /// SQLite column is TEXT — encode as sorted comma-separated, or NULL.
  String? _encodeCustomDaysFromPayload(Object? raw) {
    if (raw is! List) return null;
    final out = <int>{};
    for (final item in raw) {
      final n = item is int ? item : (item is num ? item.toInt() : null);
      if (n != null && n >= 1 && n <= 7) out.add(n);
    }
    if (out.isEmpty) return null;
    final sorted = out.toList()..sort();
    return sorted.join(',');
  }

  Future<void> _applyHabitLog(Database db, SyncChange change) async {
    final payload = change.payload;
    await db.insert(
      'habit_logs',
      {
        'id': change.id,
        'habit_id': payload['habit_id'],
        'date': payload['date'],
        'completed': payload['completed'] == true ? 1 : 0,
        'created_at': payload['created_at'] ?? change.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _applyStreak(Database db, SyncChange change) async {
    final payload = change.payload;
    await db.insert(
      'streaks',
      {
        'habit_id': change.id,
        'current_streak': payload['current_streak'] ?? 0,
        'best_streak': payload['best_streak'] ?? 0,
        'last_completed': payload['last_completed'],
        'updated_at': change.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _applyPetState(Database db, SyncChange change) async {
    final payload = change.payload;
    await db.insert(
      'pet_state',
      {
        'id': change.id,
        'level': payload['level'] ?? 1,
        'structure_complexity': payload['structure_complexity'] ?? 0,
        'damage': payload['damage'] ?? 0,
        'energy': payload['energy'] ?? 0,
        'mood': payload['mood'] ?? 0,
        'updated_at': change.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _applyUserStats(Database db, SyncChange change) async {
    final payload = change.payload;
    await db.insert(
      'user_stats',
      {
        'id': change.id,
        'total_completed': payload['total_completed'] ?? 0,
        'completion_rate': payload['completion_rate'] ?? 0.0,
        'active_days': payload['active_days'] ?? 0,
        'updated_at': change.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  bool _shouldApply(List<Map<String, Object?>> existing, String updatedAt) {
    if (existing.isEmpty) {
      return true;
    }
    final localUpdatedAt = existing.first['updated_at'] as String?;
    if (localUpdatedAt == null || localUpdatedAt.isEmpty) {
      return true;
    }
    final local =
        DbTime.parse(localUpdatedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final incoming = DbTime.parse(updatedAt) ?? DateTime.now().toUtc();
    return incoming.isAfter(local) || incoming.isAtSameMomentAs(local);
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Set<int>? _parseCustomDays(dynamic raw) {
    if (raw is! List) return null;
    final out = <int>{};
    for (final item in raw) {
      final n = item is int ? item : (item is num ? item.toInt() : null);
      if (n != null && n >= 1 && n <= 7) out.add(n);
    }
    return out.isEmpty ? null : out;
  }

  double _asDouble(dynamic value, double fallback) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}

class SyncResult {
  final int sent;
  final int received;
  final String cursor;

  SyncResult({
    required this.sent,
    required this.received,
    required this.cursor,
  });
}
