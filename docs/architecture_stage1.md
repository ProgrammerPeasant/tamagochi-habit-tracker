# Stage 1 Architecture

## Architecture Explanation

This system is a local first habit tracker with a deterministic origami companion. The mobile app is the source of truth while offline and reconciles with the backend via a sync API when network is available. All domain logic is modeled around explicit domain services and events. Completing a habit emits a HabitCompleted event that updates streaks, pet state, and user statistics in a single application service flow. The backend mirrors the same deterministic logic to ensure consistent results across devices and for server side features like notifications.

Key architectural choices:

1. Local first data model
All user actions write to SQLite immediately. A sync queue records outgoing changes. Sync uses timestamps and device ids to resolve conflicts, preferring the latest update and preserving tombstones for deletes.

2. Event driven domain updates
Habit completion generates a domain event. Application services handle the event and update Streak, PetState, and UserStats in one transaction.

3. Deterministic pet state
Pet state is computed from habit activity using fixed rules. This allows recalculation and reconciliation between client and server.

4. Clean Architecture
Domain entities and rules live in domain. Application services orchestrate use cases. Infrastructure implements repositories, database, and network clients. Interface layers expose REST APIs and Flutter UI.

5. Clear API contracts
All endpoints are versioned under /v1. Requests and responses are JSON. Sync uses a cursor and a list of changes.

## Directory Structure

Monorepo layout:

- backend/
  - api/
  - cmd/
  - domain/
  - internal/
  - pkg/
  - repository/
  - scheduler/
  - services/
- docs/
- mobile/
  - lib/
    - core/
    - features/
      - habits/
        - data/
        - domain/
        - presentation/
      - pet/
        - data/
        - domain/
        - presentation/
      - stats/
        - data/
        - domain/
        - presentation/
      - notifications/
        - data/
        - domain/
        - presentation/

## Code Examples

Go domain entities and service interfaces:

```go
package domain

import "time"

type Habit struct {
    ID        string
    UserID    string
    Title     string
    Category  string
    Frequency string
    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt *time.Time
}

type HabitLog struct {
    ID        string
    UserID    string
    HabitID   string
    Date      time.Time
    Completed bool
    CreatedAt time.Time
}

type Streak struct {
    UserID        string
    HabitID       string
    CurrentStreak int
    BestStreak    int
    LastCompleted *time.Time
}

type PetState struct {
    UserID              string
    Level               int
    StructureComplexity int
    Damage              int
    Energy              int
    Mood                int
    UpdatedAt           time.Time
}

type UserStats struct {
    UserID         string
    TotalCompleted int
    CompletionRate float64
    ActiveDays     int
    UpdatedAt      time.Time
}

// Application service contract for completing a habit.
type HabitCompletionService interface {
    CompleteHabit(userID, habitID string, completedAt time.Time) error
}
```

Flutter domain entity and repository contract:

```dart
class HabitEntity {
  final String id;
  final String title;
  final String category;
  final String frequency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.frequency,
    required this.createdAt,
    required this.updatedAt,
  });
}

abstract class HabitRepository {
  Future<List<HabitEntity>> getHabits();
  Future<void> upsertHabit(HabitEntity habit);
  Future<void> deleteHabit(String id);
  Future<void> completeHabit(String id, DateTime completedAt);
}
```

## API Contracts

Base path: /v1
All requests require Firebase Auth bearer token.

POST /habits
Request:
{
  "title": "Read",
  "category": "Learning",
  "frequency": "daily"
}
Response:
{
  "id": "hab_123",
  "title": "Read",
  "category": "Learning",
  "frequency": "daily",
  "created_at": "2026-03-12T20:30:00Z",
  "updated_at": "2026-03-12T20:30:00Z"
}

GET /habits
Response:
{
  "items": [
    {
      "id": "hab_123",
      "title": "Read",
      "category": "Learning",
      "frequency": "daily",
      "created_at": "2026-03-12T20:30:00Z",
      "updated_at": "2026-03-12T20:30:00Z"
    }
  ]
}

PATCH /habits/{id}
Request:
{
  "title": "Read 20 min",
  "category": "Learning",
  "frequency": "daily"
}
Response:
{
  "id": "hab_123",
  "title": "Read 20 min",
  "category": "Learning",
  "frequency": "daily",
  "created_at": "2026-03-12T20:30:00Z",
  "updated_at": "2026-03-12T21:00:00Z"
}

DELETE /habits/{id}
Response:
{
  "id": "hab_123",
  "deleted": true,
  "deleted_at": "2026-03-12T21:30:00Z"
}

POST /habits/{id}/complete
Request:
{
  "completed_at": "2026-03-12T21:15:00Z"
}
Response:
{
  "habit_id": "hab_123",
  "streak": {
    "current_streak": 5,
    "best_streak": 7,
    "last_completed": "2026-03-12T21:15:00Z"
  },
  "pet_state": {
    "level": 2,
    "structure_complexity": 14,
    "damage": 1,
    "energy": 32,
    "mood": 78
  },
  "stats": {
    "total_completed": 58,
    "completion_rate": 0.82,
    "active_days": 41
  }
}

GET /pet
Response:
{
  "level": 2,
  "structure_complexity": 14,
  "damage": 1,
  "energy": 32,
  "mood": 78,
  "updated_at": "2026-03-12T21:15:00Z"
}

GET /stats
Response:
{
  "total_completed": 58,
  "completion_rate": 0.82,
  "active_days": 41,
  "updated_at": "2026-03-12T21:15:00Z"
}

GET /streaks
Response:
{
  "items": [
    {
      "habit_id": "hab_123",
      "current_streak": 5,
      "best_streak": 7,
      "last_completed": "2026-03-12T21:15:00Z"
    }
  ]
}

POST /sync
Request:
{
  "device_id": "dev_abc",
  "cursor": "2026-03-12T20:00:00Z",
  "changes": [
    {
      "entity": "habit",
      "op": "upsert",
      "id": "hab_123",
      "updated_at": "2026-03-12T21:00:00Z",
      "payload": { "title": "Read 20 min", "category": "Learning", "frequency": "daily" }
    }
  ]
}
Response:
{
  "cursor": "2026-03-12T21:30:00Z",
  "changes": [
    {
      "entity": "pet_state",
      "op": "upsert",
      "id": "pet_main",
      "updated_at": "2026-03-12T21:15:00Z",
      "payload": { "level": 2, "structure_complexity": 14, "damage": 1, "energy": 32, "mood": 78 }
    }
  ]
}

GET /sync?cursor=2026-03-12T20:00:00Z&device_id=dev_abc
Response:
{
  "cursor": "2026-03-12T21:30:00Z",
  "changes": []
}

## Database Schemas

PostgreSQL schema (backend):

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE habit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  date DATE NOT NULL,
  completed BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE streaks (
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  current_streak INT NOT NULL,
  best_streak INT NOT NULL,
  last_completed TIMESTAMPTZ,
  PRIMARY KEY (user_id, habit_id)
);

CREATE TABLE pet_state (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  level INT NOT NULL,
  structure_complexity INT NOT NULL,
  damage INT NOT NULL,
  energy INT NOT NULL,
  mood INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE user_stats (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  total_completed INT NOT NULL,
  completion_rate DOUBLE PRECISION NOT NULL,
  active_days INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE sync_changes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  device_id TEXT NOT NULL,
  entity TEXT NOT NULL,
  op TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
```

SQLite schema (mobile):

```sql
CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  deleted_at TEXT
);

CREATE TABLE habit_logs (
  id TEXT PRIMARY KEY,
  habit_id TEXT NOT NULL,
  date TEXT NOT NULL,
  completed INTEGER NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE streaks (
  habit_id TEXT PRIMARY KEY,
  current_streak INTEGER NOT NULL,
  best_streak INTEGER NOT NULL,
  last_completed TEXT
);

CREATE TABLE pet_state (
  id TEXT PRIMARY KEY,
  level INTEGER NOT NULL,
  structure_complexity INTEGER NOT NULL,
  damage INTEGER NOT NULL,
  energy INTEGER NOT NULL,
  mood INTEGER NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE user_stats (
  id TEXT PRIMARY KEY,
  total_completed INTEGER NOT NULL,
  completion_rate REAL NOT NULL,
  active_days INTEGER NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  op TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  device_id TEXT NOT NULL
);
```
