import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../storage/app_database.dart';
import '../storage/db_time.dart';
import '../storage/memory_store.dart';
import '../utils/id_generator.dart';
import 'sync_models.dart';

class SyncQueueDao {
  Future<void> enqueue({
    required String deviceId,
    required String entity,
    required String op,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
  }) async {
    final now = updatedAt ?? DateTime.now().toUtc();

    if (kIsWeb) {
      MemoryStore.instance.syncQueue.add(
        MemorySyncQueueItem(
          id: IdGenerator.syncId(),
          change: SyncChange(
            entity: entity,
            op: op,
            id: entityId,
            updatedAt: DbTime.format(now),
            payload: payload,
          ),
        ),
      );
      return;
    }

    final db = await AppDatabase.instance.database;
    await db.insert(
      'sync_queue',
      {
        'id': IdGenerator.syncId(),
        'entity': entity,
        'op': op,
        'entity_id': entityId,
        'payload': jsonEncode(payload),
        'updated_at': DbTime.format(now),
        'device_id': deviceId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> listPending({int limit = 50}) async {
    if (kIsWeb) {
      final items = MemoryStore.instance.syncQueue.toList();
      items.sort((a, b) => a.change.updatedAt.compareTo(b.change.updatedAt));
      return items
          .take(limit)
          .map((item) => SyncQueueItem(id: item.id, change: item.change))
          .toList();
    }

    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'sync_queue',
      orderBy: 'updated_at ASC',
      limit: limit,
    );
    return rows.map(SyncQueueItem.fromRow).toList();
  }

  Future<void> deleteByIds(List<String> ids) async {
    if (ids.isEmpty) return;

    if (kIsWeb) {
      MemoryStore.instance.syncQueue
          .removeWhere((item) => ids.contains(item.id));
      return;
    }

    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete('sync_queue',
        where: 'id IN ($placeholders)', whereArgs: ids);
  }
}

class SyncQueueItem {
  final String id;
  final SyncChange change;

  SyncQueueItem({required this.id, required this.change});

  factory SyncQueueItem.fromRow(Map<String, Object?> row) {
    return SyncQueueItem(
      id: row['id'] as String,
      change: SyncChange(
        entity: row['entity'] as String,
        op: row['op'] as String,
        id: row['entity_id'] as String,
        updatedAt: row['updated_at'] as String,
        payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      ),
    );
  }
}
