package services

import (
	"testing"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

func TestApplyMissedDayPenalty_NoOpForZero(t *testing.T) {
	in := domain.PetState{Level: 3, Energy: 50, Mood: 50, Damage: 10, StructureComplexity: 30}
	out := applyMissedDayPenalty(in, 0)
	if out != in {
		t.Fatalf("expected no-op for 0 missed habits, got %#v", out)
	}
}

func TestApplyMissedDayPenalty_OneHabit(t *testing.T) {
	in := domain.PetState{Level: 2, Energy: 50, Mood: 50, Damage: 10, StructureComplexity: 30}
	out := applyMissedDayPenalty(in, 1)
	if out.Energy != 48 || out.Mood != 47 || out.Damage != 12 || out.StructureComplexity != 29 {
		t.Fatalf("unexpected state after 1 missed habit: %#v", out)
	}
	if out.Level != 2 {
		t.Fatalf("level should not regress at damage<80, got %d", out.Level)
	}
}

func TestApplyMissedDayPenalty_ClampsLow(t *testing.T) {
	in := domain.PetState{Level: 1, Energy: 1, Mood: 1, Damage: 0, StructureComplexity: 0}
	out := applyMissedDayPenalty(in, 5)
	if out.Energy != 0 || out.Mood != 0 || out.StructureComplexity != 0 {
		t.Fatalf("expected lower clamp at 0, got %#v", out)
	}
}

func TestApplyMissedDayPenalty_RegressLevelAtHighDamage(t *testing.T) {
	in := domain.PetState{Level: 3, Damage: 75}
	out := applyMissedDayPenalty(in, 3) // +6 damage → 81 → regress
	if out.Damage != 81 {
		t.Fatalf("expected damage 81, got %d", out.Damage)
	}
	if out.Level != 2 {
		t.Fatalf("expected level 2 (regressed), got %d", out.Level)
	}
}

func TestRecomputePet_NoDailyHabits_NoOp(t *testing.T) {
	mem := freshMem("u")
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	out := mem.recomputePetLocked("u", now)
	if out.Energy != 0 || out.Mood != 0 || out.Damage != 0 {
		t.Fatalf("expected zero-state for user with no daily habits, got %#v", out)
	}
	if out.Level != 1 {
		t.Fatalf("expected default level 1, got %d", out.Level)
	}
}

func TestRecomputePet_MissedTwoDays(t *testing.T) {
	mem := freshMem("u")
	createdAt := time.Date(2026, 5, 15, 8, 0, 0, 0, time.UTC)
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily, CreatedAt: createdAt,
	}
	// Pet is fresh; UpdatedAt zero → anchor at createdAt.
	// Walk: May 16, 17, 18 → 3 missed days before May 19.
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	out := mem.recomputePetLocked("u", now)

	wantDamage := 3 * 2
	wantEnergyDelta := -3 * 2
	wantMoodDelta := -3 * 3
	if out.Damage != wantDamage {
		t.Fatalf("damage: want %d, got %d", wantDamage, out.Damage)
	}
	if out.Energy != clamp(wantEnergyDelta, 0, 100) {
		t.Fatalf("energy: want %d, got %d", clamp(wantEnergyDelta, 0, 100), out.Energy)
	}
	if out.Mood != clamp(wantMoodDelta, 0, 100) {
		t.Fatalf("mood: want %d, got %d", clamp(wantMoodDelta, 0, 100), out.Mood)
	}
	if !out.UpdatedAt.Equal(now) {
		t.Fatalf("UpdatedAt should be now, got %s", out.UpdatedAt)
	}
}

func TestRecomputePet_CompletionAvoidsPenalty(t *testing.T) {
	mem := freshMem("u")
	createdAt := time.Date(2026, 5, 17, 8, 0, 0, 0, time.UTC)
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily, CreatedAt: createdAt,
	}
	// Completed on May 17 → no missed day for May 17. May 18 still missed.
	mem.habitLogs = append(mem.habitLogs, domain.HabitLog{
		ID: "l1", UserID: "u", HabitID: "h1",
		Date:      time.Date(2026, 5, 17, 9, 0, 0, 0, time.UTC),
		Completed: true,
	})
	now := time.Date(2026, 5, 19, 12, 0, 0, 0, time.UTC)
	out := mem.recomputePetLocked("u", now)

	// Walk starts from anchor (createdAt May 17) + 1 day = May 18.
	// Only May 18 is iterated (May 19 is "today"). One missed day, one habit.
	if out.Damage != 2 {
		t.Fatalf("expected damage 2 (one missed day), got %d", out.Damage)
	}
}

func TestRecomputePet_CapsAtThirtyDays(t *testing.T) {
	mem := freshMem("u")
	createdAt := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily, CreatedAt: createdAt,
	}
	now := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC) // many months later
	out := mem.recomputePetLocked("u", now)
	// 30 iterations × +2 damage each, capped at 100.
	if out.Damage != 60 {
		t.Fatalf("expected damage 60 (30 days × 2), got %d", out.Damage)
	}
}

func TestRecomputePet_IgnoresWeekly(t *testing.T) {
	mem := freshMem("u")
	createdAt := time.Date(2026, 5, 15, 0, 0, 0, 0, time.UTC)
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyWeekly, CreatedAt: createdAt,
	}
	now := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)
	out := mem.recomputePetLocked("u", now)
	if out.Damage != 0 || out.Energy != 0 {
		t.Fatalf("weekly habits should not cause penalties, got %#v", out)
	}
}

func TestRecomputePet_IgnoresDeleted(t *testing.T) {
	mem := freshMem("u")
	deleted := time.Date(2026, 5, 14, 0, 0, 0, 0, time.UTC)
	mem.habits["h1"] = domain.Habit{
		ID: "h1", UserID: "u", Frequency: domain.FrequencyDaily,
		CreatedAt: time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC),
		DeletedAt: &deleted,
	}
	now := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)
	out := mem.recomputePetLocked("u", now)
	if out.Damage != 0 {
		t.Fatalf("deleted habits should not cause penalties, got %#v", out)
	}
}

func freshMem(_ string) *InMemoryApp {
	return &InMemoryApp{
		habits:    make(map[string]domain.Habit),
		streaks:   make(map[string]domain.Streak),
		petStates: make(map[string]domain.PetState),
		stats:     make(map[string]domain.UserStats),
		users:     make(map[string]domain.User),
		usersByID: make(map[string]string),
	}
}
