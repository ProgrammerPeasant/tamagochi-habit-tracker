# Stage 3 REST API

## Architecture Explanation

Stage 3 introduces the HTTP interface layer and application services boundary. The API uses a single router that maps REST endpoints to handlers. Each handler performs request validation, calls a service interface, and serializes consistent JSON responses. The services are represented by interfaces so the API does not depend on infrastructure details. For now, an in memory implementation is provided to keep the server runnable while Stage 4 and Stage 5 introduce persistent storage and more advanced logic.

Key API choices:

1. Versioned base path
All routes are under /v1 to preserve future compatibility.

2. Stateless request handling
Each handler pulls the user id from headers, validates JSON, and returns RFC3339 timestamps.

3. Service boundary
Handlers depend on interfaces. Switching to Postgres repositories will not change API code.

4. Deterministic outputs
Completion returns streak, pet state, and stats in one response, keeping UI updates atomic.

## Directory Structure

- backend/
  - api/
    - http/
      - api.go
      - types.go
  - cmd/
    - server/
      - main.go
  - services/
    - contracts.go
    - inmemory_app.go

## Code Examples

HTTP handler for completing a habit:

```go
func (a *API) handleHabitComplete(w http.ResponseWriter, r *http.Request, userID, habitID string) {
    if r.Method != http.MethodPost {
        writeError(w, http.StatusMethodNotAllowed, "method not allowed")
        return
    }

    var req completeHabitRequest
    if err := decodeJSON(r, &req); err != nil {
        writeError(w, http.StatusBadRequest, err.Error())
        return
    }

    completedAt := time.Now().UTC()
    if req.CompletedAt != "" {
        parsed, err := time.Parse(time.RFC3339, req.CompletedAt)
        if err != nil {
            writeError(w, http.StatusBadRequest, "invalid completed_at")
            return
        }
        completedAt = parsed
    }

    result, err := a.services.Habits.CompleteHabit(r.Context(), userID, habitID, completedAt)
    if err != nil {
        writeError(w, http.StatusNotFound, err.Error())
        return
    }

    writeJSON(w, http.StatusOK, map[string]any{
        "habit_id": result.HabitID,
        "streak":   mapStreak(result.Streak),
        "pet_state": mapPetState(result.Pet),
        "stats":    mapStats(result.Stats),
    })
}
```

Service contract:

```go
type HabitService interface {
    CreateHabit(ctx context.Context, userID string, input CreateHabitInput) (domain.Habit, error)
    ListHabits(ctx context.Context, userID string) ([]domain.Habit, error)
    UpdateHabit(ctx context.Context, userID, habitID string, input UpdateHabitInput) (domain.Habit, error)
    DeleteHabit(ctx context.Context, userID, habitID string) (DeleteResult, error)
    CompleteHabit(ctx context.Context, userID, habitID string, completedAt time.Time) (CompletionResult, error)
}
```

## API Contracts

Base path: /v1
All requests require Firebase Auth bearer token in production. For local development, the API accepts X-User-Id.

Endpoints:

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

Response payloads remain consistent with Stage 1 and Stage 2.

## Database Schemas

No schema changes in Stage 3. The schema defined in Stage 2 remains the source of truth and will be wired to repositories in the next stage.
