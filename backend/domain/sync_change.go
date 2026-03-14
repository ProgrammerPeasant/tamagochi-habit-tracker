package domain

import "time"

type ChangeEntity string

type ChangeOp string

const (
	ChangeEntityHabit    ChangeEntity = "habit"
	ChangeEntityHabitLog ChangeEntity = "habit_log"
	ChangeEntityStreak   ChangeEntity = "streak"
	ChangeEntityPetState ChangeEntity = "pet_state"
	ChangeEntityStats    ChangeEntity = "user_stats"

	ChangeOpUpsert ChangeOp = "upsert"
	ChangeOpDelete ChangeOp = "delete"
)

type SyncChange struct {
	ID        string
	UserID    string
	DeviceID  string
	Entity    ChangeEntity
	Op        ChangeOp
	EntityID  string
	Payload   map[string]any
	UpdatedAt time.Time
}
