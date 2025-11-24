package database

import (
	"database/sql"
	"fmt"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// GetDBConnection returns a database connection using environment variables
// Uses DATABASE_URL if set (Railway production)
// Falls back to localhost:3306 for local development
func GetDBConnection() (*sql.DB, error) {
	dbURL := os.Getenv("DATABASE_URL")

	// If DATABASE_URL not set, try Railway MYSQL* vars (no underscore)
	if dbURL == "" {
		user := os.Getenv("MYSQLUSER")
		pass := os.Getenv("MYSQLPASSWORD")
		host := os.Getenv("MYSQLHOST")
		port := os.Getenv("MYSQLPORT")
		name := os.Getenv("MYSQLDATABASE")

		if user != "" && host != "" && name != "" {
			// build DSN from components (Railway provides these)
			dbURL = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&loc=Local", user, pass, host, port, name)
		} else {
			// Fallback for local development
			// Using localhost MySQL - safe to test without affecting Railway!
			dbURL = "root:@tcp(localhost:3306)/gudang_victoria?parseTime=true&loc=Local"
		}
	}

	db, err := sql.Open("mysql", dbURL)
	if err != nil {
		return nil, err
	}

	// Set timeout for ping
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, err
	}

	// Connection pooling params
	db.SetConnMaxLifetime(3 * time.Minute)
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	return db, nil
}
