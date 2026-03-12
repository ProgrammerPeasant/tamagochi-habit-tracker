package services

import (
	"context"
	"errors"
	"math"
	"sort"
	"sync"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

type InMemoryApp struct {
	mu        sync.Mutex
	habits    map[string]domain.Habit
	habitLogs []domain.HabitLog
	streaks   map[string]domain.Streak
	petStates map[string]domain.PetState
	stats     map[string]domain.UserStats
	syncLog   []domain.SyncChange
}

func NewInMemoryApp() *App {
	mem := &InMemoryApp{
		habits:    make(map[string]domain.Habit),
		streaks:   make(map[string]domain.Streak),
		petStates: make(map[string]domain.PetState),
		stats:     make(map[string]domain.UserStats),
	}

	return &App{
		Habits:  mem,
		Streaks: mem,
		Pet:     mem,
		Stats:   mem,
		Sync:    mem,
	}
}

func (m *InMemoryApp) CreateHabit(ctx context.Context, userID string, input CreateHabitInput) (domain.Habit, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	id := newID("hab")
	now := time.Now().UTC()

	habit := domain.Habit{
		ID:        id,
		UserID:    userID,
		Title:     input.Title,
		Category:  input.Category,
		Frequency: input.Frequency,
		CreatedAt: now,
		UpdatedAt: now,
	}

	m.habits[id] = habit
	m.appendChangeLocked(userID, "habit", "upsert", id, now, map[string]any{
		"title":     habit.Title,
		"category":  habit.Category,
		"frequency": string(habit.Frequency),
	})

	return habit, nil
}

func (m *InMemoryApp) ListHabits(ctx context.Context, userID string) ([]domain.Habit, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	items := make([]domain.Habit, 0)
	for _, habit := range m.habits {
		if habit.UserID != userID {
			continue
		}
		items = append(items, habit)
	}

	sort.Slice(items, func(i, j int) bool {
		return items[i].CreatedAt.Before(items[j].CreatedAt)
	})

	return items, nil
}

func (m *InMemoryApp) UpdateHabit(ctx context.Context, userID, habitID string, input UpdateHabitInput) (domain.Habit, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	habit, ok := m.habits[habitID]
	if !ok || habit.UserID != userID {
		return domain.Habit{}, errors.New("habit not found")
	}

	habit.Title = input.Title
	habit.Category = input.Category
	habit.Frequency = input.Frequency
	habit.UpdatedAt = time.Now().UTC()

	m.habits[habitID] = habit
	m.appendChangeLocked(userID, "habit", "upsert", habitID, habit.UpdatedAt, map[string]any{
		"title":     habit.Title,
		"category":  habit.Category,
		"frequency": string(habit.Frequency),
	})

	return habit, nil
}

func (m *InMemoryApp) DeleteHabit(ctx context.Context, userID, habitID string) (DeleteResult, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	habit, ok := m.habits[habitID]
	if !ok || habit.UserID != userID {
		return DeleteResult{}, errors.New("habit not found")
	}

	deletedAt := time.Now().UTC()
	habit.DeletedAt = &deletedAt
	habit.UpdatedAt = deletedAt
	m.habits[habitID] = habit

	m.appendChangeLocked(userID, "habit", "delete", habitID, deletedAt, map[string]any{})

	return DeleteResult{ID: habitID, DeletedAt: deletedAt}, nil
}

func (m *InMemoryApp) CompleteHabit(ctx context.Context, userID, habitID string, completedAt time.Time) (CompletionResult, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	habit, ok := m.habits[habitID]
	if !ok || habit.UserID != userID {
		return CompletionResult{}, errors.New("habit not found")
	}

	log := domain.HabitLog{
		ID:        newID("log"),
		UserID:    userID,
		HabitID:   habitID,
		Date:      completedAt.UTC(),
		Completed: true,
		CreatedAt: time.Now().UTC(),
	}
	m.habitLogs = append(m.habitLogs, log)

	streakKey := userID + ":" + habitID
	streak := m.streaks[streakKey]
	streak.UserID = userID
	streak.HabitID = habitID

	if streak.LastCompleted == nil || !isSameDay(*streak.LastCompleted, completedAt) {
		if streak.LastCompleted != nil && isYesterday(*streak.LastCompleted, completedAt) {
			streak.CurrentStreak++
		} else {
			streak.CurrentStreak = 1
		}
	}

	if streak.CurrentStreak > streak.BestStreak {
		streak.BestStreak = streak.CurrentStreak
	}

	streak.LastCompleted = ptrTime(completedAt.UTC())
	streak.UpdatedAt = time.Now().UTC()
	m.streaks[streakKey] = streak

	stats := m.stats[userID]
	stats.UserID = userID
	stats.TotalCompleted++
	stats.ActiveDays = computeActiveDays(m.habitLogs, userID)
	stats.CompletionRate = computeCompletionRate(m.habitLogs, userID)
	stats.UpdatedAt = time.Now().UTC()
	m.stats[userID] = stats

	pet := m.petStates[userID]
	pet.UserID = userID
	pet = evolvePetState(pet, streak)
	pet.UpdatedAt = time.Now().UTC()
	m.petStates[userID] = pet

	m.appendChangeLocked(userID, "habit_log", "upsert", log.ID, log.CreatedAt, map[string]any{
		"habit_id": habitID,
		"date":     log.Date.Format(time.RFC3339),
		"completed": true,
	})
	m.appendChangeLocked(userID, "streak", "upsert", habitID, streak.UpdatedAt, map[string]any{
		"current_streak": streak.CurrentStreak,
		"best_streak":    streak.BestStreak,
		"last_completed": streak.LastCompleted.Format(time.RFC3339),
	})
	m.appendChangeLocked(userID, "pet_state", "upsert", userID, pet.UpdatedAt, map[string]any{
		"level":                pet.Level,
		"structure_complexity": pet.StructureComplexity,
		"damage":               pet.Damage,
		"energy":               pet.Energy,
		"mood":                 pet.Mood,
	})
	m.appendChangeLocked(userID, "user_stats", "upsert", userID, stats.UpdatedAt, map[string]any{
		"total_completed": stats.TotalCompleted,
		"completion_rate": stats.CompletionRate,
		"active_days":     stats.ActiveDays,
	})

	return CompletionResult{
		HabitID: habitID,
		Streak:  streak,
		Pet:     pet,
		Stats:   stats,
	}, nil
}

func (m *InMemoryApp) ListStreaks(ctx context.Context, userID string) ([]domain.Streak, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	items := make([]domain.Streak, 0)
	for _, streak := range m.streaks {
		if streak.UserID == userID {
			items = append(items, streak)
		}
	}

	return items, nil
}

func (m *InMemoryApp) GetPetState(ctx context.Context, userID string) (domain.PetState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	state, ok := m.petStates[userID]
	if !ok {
		state = domain.PetState{UserID: userID, Level: 1}
		m.petStates[userID] = state
	}

	return state, nil
}

func (m *InMemoryApp) GetUserStats(ctx context.Context, userID string) (domain.UserStats, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	stats, ok := m.stats[userID]
	if !ok {
		stats = domain.UserStats{UserID: userID}
		m.stats[userID] = stats
	}

	return stats, nil
}

func (m *InMemoryApp) PushPull(ctx context.Context, userID, deviceID string, cursor time.Time, changes []domain.SyncChange) (time.Time, []domain.SyncChange, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	for _, change := range changes {
		change.ID = newID("chg")
		change.UserID = userID
		change.DeviceID = deviceID
		m.syncLog = append(m.syncLog, change)
	}

	newCursor, outbound := m.pullSinceLocked(userID, deviceID, cursor)
	return newCursor, outbound, nil
}

func (m *InMemoryApp) PullSince(ctx context.Context, userID, deviceID string, cursor time.Time) (time.Time, []domain.SyncChange, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	newCursor, outbound := m.pullSinceLocked(userID, deviceID, cursor)
	return newCursor, outbound, nil
}

func (m *InMemoryApp) pullSinceLocked(userID, deviceID string, cursor time.Time) (time.Time, []domain.SyncChange) {
	changes := make([]domain.SyncChange, 0)
	latest := cursor

	for _, change := range m.syncLog {
		if change.UserID != userID || change.DeviceID == deviceID {
			continue
		}
		if change.UpdatedAt.After(cursor) {
			changes = append(changes, change)
			if change.UpdatedAt.After(latest) {
				latest = change.UpdatedAt
			}
		}
	}

	if latest.Equal(cursor) {
		latest = time.Now().UTC()
	}

	return latest, changes
}

func (m *InMemoryApp) appendChangeLocked(userID, entity, op, entityID string, updatedAt time.Time, payload map[string]any) {
	m.syncLog = append(m.syncLog, domain.SyncChange{
		ID:        newID("chg"),
		UserID:    userID,
		DeviceID:  "server",
		Entity:    domain.ChangeEntity(entity),
		Op:        domain.ChangeOp(op),
		EntityID:  entityID,
		Payload:   payload,
		UpdatedAt: updatedAt,
	})
}

func newID(prefix string) string {
	return prefix + "_" + time.Now().UTC().Format("20060102150405.000000000")
}

func ptrTime(t time.Time) *time.Time {
	return &t
}

func isSameDay(a, b time.Time) bool {
	ay, am, ad := a.Date()
	by, bm, bd := b.Date()
	return ay == by && am == bm && ad == bd
}

func isYesterday(last, current time.Time) bool {
	lastDay := time.Date(last.Year(), last.Month(), last.Day(), 0, 0, 0, 0, time.UTC)
	currentDay := time.Date(current.Year(), current.Month(), current.Day(), 0, 0, 0, 0, time.UTC)
	return currentDay.Sub(lastDay) == 24*time.Hour
}

func computeActiveDays(logs []domain.HabitLog, userID string) int {
	set := make(map[string]struct{})
	for _, log := range logs {
		if log.UserID != userID || !log.Completed {
			continue
		}
		key := log.Date.Format("2006-01-02")
		set[key] = struct{}{}
	}
	return len(set)
}

func computeCompletionRate(logs []domain.HabitLog, userID string) float64 {
	total := 0
	completed := 0
	for _, log := range logs {
		if log.UserID != userID {
			continue
		}
		total++
		if log.Completed {
			completed++
		}
	}
	if total == 0 {
		return 0
	}
	return math.Round((float64(completed)/float64(total))*100) / 100
}

func evolvePetState(current domain.PetState, streak domain.Streak) domain.PetState {
	level := 1
	if streak.BestStreak >= 3 {
		level = 2
	}
	if streak.BestStreak >= 7 {
		level = 3
	}
	if streak.BestStreak >= 14 {
		level = 4
	}
	if streak.BestStreak >= 30 {
		level = 5
	}

	current.Level = level
	current.StructureComplexity = clamp(current.StructureComplexity+2, 0, 200)
	current.Energy = clamp(current.Energy+3, 0, 100)
	current.Mood = clamp(current.Mood+4, 0, 100)
	current.Damage = clamp(current.Damage-1, 0, 100)

	return current
}

func clamp(value, min, max int) int {
	if value < min {
		return min
	}
	if value > max {
		return max
	}
	return value
}

