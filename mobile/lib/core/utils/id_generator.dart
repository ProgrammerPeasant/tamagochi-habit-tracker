import 'dart:math';

class IdGenerator {
  static String habitId() => _id('hab');
  static String habitLogId() => _id('log');
  static String syncId() => _id('chg');
  static String deviceId() => 'dev_${_id('local')}';

  static String _id(String prefix) {
    final now = DateTime.now().toUtc();
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${prefix}_${now.millisecondsSinceEpoch}_$rand';
  }
}
