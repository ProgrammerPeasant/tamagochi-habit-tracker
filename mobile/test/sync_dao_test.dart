import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/storage/db_time.dart';
import 'package:origamit/core/storage/memory_store.dart';
import 'package:origamit/core/sync/sync_queue.dart';
import 'package:origamit/core/sync/sync_state.dart';

void main() {
  setUp(() => MemoryStore.instance.reset());

  test('SyncQueueDao enqueue/list/delete in memory store', () async {
    final queue = SyncQueueDao(forceMemoryStore: true);
    final now = DateTime.now().toUtc();

    await queue.enqueue(
      deviceId: 'dev',
      entity: 'habit',
      op: 'upsert',
      entityId: 'hab_1',
      updatedAt: now.subtract(const Duration(minutes: 1)),
      payload: {'title': 'A'},
    );
    await queue.enqueue(
      deviceId: 'dev',
      entity: 'habit',
      op: 'delete',
      entityId: 'hab_2',
      updatedAt: now,
      payload: {},
    );

    final pending = await queue.listPending();
    expect(pending.length, 2);
    expect(pending.first.change.updatedAt,
        DbTime.format(now.subtract(const Duration(minutes: 1))));

    await queue.deleteByIds([pending.first.id]);
    final remaining = await queue.listPending();
    expect(remaining.length, 1);
  });

  test('SyncStateDao getState/updateCursor in memory store', () async {
    final stateDao = SyncStateDao(forceMemoryStore: true);

    final initial = await stateDao.getState();
    expect(initial.deviceId, isNotEmpty);
    expect(initial.cursor, '');

    await stateDao.updateCursor('cursor_42');
    final updated = await stateDao.getState();
    expect(updated.cursor, 'cursor_42');
  });
}
