package domain

import "time"

type UserStats struct {
	UserID         string
	TotalCompleted int
	CompletionRate float64
	ActiveDays     int
	UpdatedAt      time.Time
}
