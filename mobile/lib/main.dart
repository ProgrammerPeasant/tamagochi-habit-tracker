import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/notifications/data/local_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationsService.instance.init();
  runApp(const ProviderScope(child: OrigamitApp()));
}
