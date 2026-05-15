import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/v1';
    return 'http://localhost:8080/v1';
  }

  static const defaultUserId = 'user_local';
}
