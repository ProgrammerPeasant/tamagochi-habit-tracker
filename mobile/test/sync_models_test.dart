import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/sync/sync_models.dart';

void main() {
  test('SyncChange toJson/fromJson preserves fields', () {
    final change = SyncChange(
      entity: 'habit',
      op: 'upsert',
      id: 'hab_1',
      updatedAt: '2026-03-14T10:00:00Z',
      payload: {'title': 'Drink water', 'completed_today': 1},
    );

    final json = change.toJson();
    final decoded = SyncChange.fromJson(json);

    expect(decoded.entity, change.entity);
    expect(decoded.op, change.op);
    expect(decoded.id, change.id);
    expect(decoded.updatedAt, change.updatedAt);
    expect(decoded.payload, change.payload);
  });

  test('SyncResponse parses changes list', () {
    final response = SyncResponse.fromJson({
      'cursor': '2026-03-14T10:00:00Z',
      'changes': [
        {
          'entity': 'habit',
          'op': 'delete',
          'id': 'hab_2',
          'updated_at': '2026-03-14T09:00:00Z',
          'payload': <String, dynamic>{},
        },
      ],
    });

    expect(response.cursor, '2026-03-14T10:00:00Z');
    expect(response.changes.length, 1);
    expect(response.changes.first.entity, 'habit');
    expect(response.changes.first.op, 'delete');
    expect(response.changes.first.id, 'hab_2');
  });
}
