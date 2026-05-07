package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
	"time"
)

type Claims struct {
	Subject   string `json:"sub"`
	Email     string `json:"email,omitempty"`
	IssuedAt  int64  `json:"iat"`
	ExpiresAt int64  `json:"exp"`
}

type Signer struct {
	secret []byte
	ttl    time.Duration
}

func NewSigner(secret string, ttl time.Duration) *Signer {
	if ttl <= 0 {
		ttl = 24 * time.Hour
	}
	return &Signer{secret: []byte(secret), ttl: ttl}
}

func (s *Signer) Sign(userID, email string) (string, error) {
	if userID == "" {
		return "", errors.New("user id required")
	}
	now := time.Now().UTC()
	claims := Claims{
		Subject:   userID,
		Email:     email,
		IssuedAt:  now.Unix(),
		ExpiresAt: now.Add(s.ttl).Unix(),
	}

	header := map[string]string{"alg": "HS256", "typ": "JWT"}
	headerBytes, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	payloadBytes, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	encodedHeader := encode(headerBytes)
	encodedPayload := encode(payloadBytes)
	signingInput := encodedHeader + "." + encodedPayload
	signature := s.sign(signingInput)
	return signingInput + "." + encode(signature), nil
}

func (s *Signer) Verify(token string) (Claims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return Claims{}, errors.New("malformed token")
	}

	signingInput := parts[0] + "." + parts[1]
	expected := s.sign(signingInput)
	provided, err := decode(parts[2])
	if err != nil {
		return Claims{}, errors.New("malformed signature")
	}
	if !hmac.Equal(expected, provided) {
		return Claims{}, errors.New("invalid signature")
	}

	payload, err := decode(parts[1])
	if err != nil {
		return Claims{}, errors.New("malformed payload")
	}

	var claims Claims
	if err := json.Unmarshal(payload, &claims); err != nil {
		return Claims{}, err
	}
	if claims.ExpiresAt > 0 && time.Now().UTC().Unix() > claims.ExpiresAt {
		return Claims{}, errors.New("token expired")
	}
	return claims, nil
}

func (s *Signer) sign(input string) []byte {
	mac := hmac.New(sha256.New, s.secret)
	mac.Write([]byte(input))
	return mac.Sum(nil)
}

func encode(value []byte) string {
	return base64.RawURLEncoding.EncodeToString(value)
}

func decode(value string) ([]byte, error) {
	return base64.RawURLEncoding.DecodeString(value)
}
