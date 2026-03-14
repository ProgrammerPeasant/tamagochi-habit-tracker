import 'package:flutter/foundation.dart';

import '../storage/app_database.dart';
import '../storage/db_time.dart';
import '../storage/memory_store.dart';
import '../utils/id_generator.dart';

class SyncStateDao {
  SyncStateDao({bool forceMemoryStore = false})
      : _forceMemoryStore = forceMemoryStore;

  final bool _forceMemoryStore;

  static const _stateId = 'main';

  Future<SyncState> getState() async {
    if (kIsWeb || _forceMemoryStore) {
      final store = MemoryStore.instance;
      return SyncState(
        id: _stateId,
        deviceId: store.deviceId,
        cursor: store.cursor,
        updatedAt: store.syncUpdatedAt,
      );
    }

    final db = await AppDatabase.instance.database;
    final rows =
        await db.query('sync_state', where: 'id = ?', whereArgs: [_stateId]);
    if (rows.isEmpty) {
      final state = SyncState(
        id: _stateId,
        deviceId: IdGenerator.deviceId(),
        cursor: '',
        updatedAt: DateTime.now().toUtc(),
      );
      await db.insert('sync_state', state.toRow());
      return state;
    }
    return SyncState.fromRow(rows.first);
  }

  Future<void> updateCursor(String cursor) async {
    if (kIsWeb || _forceMemoryStore) {
      final store = MemoryStore.instance;
      store.cursor = cursor;
      store.syncUpdatedAt = DateTime.now().toUtc();
      return;
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toUtc();
    await db.update(
      'sync_state',
      {'cursor': cursor, 'updated_at': DbTime.format(now)},
      where: 'id = ?',
      whereArgs: [_stateId],
    );
  }
}

class SyncState {
  final String id;
  final String deviceId;
  final String cursor;
  final DateTime updatedAt;

  SyncState({
    required this.id,
    required this.deviceId,
    required this.cursor,
    required this.updatedAt,
  });

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'device_id': deviceId,
      'cursor': cursor,
      'updated_at': DbTime.format(updatedAt),
    };
  }

  factory SyncState.fromRow(Map<String, Object?> row) {
    return SyncState(
      id: row['id'] as String,
      deviceId: row['device_id'] as String,
      cursor: row['cursor'] as String,
      updatedAt:
          DbTime.parse(row['updated_at'] as String) ?? DateTime.now().toUtc(),
    );
  }
}
