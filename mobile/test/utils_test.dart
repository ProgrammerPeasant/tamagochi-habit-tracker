import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/storage/db_time.dart';
import 'package:origamit/core/utils/id_generator.dart';

void main() {
  test('DbTime format + parse roundtrip to UTC', () {
    final local = DateTime(2026, 3, 14, 12, 30, 45);
    final encoded = DbTime.format(local);
    final parsed = DbTime.parse(encoded);

    expect(parsed, isNotNull);
    expect(parsed!.isUtc, isTrue);
    expect(parsed.toIso8601String(), local.toUtc().toIso8601String());
  });

  test('DbTime parse returns null for empty input', () {
    expect(DbTime.parse(null), isNull);
    expect(DbTime.parse(''), isNull);
  });

  test('IdGenerator prefixes are correct', () {
    expect(IdGenerator.habitId().startsWith('hab_'), isTrue);
    expect(IdGenerator.habitLogId().startsWith('log_'), isTrue);
    expect(IdGenerator.syncId().startsWith('chg_'), isTrue);
    expect(IdGenerator.deviceId().startsWith('dev_local_'), isTrue);
  });
}
