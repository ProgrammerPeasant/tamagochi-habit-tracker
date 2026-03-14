package httpapi

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"origamit-tamagochi-tracker/backend/services"
)

func TestUnauthorizedRequest(t *testing.T) {
	api := New(services.NewInMemoryApp())
	req := httptest.NewRequest(http.MethodGet, "/v1/habits", nil)
	rec := httptest.NewRecorder()

	api.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", rec.Code)
	}
}

func TestCreateListAndCompleteHabit(t *testing.T) {
	api := New(services.NewInMemoryApp())
	userID := "user_test"

	createBody := map[string]any{
		"title":     "Read",
		"category":  "Learning",
		"frequency": "daily",
	}
	createResp := doRequest(t, api, http.MethodPost, "/v1/habits", userID, createBody)
	if createResp.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d", createResp.Code)
	}
	var created map[string]any
	if err := json.NewDecoder(createResp.Body).Decode(&created); err != nil {
		t.Fatalf("decode create response: %v", err)
	}
	habitID, ok := created["id"].(string)
	if !ok || habitID == "" {
		t.Fatal("expected habit id in response")
	}

	listResp := doRequest(t, api, http.MethodGet, "/v1/habits", userID, nil)
	if listResp.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", listResp.Code)
	}
	var listPayload map[string]any
	if err := json.NewDecoder(listResp.Body).Decode(&listPayload); err != nil {
		t.Fatalf("decode list response: %v", err)
	}
	items, ok := listPayload["items"].([]any)
	if !ok || len(items) != 1 {
		t.Fatalf("expected 1 habit item, got %#v", listPayload["items"])
	}

	completeBody := map[string]any{
		"completed_at": time.Date(2026, 1, 1, 10, 0, 0, 0, time.UTC).Format(time.RFC3339),
	}
	completeResp := doRequest(
		t,
		api,
		http.MethodPost,
		"/v1/habits/"+habitID+"/complete",
		userID,
		completeBody,
	)
	if completeResp.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", completeResp.Code)
	}
	var completePayload map[string]any
	if err := json.NewDecoder(completeResp.Body).Decode(&completePayload); err != nil {
		t.Fatalf("decode complete response: %v", err)
	}
	if completePayload["habit_id"] != habitID {
		t.Fatalf("expected habit_id %s, got %v", habitID, completePayload["habit_id"])
	}
}

func TestAPINegativeCases(t *testing.T) {
	api := New(services.NewInMemoryApp())
	userID := "user_test"

	resp := doRequest(t, api, http.MethodGet, "/v1/unknown", userID, nil)
	if resp.Code != http.StatusNotFound {
		t.Fatalf("expected 404, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodPost, "/v1/habits/abc", userID, map[string]any{})
	if resp.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected 405, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodPost, "/v1/habits", userID, map[string]any{
		"title":     "",
		"category":  "Health",
		"frequency": "daily",
	})
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for missing title, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodPost, "/v1/habits", userID, map[string]any{
		"title":     "Read",
		"category":  "Learning",
		"frequency": "yearly",
	})
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid frequency, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodPost, "/v1/habits", userID, map[string]any{
		"title":     "Read",
		"category":  "Learning",
		"frequency": "daily",
		"unexpected": "field",
	})
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for unknown field, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodPost, "/v1/habits/missing/complete", userID, map[string]any{
		"completed_at": "not-a-time",
	})
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid completed_at, got %d", resp.Code)
	}

	resp = doRequest(t, api, http.MethodDelete, "/v1/habits/missing", userID, nil)
	if resp.Code != http.StatusNotFound {
		t.Fatalf("expected 404 for deleting missing habit, got %d", resp.Code)
	}
}

func TestSyncNegativeCases(t *testing.T) {
	api := New(services.NewInMemoryApp())
	userID := "user_sync_neg"

	// GET /v1/sync without device_id
	resp := doRequest(t, api, http.MethodGet, "/v1/sync", userID, nil)
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for missing device_id, got %d", resp.Code)
	}

	// GET /v1/sync with invalid cursor
	req := httptest.NewRequest(http.MethodGet, "/v1/sync?device_id=dev1&cursor=bad", nil)
	req.Header.Set("X-User-Id", userID)
	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid cursor, got %d", rec.Code)
	}

	// POST /v1/sync with invalid cursor
	resp = doRequest(t, api, http.MethodPost, "/v1/sync", userID, map[string]any{
		"device_id": "dev1",
		"cursor":    "bad",
		"changes":   []any{},
	})
	if resp.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid cursor on post, got %d", resp.Code)
	}
}

func doRequest(
	t *testing.T,
	api *API,
	method, path, userID string,
	body map[string]any,
) *httptest.ResponseRecorder {
	t.Helper()

	var payload []byte
	if body != nil {
		var err error
		payload, err = json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal body: %v", err)
		}
	}

	req := httptest.NewRequest(method, path, bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-User-Id", userID)

	rec := httptest.NewRecorder()
	api.ServeHTTP(rec, req)
	return rec
}
