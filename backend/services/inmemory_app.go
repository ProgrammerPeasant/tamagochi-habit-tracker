package services

import (
	"context"
	"errors"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
	"origamit-tamagochi-tracker/backend/internal/auth"
)

type InMemoryApp struct {
	mu        sync.Mutex
	habits    map[string]domain.Habit
	habitLogs []domain.HabitLog
	streaks   map[string]domain.Streak
	petStates map[string]domain.PetState
	stats     map[string]domain.UserStats
	syncLog   []domain.SyncChange
	users     map[string]domain.User
	usersByID map[string]string
}

func NewInMemoryApp() *App {
	mem := &InMemoryApp{
		habits:    make(map[string]domain.Habit),
		streaks:   make(map[string]domain.Streak),
		petStates: make(map[string]domain.PetState),
		stats:     make(map[string]domain.UserStats),
		users:     make(map[string]domain.User),
		usersByID: make(map[string]string),
	}

	return &App{
		Habits:  mem,
		Streaks: mem,
		Pet:     mem,
		Stats:   mem,
		Sync:    mem,
		Auth:    mem,
	}
}

func (m *InMemoryApp) Register(ctx context.Context, email, password string) (domain.User, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" {
		return domain.User{}, errors.New("email required")
	}
	if len(password) < 6 {
		return domain.User{}, errors.New("password must be at least 6 characters")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.users[email]; exists {
		return domain.User{}, errors.New("user already exists")
	}

	hash, err := auth.HashPassword(password)
	if err != nil {
		return domain.User{}, err
	}

	user := domain.User{
		ID:           newID("usr"),
		Email:        email,
		PasswordHash: hash,
		CreatedAt:    time.Now().UTC(),
	}
	m.users[email] = user
	m.usersByID[user.ID] = email
	return user, nil
}

func (m *InMemoryApp) Authenticate(ctx context.Context, email, password string) (domain.User, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	m.mu.Lock()
	user, ok := m.users[email]
	m.mu.Unlock()
	if !ok {
		return domain.User{}, errors.New("invalid credentials")
	}
	if !auth.VerifyPassword(password, user.PasswordHash) {
		return domain.User{}, errors.New("invalid credentials")
	}
	return user, nil
}

func (m *InMemoryApp) CreateHabit(ctx context.Context, userID string, input CreateHabitInput) (domain.Habit, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	id := strings.TrimSpace(input.ID)
	if id == "" {
		id = newID("hab")
	}
	now := time.Now().UTC()

	difficulty := input.Difficulty
	if difficulty == "" {
		difficulty = domain.DifficultyMedium
	}
	habit := domain.Habit{
		ID:         id,
		UserID:     userID,
		Title:      input.Title,
		Category:   input.Category,
		Frequency:  input.Frequency,
		Difficulty: difficulty,
		CreatedAt:  now,
		UpdatedAt:  now,
	}

	m.habits[id] = habit
	m.appendChangeLocked(userID, "habit", "upsert", id, now, map[string]any{
		"title":      habit.Title,
		"category":   habit.Category,
		"frequency":  string(habit.Frequency),
		"difficulty": string(habit.Difficulty),
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
	if input.Difficulty != "" {
		habit.Difficulty = input.Difficulty
	}
	habit.UpdatedAt = time.Now().UTC()

	m.habits[habitID] = habit
	m.appendChangeLocked(userID, "habit", "upsert", habitID, habit.UpdatedAt, map[string]any{
		"title":      habit.Title,
		"category":   habit.Category,
		"frequency":  string(habit.Frequency),
		"difficulty": string(habit.Difficulty),
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

func (m *InMemoryApp) CompleteHabit(ctx context.Context, userID, habitID string, completedAt time.Time, notes string) (CompletionResult, error) {
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
		Notes:     notes,
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
		"habit_id":  habitID,
		"date":      log.Date.Format(time.RFC3339),
		"completed": true,
		"notes":     notes,
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
		m.applySyncChangeLocked(change)
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

func (m *InMemoryApp) applySyncChangeLocked(change domain.SyncChange) {
	switch change.Entity {
	case domain.ChangeEntityHabit:
		m.applyHabitChangeLocked(change)
	case domain.ChangeEntityHabitLog:
		m.applyHabitLogChangeLocked(change)
	case domain.ChangeEntityStreak:
		m.applyStreakChangeLocked(change)
	case domain.ChangeEntityPetState:
		m.applyPetStateChangeLocked(change)
	case domain.ChangeEntityStats:
		m.applyStatsChangeLocked(change)
	}
}

func (m *InMemoryApp) applyHabitChangeLocked(change domain.SyncChange) {
	habit := m.habits[change.EntityID]
	habit.ID = change.EntityID
	habit.UserID = change.UserID
	habit.UpdatedAt = change.UpdatedAt

	if change.Op == domain.ChangeOpDelete {
		deletedAt := change.UpdatedAt
		habit.DeletedAt = &deletedAt
		m.habits[change.EntityID] = habit
		return
	}

	if title, ok := change.Payload["title"].(string); ok {
		habit.Title = title
	}
	if category, ok := change.Payload["category"].(string); ok {
		habit.Category = category
	}
	if freq, ok := change.Payload["frequency"].(string); ok {
		habit.Frequency = domain.HabitFrequency(strings.ToLower(freq))
	}
	if diff, ok := change.Payload["difficulty"].(string); ok {
		habit.Difficulty = domain.HabitDifficulty(strings.ToLower(diff))
	}
	if habit.Difficulty == "" {
		habit.Difficulty = domain.DifficultyMedium
	}
	if habit.CreatedAt.IsZero() {
		habit.CreatedAt = change.UpdatedAt
	}
	m.habits[change.EntityID] = habit
}

func (m *InMemoryApp) applyHabitLogChangeLocked(change domain.SyncChange) {
	habitID, ok := change.Payload["habit_id"].(string)
	if !ok {
		return
	}
	if _, ok := m.habits[habitID]; !ok {
		return
	}
	for _, log := range m.habitLogs {
		if log.ID == change.EntityID {
			return
		}
	}

	completed := true
	if value, ok := change.Payload["completed"].(bool); ok {
		completed = value
	}

	completedAt := change.UpdatedAt
	if value, ok := change.Payload["date"].(string); ok {
		if parsed, err := time.Parse(time.RFC3339, value); err == nil {
			completedAt = parsed
		}
	}

	notes := ""
	if value, ok := change.Payload["notes"].(string); ok {
		notes = value
	}

	log := domain.HabitLog{
		ID:        change.EntityID,
		UserID:    change.UserID,
		HabitID:   habitID,
		Date:      completedAt.UTC(),
		Completed: completed,
		Notes:     notes,
		CreatedAt: change.UpdatedAt,
	}
	m.habitLogs = append(m.habitLogs, log)

	streakKey := change.UserID + ":" + habitID
	streak := m.streaks[streakKey]
	streak.UserID = change.UserID
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
	streak.UpdatedAt = change.UpdatedAt
	m.streaks[streakKey] = streak

	stats := m.stats[change.UserID]
	stats.UserID = change.UserID
	stats.TotalCompleted++
	stats.ActiveDays = computeActiveDays(m.habitLogs, change.UserID)
	stats.CompletionRate = computeCompletionRate(m.habitLogs, change.UserID)
	stats.UpdatedAt = change.UpdatedAt
	m.stats[change.UserID] = stats

	pet := m.petStates[change.UserID]
	pet.UserID = change.UserID
	pet = evolvePetState(pet, streak)
	pet.UpdatedAt = change.UpdatedAt
	m.petStates[change.UserID] = pet

	m.appendChangeLocked(change.UserID, "streak", "upsert", habitID, streak.UpdatedAt, map[string]any{
		"current_streak": streak.CurrentStreak,
		"best_streak":    streak.BestStreak,
		"last_completed": streak.LastCompleted.Format(time.RFC3339),
	})
	m.appendChangeLocked(change.UserID, "pet_state", "upsert", change.UserID, pet.UpdatedAt, map[string]any{
		"level":                pet.Level,
		"structure_complexity": pet.StructureComplexity,
		"damage":               pet.Damage,
		"energy":               pet.Energy,
		"mood":                 pet.Mood,
	})
	m.appendChangeLocked(change.UserID, "user_stats", "upsert", change.UserID, stats.UpdatedAt, map[string]any{
		"total_completed": stats.TotalCompleted,
		"completion_rate": stats.CompletionRate,
		"active_days":     stats.ActiveDays,
	})
}

func (m *InMemoryApp) applyStreakChangeLocked(change domain.SyncChange) {
	streak := m.streaks[change.UserID+":"+change.EntityID]
	streak.UserID = change.UserID
	streak.HabitID = change.EntityID
	if value, ok := change.Payload["current_streak"].(float64); ok {
		streak.CurrentStreak = int(value)
	}
	if value, ok := change.Payload["best_streak"].(float64); ok {
		streak.BestStreak = int(value)
	}
	if value, ok := change.Payload["last_completed"].(string); ok {
		if parsed, err := time.Parse(time.RFC3339, value); err == nil {
			streak.LastCompleted = ptrTime(parsed)
		}
	}
	streak.UpdatedAt = change.UpdatedAt
	m.streaks[change.UserID+":"+change.EntityID] = streak
}

func (m *InMemoryApp) applyPetStateChangeLocked(change domain.SyncChange) {
	pet := m.petStates[change.EntityID]
	pet.UserID = change.UserID
	pet.UpdatedAt = change.UpdatedAt
	if value, ok := change.Payload["level"].(float64); ok {
		pet.Level = int(value)
	}
	if value, ok := change.Payload["structure_complexity"].(float64); ok {
		pet.StructureComplexity = int(value)
	}
	if value, ok := change.Payload["damage"].(float64); ok {
		pet.Damage = int(value)
	}
	if value, ok := change.Payload["energy"].(float64); ok {
		pet.Energy = int(value)
	}
	if value, ok := change.Payload["mood"].(float64); ok {
		pet.Mood = int(value)
	}
	m.petStates[change.EntityID] = pet
}

func (m *InMemoryApp) applyStatsChangeLocked(change domain.SyncChange) {
	stats := m.stats[change.EntityID]
	stats.UserID = change.UserID
	stats.UpdatedAt = change.UpdatedAt
	if value, ok := change.Payload["total_completed"].(float64); ok {
		stats.TotalCompleted = int(value)
	}
	if value, ok := change.Payload["completion_rate"].(float64); ok {
		stats.CompletionRate = value
	}
	if value, ok := change.Payload["active_days"].(float64); ok {
		stats.ActiveDays = int(value)
	}
	m.stats[change.EntityID] = stats
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
