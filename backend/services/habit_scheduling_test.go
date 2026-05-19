package services

import (
	"testing"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

func TestIsHabitDueOn_Daily(t *testing.T) {
	created := time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC) // Tue
	h := domain.Habit{Frequency: domain.FrequencyDaily, CreatedAt: created}
	if !isHabitDueOn(h, time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)) {
		t.Fatal("daily must be due on its created day")
	}
	if !isHabitDueOn(h, time.Date(2026, 5, 22, 0, 0, 0, 0, time.UTC)) {
		t.Fatal("daily must be due every day")
	}
}

func TestIsHabitDueOn_Weekly(t *testing.T) {
	created := time.Date(2026, 5, 19, 8, 0, 0, 0, time.UTC) // Tue
	h := domain.Habit{Frequency: domain.FrequencyWeekly, CreatedAt: created}
	if !isHabitDueOn(h, time.Date(2026, 5, 26, 0, 0, 0, 0, time.UTC)) {
		t.Fatal("weekly must be due same weekday a week later")
	}
	if isHabitDueOn(h, time.Date(2026, 5, 20, 0, 0, 0, 0, time.UTC)) {
		t.Fatal("weekly must NOT be due on a different weekday")
	}
}

func TestIsHabitDueOn_CustomBitmask(t *testing.T) {
	// Custom: Mon (1), Wed (3), Fri (5).
	h := domain.Habit{Frequency: domain.FrequencyCustom, CustomDays: []int{1, 3, 5}}
	// 2026-05-18 is Mon, 5-19 Tue, 5-20 Wed, 5-21 Thu, 5-22 Fri.
	cases := map[string]struct {
		day  time.Time
		want bool
	}{
		"Mon": {time.Date(2026, 5, 18, 0, 0, 0, 0, time.UTC), true},
		"Tue": {time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC), false},
		"Wed": {time.Date(2026, 5, 20, 0, 0, 0, 0, time.UTC), true},
		"Thu": {time.Date(2026, 5, 21, 0, 0, 0, 0, time.UTC), false},
		"Fri": {time.Date(2026, 5, 22, 0, 0, 0, 0, time.UTC), true},
		"Sat": {time.Date(2026, 5, 23, 0, 0, 0, 0, time.UTC), false},
		"Sun": {time.Date(2026, 5, 24, 0, 0, 0, 0, time.UTC), false},
	}
	for name, c := range cases {
		t.Run(name, func(t *testing.T) {
			got := isHabitDueOn(h, c.day)
			if got != c.want {
				t.Fatalf("got %v, want %v", got, c.want)
			}
		})
	}
}

func TestIsHabitDueOn_CustomEmptyFallsBack(t *testing.T) {
	h := domain.Habit{Frequency: domain.FrequencyCustom, CustomDays: nil}
	if !isHabitDueOn(h, time.Date(2026, 5, 19, 0, 0, 0, 0, time.UTC)) {
		t.Fatal("custom with nil customDays must fall back to always due")
	}
}

func TestIsoWeekday(t *testing.T) {
	cases := map[time.Weekday]int{
		time.Monday:    1,
		time.Tuesday:   2,
		time.Wednesday: 3,
		time.Thursday:  4,
		time.Friday:    5,
		time.Saturday:  6,
		time.Sunday:    7,
	}
	// Reference dates 2026-05-18 (Mon) .. 2026-05-24 (Sun).
	base := time.Date(2026, 5, 18, 12, 0, 0, 0, time.UTC)
	for i := 0; i < 7; i++ {
		d := base.AddDate(0, 0, i)
		want := cases[d.Weekday()]
		got := isoWeekday(d)
		if got != want {
			t.Fatalf("%s: isoWeekday got %d, want %d", d.Format("Mon"), got, want)
		}
	}
}
