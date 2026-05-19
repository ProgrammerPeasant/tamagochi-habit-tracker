package httpapi

import (
	"errors"
	"strings"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
	"origamit-tamagochi-tracker/backend/services"
)

type createHabitRequest struct {
	ID         string `json:"id"`
	Title      string `json:"title"`
	Category   string `json:"category"`
	Frequency  string `json:"frequency"`
	Difficulty string `json:"difficulty"`
	CustomDays []int  `json:"custom_days"`
}

type updateHabitRequest struct {
	Title      string `json:"title"`
	Category   string `json:"category"`
	Frequency  string `json:"frequency"`
	Difficulty string `json:"difficulty"`
	CustomDays []int  `json:"custom_days"`
}

type completeHabitRequest struct {
	CompletedAt string `json:"completed_at"`
	Notes       string `json:"notes"`
}

type authRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type syncRequest struct {
	DeviceID string       `json:"device_id"`
	Cursor   string       `json:"cursor"`
	Changes  []syncChange `json:"changes"`
}

type syncChange struct {
	Entity    string         `json:"entity"`
	Op        string         `json:"op"`
	ID        string         `json:"id"`
	UpdatedAt string         `json:"updated_at"`
	Payload   map[string]any `json:"payload"`
}

func (r createHabitRequest) toInput() (services.CreateHabitInput, error) {
	if strings.TrimSpace(r.Title) == "" {
		return services.CreateHabitInput{}, errors.New("title required")
	}
	if strings.TrimSpace(r.Category) == "" {
		return services.CreateHabitInput{}, errors.New("category required")
	}
	frequency, err := parseFrequency(r.Frequency)
	if err != nil {
		return services.CreateHabitInput{}, err
	}
	difficulty, err := parseDifficulty(r.Difficulty)
	if err != nil {
		return services.CreateHabitInput{}, err
	}
	return services.CreateHabitInput{
		ID:         strings.TrimSpace(r.ID),
		Title:      strings.TrimSpace(r.Title),
		Category:   strings.TrimSpace(r.Category),
		Frequency:  frequency,
		Difficulty: difficulty,
		CustomDays: sanitizeCustomDays(r.CustomDays),
	}, nil
}

func (r updateHabitRequest) toInput() (services.UpdateHabitInput, error) {
	if strings.TrimSpace(r.Title) == "" {
		return services.UpdateHabitInput{}, errors.New("title required")
	}
	if strings.TrimSpace(r.Category) == "" {
		return services.UpdateHabitInput{}, errors.New("category required")
	}
	frequency, err := parseFrequency(r.Frequency)
	if err != nil {
		return services.UpdateHabitInput{}, err
	}
	difficulty, err := parseDifficulty(r.Difficulty)
	if err != nil {
		return services.UpdateHabitInput{}, err
	}
	return services.UpdateHabitInput{
		Title:      strings.TrimSpace(r.Title),
		Category:   strings.TrimSpace(r.Category),
		Frequency:  frequency,
		Difficulty: difficulty,
		CustomDays: sanitizeCustomDays(r.CustomDays),
	}, nil
}

// sanitizeCustomDays drops out-of-range entries and de-duplicates while
// preserving sort order. Returns a non-nil empty slice for empty input so the
// caller can distinguish "no days picked yet" from "field absent".
func sanitizeCustomDays(in []int) []int {
	seen := make(map[int]struct{})
	out := make([]int, 0, len(in))
	for _, d := range in {
		if d < 1 || d > 7 {
			continue
		}
		if _, dup := seen[d]; dup {
			continue
		}
		seen[d] = struct{}{}
		out = append(out, d)
	}
	return out
}

func (c syncChange) toDomain(userID, deviceID string) domain.SyncChange {
	updatedAt := time.Now().UTC()
	if c.UpdatedAt != "" {
		if parsed, err := time.Parse(time.RFC3339, c.UpdatedAt); err == nil {
			updatedAt = parsed
		}
	}

	return domain.SyncChange{
		ID:        c.ID,
		UserID:    userID,
		DeviceID:  deviceID,
		Entity:    domain.ChangeEntity(c.Entity),
		Op:        domain.ChangeOp(c.Op),
		EntityID:  c.ID,
		Payload:   c.Payload,
		UpdatedAt: updatedAt,
	}
}

func parseFrequency(value string) (domain.HabitFrequency, error) {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "daily":
		return domain.FrequencyDaily, nil
	case "weekly":
		return domain.FrequencyWeekly, nil
	case "custom":
		return domain.FrequencyCustom, nil
	default:
		return "", errors.New("invalid frequency")
	}
}

func parseDifficulty(value string) (domain.HabitDifficulty, error) {
	v := strings.ToLower(strings.TrimSpace(value))
	if v == "" {
		return domain.DifficultyMedium, nil
	}
	switch v {
	case "easy":
		return domain.DifficultyEasy, nil
	case "medium":
		return domain.DifficultyMedium, nil
	case "hard":
		return domain.DifficultyHard, nil
	default:
		return "", errors.New("invalid difficulty")
	}
}
