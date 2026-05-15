import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:origamit/app/app.dart';

void main() {
  testWidgets('App boots without exceptions', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrigamitApp()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
