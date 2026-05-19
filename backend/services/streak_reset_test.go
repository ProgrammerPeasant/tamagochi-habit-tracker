package services

import (
	"testing"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

func ptrT(t time.Time) *time.Time { return &t }

func TestResetStaleStreaks_KeepsYesterdayCompletion(t *testing.T) {
	mem := freshMem("u")
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily,
		CreatedAt: time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC),
	}
	yesterday := time.Date(2026, 5, 18, 20, 0, 0, 0, time.UTC)
	mem.streaks["u:h1"] = domain.Streak{
		UserID: "u", HabitID: "h1", CurrentStreak: 5, BestStreak: 5,
		LastCompleted: ptrT(yesterday),
	}
	now := time.Date(2026, 5, 19, 9, 0, 0, 0, time.UTC) // next morning
	mem.resetStaleStreaksLocked("u", now)
	if got := mem.streaks["u:h1"].CurrentStreak; got != 5 {
		t.Fatalf("expected streak preserved (gap < 2 days), got %d", got)
	}
}

func TestResetStaleStreaks_ZerosAfterFullMissedDay(t *testing.T) {
	mem := freshMem("u")
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily,
		CreatedAt: time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC),
	}
	twoDaysAgo := time.Date(2026, 5, 17, 12, 0, 0, 0, time.UTC)
	mem.streaks["u:h1"] = domain.Streak{
		UserID: "u", HabitID: "h1", CurrentStreak: 5, BestStreak: 7,
		LastCompleted: ptrT(twoDaysAgo),
	}
	now := time.Date(2026, 5, 19, 9, 0, 0, 0, time.UTC)
	mem.resetStaleStreaksLocked("u", now)
	streak := mem.streaks["u:h1"]
	if streak.CurrentStreak != 0 {
		t.Fatalf("expected streak reset to 0, got %d", streak.CurrentStreak)
	}
	if streak.BestStreak != 7 {
		t.Fatalf("best streak must not change, got %d", streak.BestStreak)
	}
	if !streak.UpdatedAt.Equal(now) {
		t.Fatalf("UpdatedAt should advance to now, got %s", streak.UpdatedAt)
	}
}

func TestResetStaleStreaks_AppendsSyncChange(t *testing.T) {
	mem := freshMem("u")
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily,
		CreatedAt: time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC),
	}
	twoDaysAgo := time.Date(2026, 5, 17, 0, 0, 0, 0, time.UTC)
	mem.streaks["u:h1"] = domain.Streak{
		UserID: "u", HabitID: "h1", CurrentStreak: 4,
		LastCompleted: ptrT(twoDaysAgo),
	}
	now := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)
	mem.resetStaleStreaksLocked("u", now)
	found := false
	for _, ch := range mem.syncLog {
		if ch.Entity == domain.ChangeEntityStreak && ch.EntityID == "h1" {
			if v, ok := ch.Payload["current_streak"].(int); ok && v == 0 {
				found = true
				break
			}
		}
	}
	if !found {
		t.Fatalf("expected a sync change for the reset streak; log: %+v", mem.syncLog)
	}
}

func TestResetStaleStreaks_IgnoresWeekly(t *testing.T) {
	mem := freshMem("u")
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyWeekly,
		CreatedAt: time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC),
	}
	twoDaysAgo := time.Date(2026, 5, 17, 0, 0, 0, 0, time.UTC)
	mem.streaks["u:h1"] = domain.Streak{
		UserID: "u", HabitID: "h1", CurrentStreak: 4,
		LastCompleted: ptrT(twoDaysAgo),
	}
	now := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)
	mem.resetStaleStreaksLocked("u", now)
	if mem.streaks["u:h1"].CurrentStreak != 4 {
		t.Fatalf("weekly streak should not be auto-reset, got %d", mem.streaks["u:h1"].CurrentStreak)
	}
}

func TestResetStaleStreaks_IgnoresZeroAndNil(t *testing.T) {
	mem := freshMem("u")
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily,
	}
	mem.streaks["u:h1"] = domain.Streak{
		UserID: "u", HabitID: "h1", CurrentStreak: 0, LastCompleted: nil,
	}
	mem.resetStaleStreaksLocked("u", time.Now().UTC())
	if mem.streaks["u:h1"].CurrentStreak != 0 {
		t.Fatalf("expected no-op")
	}
	// No sync change appended for a no-op.
	for _, ch := range mem.syncLog {
		if ch.Entity == domain.ChangeEntityStreak {
			t.Fatalf("unexpected sync change for no-op: %+v", ch)
		}
	}
}
