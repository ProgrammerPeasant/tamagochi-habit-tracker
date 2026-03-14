package repository

import (
	"context"

	"origamit-tamagochi-tracker/backend/domain"
)

type UserStatsRepository interface {
	Get(ctx context.Context, userID string) (domain.UserStats, error)
	Upsert(ctx context.Context, stats domain.UserStats) error
}
