import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:origamit/core/storage/app_database.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this._path);

  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppDatabase creates expected tables', () async {
    final tempDir = await Directory.systemTemp.createTemp('origamit_db_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);

    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
    final names = rows.map((row) => row['name'] as String).toSet();

    expect(names.contains('habits'), isTrue);
    expect(names.contains('habit_logs'), isTrue);
    expect(names.contains('streaks'), isTrue);
    expect(names.contains('pet_state'), isTrue);
    expect(names.contains('user_stats'), isTrue);
    expect(names.contains('sync_queue'), isTrue);
    expect(names.contains('sync_state'), isTrue);
    expect(names.contains('notifications'), isTrue);
  });
}
