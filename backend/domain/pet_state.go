package domain

import "time"

type PetState struct {
	UserID              string
	Level               int
	StructureComplexity int
	Damage              int
	Energy              int
	Mood                int
	UpdatedAt           time.Time
}
