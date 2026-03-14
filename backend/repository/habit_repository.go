package repository

import (
	"context"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

type HabitRepository interface {
	List(ctx context.Context, userID string) ([]domain.Habit, error)
	Get(ctx context.Context, userID, habitID string) (domain.Habit, error)
	Upsert(ctx context.Context, habit domain.Habit) error
	MarkDeleted(ctx context.Context, userID, habitID string, deletedAt time.Time) error
}

type HabitLogRepository interface {
	ListByHabit(ctx context.Context, userID, habitID string, from, to time.Time) ([]domain.HabitLog, error)
	Append(ctx context.Context, log domain.HabitLog) error
}
