package repository

import (
	"context"

	"origamit-tamagochi-tracker/backend/domain"
)

type PetStateRepository interface {
	Get(ctx context.Context, userID string) (domain.PetState, error)
	Upsert(ctx context.Context, state domain.PetState) error
}
