package domain

import "time"

type HabitLog struct {
	ID        string
	UserID    string
	HabitID   string
	Date      time.Time
	Completed bool
	CreatedAt time.Time
}
