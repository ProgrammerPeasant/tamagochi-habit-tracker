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
