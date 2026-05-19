package domain

import "time"

type HabitFrequency string

const (
	FrequencyDaily  HabitFrequency = "daily"
	FrequencyWeekly HabitFrequency = "weekly"
	FrequencyCustom HabitFrequency = "custom"
)

type HabitDifficulty string

const (
	DifficultyEasy   HabitDifficulty = "easy"
	DifficultyMedium HabitDifficulty = "medium"
	DifficultyHard   HabitDifficulty = "hard"
)

type Habit struct {
	ID         string
	UserID     string
	Title      string
	Category   string
	Frequency  HabitFrequency
	Difficulty HabitDifficulty
	// CustomDays lists ISO weekdays (1=Mon … 7=Sun) on which the habit is
	// scheduled. Only meaningful when Frequency == FrequencyCustom.
	CustomDays []int
	CreatedAt  time.Time
	UpdatedAt  time.Time
	DeletedAt  *time.Time
}
