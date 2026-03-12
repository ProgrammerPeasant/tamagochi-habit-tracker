import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Center(
        child: Text(
          'Statistics placeholder',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
