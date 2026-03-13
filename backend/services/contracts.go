package services

import (
	"context"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
)

type HabitService interface {
	CreateHabit(ctx context.Context, userID string, input CreateHabitInput) (domain.Habit, error)
	ListHabits(ctx context.Context, userID string) ([]domain.Habit, error)
	UpdateHabit(ctx context.Context, userID, habitID string, input UpdateHabitInput) (domain.Habit, error)
	DeleteHabit(ctx context.Context, userID, habitID string) (DeleteResult, error)
	CompleteHabit(ctx context.Context, userID, habitID string, completedAt time.Time) (CompletionResult, error)
}

type StreakService interface {
	ListStreaks(ctx context.Context, userID string) ([]domain.Streak, error)
}

type PetService interface {
	GetPetState(ctx context.Context, userID string) (domain.PetState, error)
}

type StatsService interface {
	GetUserStats(ctx context.Context, userID string) (domain.UserStats, error)
}

type SyncService interface {
	PushPull(ctx context.Context, userID, deviceID string, cursor time.Time, changes []domain.SyncChange) (time.Time, []domain.SyncChange, error)
	PullSince(ctx context.Context, userID, deviceID string, cursor time.Time) (time.Time, []domain.SyncChange, error)
}

type App struct {
	Habits  HabitService
	Streaks StreakService
	Pet     PetService
	Stats   StatsService
	Sync    SyncService
}

type CreateHabitInput struct {
	ID        string
	Title     string
	Category  string
	Frequency domain.HabitFrequency
}

type UpdateHabitInput struct {
	Title     string
	Category  string
	Frequency domain.HabitFrequency
}

type DeleteResult struct {
	ID        string
	DeletedAt time.Time
}

type CompletionResult struct {
	HabitID string
	Streak  domain.Streak
	Pet     domain.PetState
	Stats   domain.UserStats
}
