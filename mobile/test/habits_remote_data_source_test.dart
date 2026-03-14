import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:origamit/core/network/api_client.dart';
import 'package:origamit/features/habits/data/habits_remote_data_source.dart';
import 'package:origamit/features/habits/domain/habit.dart';
import 'package:origamit/features/pet/domain/pet_state.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(client: http.Client());

  Map<String, dynamic> habitsResponse = {};
  Map<String, dynamic> habitResponse = {};
  Map<String, dynamic> completionResponse = {};

  @override
  Future<Map<String, dynamic>> getHabits({required String userId}) async {
    return habitsResponse;
  }

  @override
  Future<Map<String, dynamic>> createHabit({
    required String userId,
    required Map<String, dynamic> body,
  }) async {
    return habitResponse;
  }

  @override
  Future<Map<String, dynamic>> updateHabit({
    required String userId,
    required String habitId,
    required Map<String, dynamic> body,
  }) async {
    return habitResponse;
  }

  @override
  Future<Map<String, dynamic>> completeHabit({
    required String userId,
    required String habitId,
    required Map<String, dynamic> body,
  }) async {
    return completionResponse;
  }
}

void main() {
  test('fetchHabits maps remote payload', () async {
    final api = FakeApiClient();
    api.habitsResponse = {
      'items': [
        {
          'id': 'hab_1',
          'title': 'Read',
          'category': 'Learning',
          'frequency': 'daily',
          'created_at': '2026-03-14T10:00:00Z',
          'updated_at': '2026-03-14T10:05:00Z',
        },
      ],
    };

    final ds = HabitsRemoteDataSource(apiClient: api);
    final items = await ds.fetchHabits();

    expect(items.length, 1);
    expect(items.first.id, 'hab_1');
    expect(items.first.frequency, HabitFrequency.daily);
    expect(items.first.createdAt.isUtc, isTrue);
  });

  test('createHabit maps response', () async {
    final api = FakeApiClient();
    api.habitResponse = {
      'id': 'hab_2',
      'title': 'Walk',
      'category': 'Wellness',
      'frequency': 'weekly',
      'created_at': '2026-03-14T10:00:00Z',
      'updated_at': '2026-03-14T10:00:00Z',
    };

    final ds = HabitsRemoteDataSource(apiClient: api);
    final created = await ds.createHabit(
      HabitEntity(
        id: 'hab_2',
        title: 'Walk',
        category: 'Wellness',
        frequency: HabitFrequency.weekly,
        currentStreak: 0,
        completedToday: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    expect(created.id, 'hab_2');
    expect(created.frequency, HabitFrequency.weekly);
  });

  test('completeHabit maps streak, pet, stats', () async {
    final api = FakeApiClient();
    api.completionResponse = {
      'streak': {
        'current_streak': 5,
        'best_streak': 8,
        'last_completed': '2026-03-14T08:00:00Z',
        'updated_at': '2026-03-14T08:05:00Z',
      },
      'pet_state': {
        'structure_complexity': 35,
        'damage': 2,
        'energy': 70,
        'mood': 80,
      },
      'stats': {
        'total_completed': 12,
        'completion_rate': 0.6,
        'active_days': 7,
        'updated_at': '2026-03-14T08:05:00Z',
      },
    };

    final ds = HabitsRemoteDataSource(apiClient: api);
    final completion = await ds.completeHabit(
      'hab_3',
      DateTime.parse('2026-03-14T08:05:00Z'),
    );

    expect(completion.streak.currentStreak, 5);
    expect(completion.streak.bestStreak, 8);
    expect(completion.stats.totalCompleted, 12);
    expect(completion.stats.completionRate, 0.6);
    expect(completion.petState.structureComplexity, 35);
    expect(completion.petState.stage, PetStage.simpleFold);
  });
}
