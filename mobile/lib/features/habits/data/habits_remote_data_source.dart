import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/storage/db_time.dart';
import '../../pet/domain/pet_state.dart';
import '../../stats/domain/streak.dart';
import '../../stats/domain/user_stats.dart';
import '../domain/habit.dart';

class HabitsRemoteDataSource {
  HabitsRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<HabitEntity>> fetchHabits(
      {String userId = ApiConfig.defaultUserId}) async {
    final json = await _apiClient.getHabits(userId: userId);
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((item) => _mapHabit(Map<String, dynamic>.from(item as Map)))
        .toList();
    return items;
  }

  Future<HabitEntity> createHabit(
    HabitEntity habit, {
    String userId = ApiConfig.defaultUserId,
  }) async {
    final json = await _apiClient.createHabit(
      userId: userId,
      body: {
        'id': habit.id,
        'title': habit.title,
        'category': habit.category,
        'frequency': habit.frequency.name,
        'difficulty': habit.difficulty.name,
        if (habit.customDays != null && habit.customDays!.isNotEmpty)
          'custom_days': (habit.customDays!.toList()..sort()),
      },
    );
    return _mapHabit(json);
  }

  Future<HabitEntity> updateHabit(
    HabitEntity habit, {
    String userId = ApiConfig.defaultUserId,
  }) async {
    final json = await _apiClient.updateHabit(
      userId: userId,
      habitId: habit.id,
      body: {
        'title': habit.title,
        'category': habit.category,
        'frequency': habit.frequency.name,
        'difficulty': habit.difficulty.name,
        'custom_days': habit.customDays != null && habit.customDays!.isNotEmpty
            ? (habit.customDays!.toList()..sort())
            : <int>[],
      },
    );
    return _mapHabit(json);
  }

  Future<void> deleteHabit(String id,
      {String userId = ApiConfig.defaultUserId}) async {
    await _apiClient.deleteHabit(userId: userId, habitId: id);
  }

  Future<CompletionPayload> completeHabit(
    String habitId,
    DateTime completedAt, {
    String userId = ApiConfig.defaultUserId,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'completed_at': DbTime.format(completedAt),
    };
    if (notes != null && notes.isNotEmpty) {
      body['notes'] = notes;
    }
    final json = await _apiClient.completeHabit(
      userId: userId,
      habitId: habitId,
      body: body,
    );

    final streakJson = Map<String, dynamic>.from(json['streak'] as Map);
    final petJson = Map<String, dynamic>.from(json['pet_state'] as Map);
    final statsJson = Map<String, dynamic>.from(json['stats'] as Map);

    final streak = Streak(
      habitId: habitId,
      currentStreak: (streakJson['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (streakJson['best_streak'] as num?)?.toInt() ?? 0,
      lastCompleted: DbTime.parse(streakJson['last_completed'] as String?),
      updatedAt:
          DbTime.parse(streakJson['updated_at'] as String?) ?? completedAt,
    );

    final complexity = (petJson['structure_complexity'] as num?)?.toInt() ?? 0;
    final pet = PetState(
      level:
          (petJson['level'] as num?)?.toInt() ?? levelForComplexity(complexity),
      structureComplexity: complexity,
      damage: (petJson['damage'] as num?)?.toInt() ?? 0,
      energy: (petJson['energy'] as num?)?.toInt() ?? 0,
      mood: (petJson['mood'] as num?)?.toInt() ?? 0,
      stage: stageForComplexity(complexity),
    );

    final stats = UserStats(
      totalCompleted: (statsJson['total_completed'] as num?)?.toInt() ?? 0,
      completionRate: (statsJson['completion_rate'] as num?)?.toDouble() ?? 0.0,
      activeDays: (statsJson['active_days'] as num?)?.toInt() ?? 0,
      updatedAt:
          DbTime.parse(statsJson['updated_at'] as String?) ?? completedAt,
    );

    return CompletionPayload(streak: streak, petState: pet, stats: stats);
  }

  HabitEntity _mapHabit(Map<String, dynamic> json) {
    return HabitEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      frequency: HabitFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      difficulty: HabitDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => HabitDifficulty.medium,
      ),
      customDays: _parseCustomDays(json['custom_days']),
      currentStreak: 0,
      completedToday: false,
      createdAt:
          DbTime.parse(json['created_at'] as String?) ?? DateTime.now().toUtc(),
      updatedAt:
          DbTime.parse(json['updated_at'] as String?) ?? DateTime.now().toUtc(),
      deletedAt: DbTime.parse(json['deleted_at'] as String?),
      lastCompletedAt: DbTime.parse(json['last_completed'] as String?),
    );
  }

  static Set<int>? _parseCustomDays(dynamic raw) {
    if (raw is! List) return null;
    final out = <int>{};
    for (final item in raw) {
      final n = item is int ? item : int.tryParse(item.toString());
      if (n != null && n >= 1 && n <= 7) out.add(n);
    }
    return out.isEmpty ? null : out;
  }
}

class CompletionPayload {
  final Streak streak;
  final PetState petState;
  final UserStats stats;

  const CompletionPayload({
    required this.streak,
    required this.petState,
    required this.stats,
  });
}
