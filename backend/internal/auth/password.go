package auth

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"strings"
)

// HashPassword derives a salted SHA-256 hash for the given password.
// The output format is "<saltHex>:<digestHex>" so that the salt can be
// recovered for verification without an external dependency. For a production
// system bcrypt or argon2id would be used instead — this implementation is
// scoped to keep the module dependency-free for the course project.
func HashPassword(password string) (string, error) {
	if password == "" {
		return "", errors.New("password cannot be empty")
	}
	salt := make([]byte, 16)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	digest := derive(password, salt)
	return hex.EncodeToString(salt) + ":" + hex.EncodeToString(digest), nil
}

// VerifyPassword checks the supplied password against a stored hash produced
// by HashPassword.
func VerifyPassword(password, stored string) bool {
	parts := strings.SplitN(stored, ":", 2)
	if len(parts) != 2 {
		return false
	}
	salt, err := hex.DecodeString(parts[0])
	if err != nil {
		return false
	}
	expected, err := hex.DecodeString(parts[1])
	if err != nil {
		return false
	}
	candidate := derive(password, salt)
	return subtle.ConstantTimeCompare(candidate, expected) == 1
}

func derive(password string, salt []byte) []byte {
	mac := hmac.New(sha256.New, salt)
	mac.Write([]byte(password))
	return mac.Sum(nil)
}
