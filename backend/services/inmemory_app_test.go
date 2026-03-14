package services

import (
	"context"
	"strings"
	"testing"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

func TestHabitCRUD(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_1"

	created, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		Title:     "Read",
		Category:  "Learning",
		Frequency: "daily",
	})
	if err != nil {
		t.Fatalf("create habit: %v", err)
	}
	if !strings.HasPrefix(created.ID, "hab_") {
		t.Fatalf("expected id prefix hab_, got %s", created.ID)
	}

	items, err := app.Habits.ListHabits(ctx, userID)
	if err != nil {
		t.Fatalf("list habits: %v", err)
	}
	if len(items) != 1 {
		t.Fatalf("expected 1 habit, got %d", len(items))
	}

	updated, err := app.Habits.UpdateHabit(ctx, userID, created.ID, UpdateHabitInput{
		Title:     "Read more",
		Category:  "Learning",
		Frequency: "weekly",
	})
	if err != nil {
		t.Fatalf("update habit: %v", err)
	}
	if updated.Title != "Read more" {
		t.Fatalf("expected updated title, got %s", updated.Title)
	}

	result, err := app.Habits.DeleteHabit(ctx, userID, created.ID)
	if err != nil {
		t.Fatalf("delete habit: %v", err)
	}
	if result.DeletedAt.IsZero() {
		t.Fatal("expected deleted_at to be set")
	}

	if _, err := app.Habits.UpdateHabit(ctx, userID, "missing", UpdateHabitInput{
		Title:     "X",
		Category:  "Y",
		Frequency: "daily",
	}); err == nil {
		t.Fatal("expected error on updating missing habit")
	}
}

func TestCompleteHabitProgression(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_2"

	habit, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		ID:        "hab_test",
		Title:     "Walk",
		Category:  "Wellness",
		Frequency: "daily",
	})
	if err != nil {
		t.Fatalf("create habit: %v", err)
	}

	day1 := time.Date(2026, 1, 1, 10, 0, 0, 0, time.UTC)
	day2 := day1.Add(24 * time.Hour)
	day3 := day2.Add(24 * time.Hour)

	first, err := app.Habits.CompleteHabit(ctx, userID, habit.ID, day1)
	if err != nil {
		t.Fatalf("complete day1: %v", err)
	}
	if first.Streak.CurrentStreak != 1 || first.Streak.BestStreak != 1 {
		t.Fatalf("unexpected streak after day1: %+v", first.Streak)
	}

	second, err := app.Habits.CompleteHabit(ctx, userID, habit.ID, day2)
	if err != nil {
		t.Fatalf("complete day2: %v", err)
	}
	if second.Streak.CurrentStreak != 2 || second.Streak.BestStreak != 2 {
		t.Fatalf("unexpected streak after day2: %+v", second.Streak)
	}

	third, err := app.Habits.CompleteHabit(ctx, userID, habit.ID, day3)
	if err != nil {
		t.Fatalf("complete day3: %v", err)
	}
	if third.Streak.CurrentStreak != 3 || third.Streak.BestStreak != 3 {
		t.Fatalf("unexpected streak after day3: %+v", third.Streak)
	}
	if third.Pet.Level != 2 {
		t.Fatalf("expected pet level 2 after 3-day streak, got %d", third.Pet.Level)
	}
	if third.Stats.TotalCompleted != 3 {
		t.Fatalf("expected total completed 3, got %d", third.Stats.TotalCompleted)
	}
	if third.Stats.ActiveDays != 3 {
		t.Fatalf("expected active days 3, got %d", third.Stats.ActiveDays)
	}
	if third.Stats.CompletionRate != 1 {
		t.Fatalf("expected completion rate 1, got %v", third.Stats.CompletionRate)
	}
}

func TestSyncPullSince(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_3"

	if _, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		ID:        "hab_sync",
		Title:     "Stretch",
		Category:  "Health",
		Frequency: "daily",
	}); err != nil {
		t.Fatalf("create habit: %v", err)
	}

	cursor, changes, err := app.Sync.PullSince(ctx, userID, "device_a", time.Time{})
	if err != nil {
		t.Fatalf("pull since: %v", err)
	}
	if cursor.IsZero() {
		t.Fatal("expected non-zero cursor")
	}
	if len(changes) == 0 {
		t.Fatal("expected changes to be returned")
	}
}

func TestDefaultsAndStreakListing(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_defaults"

	pet, err := app.Pet.GetPetState(ctx, userID)
	if err != nil {
		t.Fatalf("get pet state: %v", err)
	}
	if pet.Level != 1 {
		t.Fatalf("expected default pet level 1, got %d", pet.Level)
	}

	stats, err := app.Stats.GetUserStats(ctx, userID)
	if err != nil {
		t.Fatalf("get user stats: %v", err)
	}
	if stats.TotalCompleted != 0 || stats.ActiveDays != 0 || stats.CompletionRate != 0 {
		t.Fatalf("expected zeroed stats, got %+v", stats)
	}

	h1, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		ID:        "hab_a",
		Title:     "A",
		Category:  "Cat",
		Frequency: "daily",
	})
	if err != nil {
		t.Fatalf("create habit: %v", err)
	}
	h2, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		ID:        "hab_b",
		Title:     "B",
		Category:  "Cat",
		Frequency: "daily",
	})
	if err != nil {
		t.Fatalf("create habit: %v", err)
	}

	_, _ = app.Habits.CompleteHabit(ctx, userID, h1.ID, time.Now().UTC())
	_, _ = app.Habits.CompleteHabit(ctx, userID, h2.ID, time.Now().UTC())

	otherID := "user_other"
	otherHabit, _ := app.Habits.CreateHabit(ctx, otherID, CreateHabitInput{
		ID:        "hab_other",
		Title:     "O",
		Category:  "Cat",
		Frequency: "daily",
	})
	_, _ = app.Habits.CompleteHabit(ctx, otherID, otherHabit.ID, time.Now().UTC())

	streaks, err := app.Streaks.ListStreaks(ctx, userID)
	if err != nil {
		t.Fatalf("list streaks: %v", err)
	}
	if len(streaks) != 2 {
		t.Fatalf("expected 2 streaks for user, got %d", len(streaks))
	}
}

func TestStreakResetsAfterGap(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_gap"

	habit, err := app.Habits.CreateHabit(ctx, userID, CreateHabitInput{
		ID:        "hab_gap",
		Title:     "Gap",
		Category:  "Test",
		Frequency: "daily",
	})
	if err != nil {
		t.Fatalf("create habit: %v", err)
	}

	day1 := time.Date(2026, 1, 1, 9, 0, 0, 0, time.UTC)
	day3 := day1.Add(48 * time.Hour)

	first, err := app.Habits.CompleteHabit(ctx, userID, habit.ID, day1)
	if err != nil {
		t.Fatalf("complete day1: %v", err)
	}
	if first.Streak.CurrentStreak != 1 {
		t.Fatalf("expected streak 1 after day1, got %d", first.Streak.CurrentStreak)
	}

	third, err := app.Habits.CompleteHabit(ctx, userID, habit.ID, day3)
	if err != nil {
		t.Fatalf("complete day3: %v", err)
	}
	if third.Streak.CurrentStreak != 1 {
		t.Fatalf("expected streak reset to 1 after gap, got %d", third.Streak.CurrentStreak)
	}
	if third.Streak.BestStreak != 1 {
		t.Fatalf("expected best streak 1 after gap, got %d", third.Streak.BestStreak)
	}
}

func TestSyncPushPullAppliesAndFiltersByDevice(t *testing.T) {
	app := NewInMemoryApp()
	ctx := context.Background()
	userID := "user_sync"

	updatedAt := time.Date(2026, 2, 1, 12, 0, 0, 0, time.UTC)
	change := domain.SyncChange{
		Entity:   domain.ChangeEntityHabit,
		Op:       domain.ChangeOpUpsert,
		EntityID: "hab_client",
		Payload: map[string]any{
			"title":       "Client habit",
			"category":    "Test",
			"frequency":   "daily",
			"created_at":  updatedAt.Format(time.RFC3339),
			"updated_at":  updatedAt.Format(time.RFC3339),
			"deleted_at":  nil,
			"completed_today": 0,
			"current_streak":  0,
		},
		UpdatedAt: updatedAt,
	}

	cursor, outbound, err := app.Sync.PushPull(ctx, userID, "device_a", time.Time{}, []domain.SyncChange{change})
	if err != nil {
		t.Fatalf("pushpull: %v", err)
	}
	if cursor.IsZero() {
		t.Fatal("expected cursor to be set")
	}
	if len(outbound) != 0 {
		t.Fatalf("expected no outbound changes for same device, got %d", len(outbound))
	}

	habits, err := app.Habits.ListHabits(ctx, userID)
	if err != nil {
		t.Fatalf("list habits: %v", err)
	}
	if len(habits) != 1 || habits[0].Title != "Client habit" {
		t.Fatalf("expected habit applied from sync, got %+v", habits)
	}

	_, inbound, err := app.Sync.PullSince(ctx, userID, "device_b", time.Time{})
	if err != nil {
		t.Fatalf("pullsince: %v", err)
	}
	if len(inbound) == 0 {
		t.Fatal("expected inbound changes for other device")
	}
}
