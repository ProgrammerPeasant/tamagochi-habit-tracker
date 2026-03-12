# Stage 2 Backend Domain Models and Database Schema

## Architecture Explanation

Stage 2 formalizes the backend domain model and persistence foundation. The domain layer now contains explicit entities and value types for habits, logs, streaks, pet state, and user stats. Repository interfaces define the storage contract without binding to a database implementation. This keeps business rules portable across Postgres, tests, and any future storage providers.

The database schema mirrors the domain model and is written as a baseline migration. It includes indices for common queries and uses soft deletes for habits to support local first sync and conflict resolution.

## Directory Structure

- backend/
  - domain/
    - habit.go
    - habit_log.go
    - pet_state.go
    - streak.go
    - sync_change.go
    - user_stats.go
  - repository/
    - habit_repository.go
    - pet_state_repository.go
    - streak_repository.go
    - sync_change_repository.go
    - user_stats_repository.go
  - internal/
    - db/
      - migrations/
        - 0001_init.sql

## Code Examples

Domain entity and value types:

```go
package domain

import "time"

type HabitFrequency string

const (
    FrequencyDaily  HabitFrequency = "daily"
    FrequencyWeekly HabitFrequency = "weekly"
    FrequencyCustom HabitFrequency = "custom"
)

type Habit struct {
    ID        string
    UserID    string
    Title     string
    Category  string
    Frequency HabitFrequency
    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt *time.Time
}
```

Repository contract:

```go
package repository

import (
    "context"
    "time"

    "origamit-tamagochi-tracker/backend/domain"
)

type HabitRepository interface {
    List(ctx context.Context, userID string) ([]domain.Habit, error)
    Get(ctx context.Context, userID, habitID string) (domain.Habit, error)
    Upsert(ctx context.Context, habit domain.Habit) error
    MarkDeleted(ctx context.Context, userID, habitID string, deletedAt time.Time) error
}
```

## API Contracts

Base path: /v1
All requests require Firebase Auth bearer token.

The contracts remain aligned with Stage 1 and will be implemented in Stage 3. Key endpoints:

- POST /habits
- GET /habits
- PATCH /habits/{id}
- DELETE /habits/{id}
- POST /habits/{id}/complete
- GET /pet
- GET /stats
- GET /streaks
- POST /sync
- GET /sync

## Database Schemas

PostgreSQL schema (migration file in backend/internal/db/migrations/0001_init.sql):

```sql
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS habits (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ("daily", "weekly", "custom")),
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS habit_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  date DATE NOT NULL,
  completed BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS streaks (
  user_id TEXT NOT NULL REFERENCES users(id),
  habit_id TEXT NOT NULL REFERENCES habits(id),
  current_streak INT NOT NULL,
  best_streak INT NOT NULL,
  last_completed TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (user_id, habit_id)
);

CREATE TABLE IF NOT EXISTS pet_state (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  level INT NOT NULL,
  structure_complexity INT NOT NULL,
  damage INT NOT NULL,
  energy INT NOT NULL,
  mood INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS user_stats (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  total_completed INT NOT NULL,
  completion_rate DOUBLE PRECISION NOT NULL,
  active_days INT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_changes (
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
