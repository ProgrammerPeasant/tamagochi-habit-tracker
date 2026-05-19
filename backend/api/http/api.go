package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"origamit-tamagochi-tracker/backend/domain"
	"origamit-tamagochi-tracker/backend/internal/auth"
	"origamit-tamagochi-tracker/backend/services"
)

type API struct {
	services *services.App
	signer   *auth.Signer
}

func New(services *services.App, signer *auth.Signer) *API {
	return &API{services: services, signer: signer}
}

func (a *API) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	setCors(w)
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	if !strings.HasPrefix(r.URL.Path, "/v1/") {
		writeError(w, http.StatusNotFound, "route not found")
		return
	}

	path := strings.TrimPrefix(r.URL.Path, "/v1/")
	path = strings.Trim(path, "/")
	parts := strings.Split(path, "/")

	if len(parts) == 2 && parts[0] == "auth" {
		a.handleAuth(w, r, parts[1])
		return
	}

	userID, err := a.userIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err.Error())
		return
	}

	switch {
	case len(parts) == 1 && parts[0] == "habits":
		a.handleHabits(w, r, userID)
	case len(parts) == 2 && parts[0] == "habits":
		a.handleHabitByID(w, r, userID, parts[1])
	case len(parts) == 3 && parts[0] == "habits" && parts[2] == "complete":
		a.handleHabitComplete(w, r, userID, parts[1])
	case len(parts) == 1 && parts[0] == "pet":
		a.handlePet(w, r, userID)
	case len(parts) == 1 && parts[0] == "stats":
		a.handleStats(w, r, userID)
	case len(parts) == 1 && parts[0] == "streaks":
		a.handleStreaks(w, r, userID)
	case len(parts) == 1 && parts[0] == "sync":
		a.handleSync(w, r, userID)
	default:
		writeError(w, http.StatusNotFound, "route not found")
	}
}

func (a *API) handleAuth(w http.ResponseWriter, r *http.Request, action string) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req authRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	switch action {
	case "register":
		user, err := a.services.Auth.Register(r.Context(), req.Email, req.Password)
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		token, err := a.signer.Sign(user.ID, user.Email)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusCreated, map[string]any{
			"token":   token,
			"user_id": user.ID,
			"email":   user.Email,
		})
	case "login":
		user, err := a.services.Auth.Authenticate(r.Context(), req.Email, req.Password)
		if err != nil {
			writeError(w, http.StatusUnauthorized, err.Error())
			return
		}
		token, err := a.signer.Sign(user.ID, user.Email)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"token":   token,
			"user_id": user.ID,
			"email":   user.Email,
		})
	default:
		writeError(w, http.StatusNotFound, "route not found")
	}
}

func (a *API) handleHabits(w http.ResponseWriter, r *http.Request, userID string) {
	switch r.Method {
	case http.MethodGet:
		items, err := a.services.Habits.ListHabits(r.Context(), userID)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"items": mapHabits(items)})
	case http.MethodPost:
		var req createHabitRequest
		if err := decodeJSON(r, &req); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		input, err := req.toInput()
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		created, err := a.services.Habits.CreateHabit(r.Context(), userID, input)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}
		writeJSON(w, http.StatusCreated, mapHabit(created))
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func (a *API) handleHabitByID(w http.ResponseWriter, r *http.Request, userID, habitID string) {
	switch r.Method {
	case http.MethodPatch:
		var req updateHabitRequest
		if err := decodeJSON(r, &req); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		input, err := req.toInput()
		if err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		updated, err := a.services.Habits.UpdateHabit(r.Context(), userID, habitID, input)
		if err != nil {
			writeError(w, http.StatusNotFound, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, mapHabit(updated))
	case http.MethodDelete:
		result, err := a.services.Habits.DeleteHabit(r.Context(), userID, habitID)
		if err != nil {
			writeError(w, http.StatusNotFound, err.Error())
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"id":         result.ID,
			"deleted":    true,
			"deleted_at": formatTime(result.DeletedAt),
		})
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func (a *API) handleHabitComplete(w http.ResponseWriter, r *http.Request, userID, habitID string) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	var req completeHabitRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	completedAt := time.Now().UTC()
	if req.CompletedAt != "" {
		parsed, err := time.Parse(time.RFC3339, req.CompletedAt)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid completed_at")
			return
		}
		completedAt = parsed
	}

	result, err := a.services.Habits.CompleteHabit(r.Context(), userID, habitID, completedAt, strings.TrimSpace(req.Notes))
	if err != nil {
		writeError(w, http.StatusNotFound, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"habit_id":  result.HabitID,
		"streak":    mapStreak(result.Streak),
		"pet_state": mapPetState(result.Pet),
		"stats":     mapStats(result.Stats),
	})
}

func (a *API) handlePet(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	state, err := a.services.Pet.GetPetState(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, mapPetState(state))
}

func (a *API) handleStats(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	stats, err := a.services.Stats.GetUserStats(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	writeJSON(w, http.StatusOK, mapStats(stats))
}

func (a *API) handleStreaks(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}

	items, err := a.services.Streaks.ListStreaks(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	mapped := make([]map[string]any, 0, len(items))
	for _, streak := range items {
		mapped = append(mapped, mapStreak(streak))
	}

	writeJSON(w, http.StatusOK, map[string]any{"items": mapped})
}

func (a *API) handleSync(w http.ResponseWriter, r *http.Request, userID string) {
	switch r.Method {
	case http.MethodPost:
		var req syncRequest
		if err := decodeJSON(r, &req); err != nil {
			writeError(w, http.StatusBadRequest, err.Error())
			return
		}

		cursor, err := parseCursor(req.Cursor)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid cursor")
			return
		}

		changes := make([]domain.SyncChange, 0, len(req.Changes))
		for _, change := range req.Changes {
			changes = append(changes, change.toDomain(userID, req.DeviceID))
		}

		newCursor, outbound, err := a.services.Sync.PushPull(r.Context(), userID, req.DeviceID, cursor, changes)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"cursor":  formatTime(newCursor),
			"changes": mapSyncChanges(outbound),
		})
	case http.MethodGet:
		deviceID := r.URL.Query().Get("device_id")
		cursorValue := r.URL.Query().Get("cursor")
		if deviceID == "" {
			writeError(w, http.StatusBadRequest, "device_id required")
			return
		}
		cursor, err := parseCursor(cursorValue)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid cursor")
			return
		}

		newCursor, outbound, err := a.services.Sync.PullSince(r.Context(), userID, deviceID, cursor)
		if err != nil {
			writeError(w, http.StatusInternalServerError, err.Error())
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"cursor":  formatTime(newCursor),
			"changes": mapSyncChanges(outbound),
		})
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func (a *API) userIDFromRequest(r *http.Request) (string, error) {
	authHeader := strings.TrimSpace(r.Header.Get("Authorization"))
	if authHeader != "" && a.signer != nil {
		const bearer = "Bearer "
		if strings.HasPrefix(authHeader, bearer) {
			token := strings.TrimSpace(strings.TrimPrefix(authHeader, bearer))
			claims, err := a.signer.Verify(token)
			if err != nil {
				return "", errors.New("invalid token")
			}
			if claims.Subject == "" {
				return "", errors.New("invalid token subject")
			}
			return claims.Subject, nil
		}
	}

	// Fallback for legacy clients during migration. Will be removed once all
	// clients ship with the JWT-based flow.
	if userID := strings.TrimSpace(r.Header.Get("X-User-Id")); userID != "" {
		return userID, nil
	}

	return "", errors.New("missing Authorization header")
}

func decodeJSON(r *http.Request, target any) error {
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	return decoder.Decode(target)
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]any{"error": message})
}

func mapHabits(items []domain.Habit) []map[string]any {
	mapped := make([]map[string]any, 0, len(items))
	for _, habit := range items {
		mapped = append(mapped, mapHabit(habit))
	}
	return mapped
}

func mapHabit(habit domain.Habit) map[string]any {
	difficulty := habit.Difficulty
	if difficulty == "" {
		difficulty = domain.DifficultyMedium
	}
	payload := map[string]any{
		"id":         habit.ID,
		"title":      habit.Title,
		"category":   habit.Category,
		"frequency":  habit.Frequency,
		"difficulty": difficulty,
		"created_at": formatTime(habit.CreatedAt),
		"updated_at": formatTime(habit.UpdatedAt),
	}
	if len(habit.CustomDays) > 0 {
		payload["custom_days"] = habit.CustomDays
	}
	if habit.DeletedAt != nil {
		payload["deleted_at"] = formatTime(*habit.DeletedAt)
	}
	return payload
}

func mapStreak(streak domain.Streak) map[string]any {
	payload := map[string]any{
		"habit_id":       streak.HabitID,
		"current_streak": streak.CurrentStreak,
		"best_streak":    streak.BestStreak,
		"updated_at":     formatTime(streak.UpdatedAt),
	}
	if streak.LastCompleted != nil {
		payload["last_completed"] = formatTime(*streak.LastCompleted)
	}
	return payload
}

func mapPetState(state domain.PetState) map[string]any {
	return map[string]any{
		"level":                state.Level,
		"structure_complexity": state.StructureComplexity,
		"damage":               state.Damage,
		"energy":               state.Energy,
		"mood":                 state.Mood,
		"updated_at":           formatTime(state.UpdatedAt),
	}
}

func mapStats(stats domain.UserStats) map[string]any {
	return map[string]any{
		"total_completed": stats.TotalCompleted,
		"completion_rate": stats.CompletionRate,
		"active_days":     stats.ActiveDays,
		"updated_at":      formatTime(stats.UpdatedAt),
	}
}

func mapSyncChanges(items []domain.SyncChange) []map[string]any {
	mapped := make([]map[string]any, 0, len(items))
	for _, change := range items {
		mapped = append(mapped, map[string]any{
			"entity":     change.Entity,
			"op":         change.Op,
			"id":         change.EntityID,
			"updated_at": formatTime(change.UpdatedAt),
			"payload":    change.Payload,
		})
	}
	return mapped
}

func formatTime(value time.Time) string {
	if value.IsZero() {
		return ""
	}
	return value.UTC().Format(time.RFC3339)
}

func parseCursor(value string) (time.Time, error) {
	if value == "" {
		return time.Time{}, nil
	}
	return time.Parse(time.RFC3339, value)
}

func setCors(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, X-User-Id, Authorization")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
}
