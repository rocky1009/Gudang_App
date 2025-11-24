package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"src/database"
	"src/router"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

// CORS middleware for multiplatform access
func enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func homePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "API is running - Gudang Victoria Backend")
}

func handleRoutes() {
	r := mux.NewRouter()
	r.HandleFunc("/", homePage).Methods("GET")

	// Authentication routes
	router.SetupLoginRoutes(r)
	router.SetupUserRoutes(r)

	// Business routes
	router.SetupBrandRoutes(r)
	router.SetupGudangRoutes(r)
	router.SetupBarangRoutes(r)
	router.SetupCustomerRoutes(r)
	router.SetupBarangLogsRoutes(r)
	router.SetupOrdersInRoutes(r)
	router.SetupOrdersOutRoutes(r)
	router.SetupDiscountRoutes(r)
	router.SetupSalesRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, enableCORS(r)))
}

func main() {
	// Test database connection on startup
	log.Println("🔌 Attempting to connect to database...")

	db, err := database.GetDBConnection()
	if err != nil {
		log.Fatalf("❌ Error connecting to database: %v", err)
	}
	defer db.Close()

	log.Println("✅ Successfully connected to database")

	handleRoutes()
}
