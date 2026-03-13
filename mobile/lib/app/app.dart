import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'root_shell.dart';

class OrigamitApp extends StatelessWidget {
  const OrigamitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Origamit',
      theme: AppTheme.dark(),
      home: const RootShell(),
    );
  }
}
