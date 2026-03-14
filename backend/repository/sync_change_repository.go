package repository

import (
	"context"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

type SyncChangeRepository interface {
	Append(ctx context.Context, change domain.SyncChange) error
	ListSince(ctx context.Context, userID, deviceID string, since time.Time) ([]domain.SyncChange, time.Time, error)
}
