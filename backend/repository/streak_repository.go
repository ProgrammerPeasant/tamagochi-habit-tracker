package repository

import (
	"context"

	"origamit-tamagochi-tracker/backend/domain"
)

type StreakRepository interface {
	GetByHabit(ctx context.Context, userID, habitID string) (domain.Streak, error)
	Upsert(ctx context.Context, streak domain.Streak) error
	List(ctx context.Context, userID string) ([]domain.Streak, error)
}
