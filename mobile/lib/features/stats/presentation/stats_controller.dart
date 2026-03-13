import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/streaks_local_data_source.dart';
import '../data/user_stats_local_data_source.dart';
import '../domain/streak.dart';
import '../domain/user_stats.dart';

final userStatsProvider = FutureProvider<UserStats?>((ref) async {
  final local = UserStatsLocalDataSource();
  return local.getStats();
});

final streaksProvider = FutureProvider<List<Streak>>((ref) async {
  final local = StreaksLocalDataSource();
  return local.listStreaks();
});
