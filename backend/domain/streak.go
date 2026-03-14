package domain

import "time"

type Streak struct {
	UserID        string
	HabitID       string
	CurrentStreak int
	BestStreak    int
	LastCompleted *time.Time
	UpdatedAt     time.Time
}
