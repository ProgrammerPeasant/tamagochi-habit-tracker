package main

import (
	"log"
	"net/http"
	"time"

	httpapi "origamit-tamagochi-tracker/backend/api/http"
	"origamit-tamagochi-tracker/backend/services"
)

func main() {
	app := services.NewInMemoryApp()
	api := httpapi.New(app)

	srv := &http.Server{
		Addr:              ":8080",
		Handler:           api,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Println("origamit api running on :8080")
	if err := srv.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
