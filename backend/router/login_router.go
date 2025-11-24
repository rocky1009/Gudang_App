package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"src/database"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"golang.org/x/crypto/bcrypt"
)

// LoginRequest represents the login request payload
type LoginRequest struct {
	UsersNama string `json:"users_nama"`
	Password  string `json:"users_pass"`
}

// LoginResponse represents the login response
type LoginResponse struct {
	Success bool      `json:"success"`
	Message string    `json:"message"`
	User    *UserData `json:"user,omitempty"`
}

// UserData represents user information (without password)
type UserData struct {
	UsersID     string `json:"users_id"`
	UsersNama   string `json:"users_nama"`
	UsersTlp    string `json:"users_tlp"`
	UsersLevel  int    `json:"users_level"`
	UsersDaftar string `json:"users_daftar"`
	UsersStatus int    `json:"users_status"`
	LevelName   string `json:"level_name"`
	StatusName  string `json:"status_name"`
}

// Helper function to handle JSON responses
func respondWithJSONLogin(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Helper function to handle errors
func respondWithErrorLogin(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(LoginResponse{
		Success: false,
		Message: message,
	})
}

// loginUser handles user login
func loginUser(w http.ResponseWriter, r *http.Request) {
	var loginReq LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&loginReq); err != nil {
		respondWithErrorLogin(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate required fields
	if loginReq.UsersNama == "" || loginReq.Password == "" {
		respondWithErrorLogin(w, http.StatusBadRequest, "Nama dan password harus diisi")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get user from database
	var user UserData
	var hashedPassword string
	query := `SELECT users_id, users_nama, users_tlp, users_pass, users_level, users_daftar, users_status 
	          FROM users WHERE users_nama = ?`

	err = db.QueryRow(query, loginReq.UsersNama).Scan(
		&user.UsersID,
		&user.UsersNama,
		&user.UsersTlp,
		&hashedPassword,
		&user.UsersLevel,
		&user.UsersDaftar,
		&user.UsersStatus,
	)

	if err == sql.ErrNoRows {
		respondWithErrorLogin(w, http.StatusUnauthorized, "Nama tidak terdaftar")
		return
	} else if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database query error")
		return
	}

	// Check if user is active (status must be 1)
	if user.UsersStatus != 1 {
		respondWithErrorLogin(w, http.StatusForbidden, "Akun belum aktif. Silakan hubungi administrator")
		return
	}

	// Verify password using bcrypt
	err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(loginReq.Password))
	if err != nil {
		respondWithErrorLogin(w, http.StatusUnauthorized, "Password salah")
		return
	}

	// Set level and status names
	if user.UsersLevel == 1 {
		user.LevelName = "admin"
	} else {
		user.LevelName = "user"
	}

	if user.UsersStatus == 1 {
		user.StatusName = "active"
	} else {
		user.StatusName = "nonactive"
	}

	// Record login in users_login table
	// Generate new login_id
	var lastLoginID string
	err = db.QueryRow("SELECT login_id FROM users_login ORDER BY login_id DESC LIMIT 1").Scan(&lastLoginID)

	var newLoginID string
	if err == sql.ErrNoRows {
		newLoginID = "UL_000001"
	} else if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Error generating login ID")
		return
	} else {
		// Extract number and increment
		var num int
		fmt.Sscanf(lastLoginID, "UL_%d", &num)
		newLoginID = fmt.Sprintf("UL_%06d", num+1)
	}

	// Insert login record with UTC+7 timezone (WIB)
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		// Fallback to manual UTC+7 offset if timezone loading fails
		loc = time.FixedZone("UTC+7", 7*60*60)
	}
	currentTime := time.Now().In(loc)
	loginDate := currentTime.Format("2006-01-02")
	loginTime := currentTime.Format("15:04:05")

	insertQuery := `INSERT INTO users_login (login_id, users_id, login_date, login_time) 
	                VALUES (?, ?, ?, ?)`
	_, err = db.Exec(insertQuery, newLoginID, user.UsersID, loginDate, loginTime)
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Error recording login")
		return
	}

	// Return success response
	respondWithJSONLogin(w, LoginResponse{
		Success: true,
		Message: "Login successful",
		User:    &user,
	})
}

// getLoginHistory gets all login history
func getLoginHistory(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `SELECT ul.login_id, ul.users_id, u.users_nama, ul.login_date, ul.login_time 
	          FROM users_login ul 
	          JOIN users u ON ul.users_id = u.users_id 
	          ORDER BY ul.login_date DESC, ul.login_time DESC`

	rows, err := db.Query(query)
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database query error")
		return
	}
	defer rows.Close()

	type LoginHistory struct {
		LoginID   string `json:"login_id"`
		UsersID   string `json:"users_id"`
		UsersNama string `json:"users_nama"`
		LoginDate string `json:"login_date"`
		LoginTime string `json:"login_time"`
	}

	var history []LoginHistory
	for rows.Next() {
		var h LoginHistory
		if err := rows.Scan(&h.LoginID, &h.UsersID, &h.UsersNama, &h.LoginDate, &h.LoginTime); err != nil {
			respondWithErrorLogin(w, http.StatusInternalServerError, "Error scanning rows")
			return
		}
		history = append(history, h)
	}

	respondWithJSONLogin(w, history)
}

// getUserLoginHistory gets login history for a specific user
func getUserLoginHistory(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	userID := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `SELECT login_id, users_id, login_date, login_time 
	          FROM users_login 
	          WHERE users_id = ? 
	          ORDER BY login_date DESC, login_time DESC`

	rows, err := db.Query(query, userID)
	if err != nil {
		respondWithErrorLogin(w, http.StatusInternalServerError, "Database query error")
		return
	}
	defer rows.Close()

	type LoginHistory struct {
		LoginID   string `json:"login_id"`
		UsersID   string `json:"users_id"`
		LoginDate string `json:"login_date"`
		LoginTime string `json:"login_time"`
	}

	var history []LoginHistory
	for rows.Next() {
		var h LoginHistory
		if err := rows.Scan(&h.LoginID, &h.UsersID, &h.LoginDate, &h.LoginTime); err != nil {
			respondWithErrorLogin(w, http.StatusInternalServerError, "Error scanning rows")
			return
		}
		history = append(history, h)
	}

	respondWithJSONLogin(w, history)
}

// SetupLoginRoutes sets up all login-related routes
func SetupLoginRoutes(router *mux.Router) {
	router.HandleFunc("/login", loginUser).Methods("POST")
	router.HandleFunc("/loginhistory", getLoginHistory).Methods("GET")
	router.HandleFunc("/loginhistory/{id}", getUserLoginHistory).Methods("GET")
}
