package main

import (
	"log"
	"net/http"
	"os"
	"time"

	httpapi "origamit-tamagochi-tracker/backend/api/http"
	"origamit-tamagochi-tracker/backend/internal/auth"
	"origamit-tamagochi-tracker/backend/services"
)

func main() {
	app := services.NewInMemoryApp()

	secret := os.Getenv("ORIGAMIT_JWT_SECRET")
	if secret == "" {
		secret = "origamit-dev-secret-change-me"
	}
	signer := auth.NewSigner(secret, 24*time.Hour)

	api := httpapi.New(app, signer)

	addr := os.Getenv("ORIGAMIT_LISTEN_ADDR")
	if addr == "" {
		addr = ":8080"
	}

	srv := &http.Server{
		Addr:              addr,
		Handler:           api,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("origamit api running on %s", addr)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
