import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sync/sync_controller.dart';
import '../features/habits/presentation/habits_controller.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/pet/presentation/pet_controller.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/stats/presentation/stats_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell>
    with WidgetsBindingObserver {
  int _index = 0;
  DateTime? _pausedAt;

  final List<Widget> _screens = const [
    HomeScreen(),
    HabitsScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider.notifier).sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausedAt = DateTime.now().toUtc();
        break;
      case AppLifecycleState.resumed:
        _onResume();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onResume() {
    final pausedAt = _pausedAt;
    _pausedAt = null;

    ref.invalidate(habitsProvider);
    ref.invalidate(petStateProvider);
    ref.read(syncControllerProvider.notifier).sync();

    if (pausedAt != null) {
      final awayDuration = DateTime.now().toUtc().difference(pausedAt);
      if (awayDuration.inMinutes >= 1 && mounted) {
        final hours = awayDuration.inHours;
        final minutes = awayDuration.inMinutes % 60;
        final label = hours > 0
            ? '${hours}h ${minutes}m'
            : '${awayDuration.inMinutes}m';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back. Recalculated companion after $label.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline), label: 'Habits'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
