import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/sync/sync_controller.dart';
import 'package:origamit/core/sync/sync_service.dart';

class FakeSyncService extends SyncService {
  FakeSyncService({required this.result, this.shouldThrow = false});

  final SyncResult result;
  final bool shouldThrow;

  @override
  Future<SyncResult> syncNow({String userId = ''}) async {
    if (shouldThrow) {
      throw Exception('sync failed');
    }
    return result;
  }
}

void main() {
  test('sync success updates cursor and timestamps', () async {
    final service = FakeSyncService(
      result: SyncResult(sent: 1, received: 2, cursor: 'cursor_123'),
    );
    final controller = SyncController(service: service);

    await controller.sync();

    expect(controller.state.isSyncing, isFalse);
    expect(controller.state.lastCursor, 'cursor_123');
    expect(controller.state.lastSyncedAt, isNotNull);
    expect(controller.state.error, isNull);
  });

  test('sync failure stores error', () async {
    final service = FakeSyncService(
      result: SyncResult(sent: 0, received: 0, cursor: ''),
      shouldThrow: true,
    );
    final controller = SyncController(service: service);

    await controller.sync();

    expect(controller.state.isSyncing, isFalse);
    expect(controller.state.error, isNotNull);
  });
}
