package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"src/database"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
	"golang.org/x/crypto/bcrypt"
)

// User represents a user in the system
type User struct {
	UsersID     string `json:"users_id"`
	UsersNama   string `json:"users_nama"`
	UsersTlp    string `json:"users_tlp"`
	UsersPass   string `json:"users_pass,omitempty"` // Only for input, never output
	UsersLevel  int    `json:"users_level"`
	UsersDaftar string `json:"users_daftar"`
	UsersStatus int    `json:"users_status"`
}

// RegisterRequest represents the registration request payload
type RegisterRequest struct {
	UsersNama string `json:"users_nama"`
	UsersTlp  string `json:"users_tlp"`
	UsersPass string `json:"users_pass"`
}

// ChangePasswordRequest represents the password change request
type ChangePasswordRequest struct {
	UsersID     string `json:"users_id"`
	OldPassword string `json:"old_password"`
	NewPassword string `json:"new_password"`
}

// UserResponse represents standard user response
type UserResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	User    *User  `json:"user,omitempty"`
}

// Helper function to handle JSON responses
func respondWithJSONUser(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Helper function to handle errors
func respondWithErrorUser(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(UserResponse{
		Success: false,
		Message: message,
	})
}

// registerUser handles new user registration
func registerUser(w http.ResponseWriter, r *http.Request) {
	var regReq RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&regReq); err != nil {
		respondWithErrorUser(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate required fields
	if regReq.UsersNama == "" || regReq.UsersTlp == "" || regReq.UsersPass == "" {
		respondWithErrorUser(w, http.StatusBadRequest, "Name, phone, and password are required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Generate new users_id
	var lastUserID string
	err = db.QueryRow("SELECT users_id FROM users ORDER BY users_id DESC LIMIT 1").Scan(&lastUserID)

	var newUserID string
	if err == sql.ErrNoRows {
		newUserID = "US_00001"
	} else if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error generating user ID")
		return
	} else {
		// Extract number and increment
		var num int
		fmt.Sscanf(lastUserID, "US_%d", &num)
		newUserID = fmt.Sprintf("US_%05d", num+1)
	}

	// Hash password using bcrypt with cost factor 10
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(regReq.UsersPass), 10)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error hashing password")
		return
	}

	// Insert new user with level=2 (user) and status=0 (pending approval)
	currentDate := time.Now().Format("2006-01-02")
	insertQuery := `INSERT INTO users (users_id, users_nama, users_tlp, users_pass, users_level, users_daftar, users_status) 
	                VALUES (?, ?, ?, ?, 2, ?, 0)`

	_, err = db.Exec(insertQuery, newUserID, regReq.UsersNama, regReq.UsersTlp, string(hashedPassword), currentDate)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error creating user")
		return
	}

	// Return success response (without password)
	newUser := User{
		UsersID:     newUserID,
		UsersNama:   regReq.UsersNama,
		UsersTlp:    regReq.UsersTlp,
		UsersLevel:  2,
		UsersDaftar: currentDate,
		UsersStatus: 0,
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "Registration successful. Waiting for admin approval",
		User:    &newUser,
	})
}

// createUser handles admin creating a new user (with specified level and status)
func createUser(w http.ResponseWriter, r *http.Request) {
	var userReq struct {
		UsersNama   string `json:"users_nama"`
		UsersTlp    string `json:"users_tlp"`
		UsersPass   string `json:"users_pass"`
		UsersLevel  int    `json:"users_level"`
		UsersDaftar string `json:"users_daftar"`
		UsersStatus int    `json:"users_status"`
	}

	if err := json.NewDecoder(r.Body).Decode(&userReq); err != nil {
		respondWithErrorUser(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if userReq.UsersNama == "" || userReq.UsersTlp == "" || userReq.UsersPass == "" {
		respondWithErrorUser(w, http.StatusBadRequest, "Name, phone, and password are required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Generate new users_id
	var lastUserID string
	err = db.QueryRow("SELECT users_id FROM users ORDER BY users_id DESC LIMIT 1").Scan(&lastUserID)

	var newUserID string
	if err == sql.ErrNoRows {
		newUserID = "US_00001"
	} else if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error generating user ID")
		return
	} else {
		// Extract number and increment
		var num int
		fmt.Sscanf(lastUserID, "US_%d", &num)
		newUserID = fmt.Sprintf("US_%05d", num+1)
	}

	// Hash password using bcrypt with cost factor 10
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(userReq.UsersPass), 10)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error hashing password")
		return
	}

	// Use provided date or current date
	daftar := userReq.UsersDaftar
	if daftar == "" {
		daftar = time.Now().Format("2006-01-02")
	}

	// Insert new user with specified level and status
	insertQuery := `INSERT INTO users (users_id, users_nama, users_tlp, users_pass, users_level, users_daftar, users_status) 
	                VALUES (?, ?, ?, ?, ?, ?, ?)`

	_, err = db.Exec(insertQuery, newUserID, userReq.UsersNama, userReq.UsersTlp, string(hashedPassword),
		userReq.UsersLevel, daftar, userReq.UsersStatus)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error creating user")
		return
	}

	// Return success response (without password)
	newUser := User{
		UsersID:     newUserID,
		UsersNama:   userReq.UsersNama,
		UsersTlp:    userReq.UsersTlp,
		UsersLevel:  userReq.UsersLevel,
		UsersDaftar: daftar,
		UsersStatus: userReq.UsersStatus,
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "User created successfully",
		User:    &newUser,
	})
}

// changePassword handles password change
func changePassword(w http.ResponseWriter, r *http.Request) {
	var changeReq ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&changeReq); err != nil {
		respondWithErrorUser(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate required fields
	if changeReq.UsersID == "" || changeReq.OldPassword == "" || changeReq.NewPassword == "" {
		respondWithErrorUser(w, http.StatusBadRequest, "User ID, old password, and new password are required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get current password hash
	var currentHashedPassword string
	query := `SELECT users_pass FROM users WHERE users_id = ?`
	err = db.QueryRow(query, changeReq.UsersID).Scan(&currentHashedPassword)

	if err == sql.ErrNoRows {
		respondWithErrorUser(w, http.StatusNotFound, "User not found")
		return
	} else if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database query error")
		return
	}

	// Verify old password
	err = bcrypt.CompareHashAndPassword([]byte(currentHashedPassword), []byte(changeReq.OldPassword))
	if err != nil {
		respondWithErrorUser(w, http.StatusBadRequest, "Password lama salah")
		return
	}

	// Hash new password
	newHashedPassword, err := bcrypt.GenerateFromPassword([]byte(changeReq.NewPassword), 10)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error hashing new password")
		return
	}

	// Update password
	updateQuery := `UPDATE users SET users_pass = ? WHERE users_id = ?`
	_, err = db.Exec(updateQuery, string(newHashedPassword), changeReq.UsersID)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error updating password")
		return
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "Password berhasil diubah",
	})
}

// getUsers gets all users (including passwords for testing)
func getUsers(w http.ResponseWriter, r *http.Request) {
	log.Println("🔍 getUsers endpoint called")

	db, err := database.GetDBConnection()
	if err != nil {
		log.Printf("❌ Database connection error: %v", err)
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	log.Println("✅ Database connected, executing query...")

	query := `SELECT users_id, users_nama, users_tlp, users_pass, users_level, users_daftar, users_status 
	          FROM users 
	          ORDER BY users_id`

	rows, err := db.Query(query)
	if err != nil {
		log.Printf("❌ Query error: %v", err)
		respondWithErrorUser(w, http.StatusInternalServerError, "Database query error")
		return
	}
	defer rows.Close()

	log.Println("✅ Query executed, scanning rows...")

	var users []User
	for rows.Next() {
		var user User
		if err := rows.Scan(&user.UsersID, &user.UsersNama, &user.UsersTlp, &user.UsersPass, &user.UsersLevel, &user.UsersDaftar, &user.UsersStatus); err != nil {
			log.Printf("❌ Row scan error: %v", err)
			respondWithErrorUser(w, http.StatusInternalServerError, "Error scanning rows")
			return
		}
		users = append(users, user)
	}

	log.Printf("✅ Successfully retrieved %d users", len(users))
	respondWithJSONUser(w, users)
}

// getUser gets a single user by ID (including password for testing)
func getUser(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	userID := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	var user User
	query := `SELECT users_id, users_nama, users_tlp, users_pass, users_level, users_daftar, users_status 
	          FROM users WHERE users_id = ?`

	err = db.QueryRow(query, userID).Scan(&user.UsersID, &user.UsersNama, &user.UsersTlp, &user.UsersPass, &user.UsersLevel, &user.UsersDaftar, &user.UsersStatus)

	if err == sql.ErrNoRows {
		respondWithErrorUser(w, http.StatusNotFound, "User not found")
		return
	} else if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database query error")
		return
	}

	respondWithJSONUser(w, user)
}

// updateUser updates user information (admin function)
func updateUser(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	userID := params["id"]

	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		respondWithErrorUser(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Update user (not including password change - use changePassword endpoint for that)
	updateQuery := `UPDATE users SET users_nama = ?, users_tlp = ?, users_level = ?, users_status = ? 
	                WHERE users_id = ?`

	result, err := db.Exec(updateQuery, user.UsersNama, user.UsersTlp, user.UsersLevel, user.UsersStatus, userID)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error updating user")
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		respondWithErrorUser(w, http.StatusNotFound, "User not found")
		return
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "User updated successfully",
	})
}

// approveUser approves a pending user (admin function)
func approveUser(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	userID := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Update user status to active (1)
	updateQuery := `UPDATE users SET users_status = 1 WHERE users_id = ?`

	result, err := db.Exec(updateQuery, userID)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error approving user")
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		respondWithErrorUser(w, http.StatusNotFound, "User not found")
		return
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "User approved successfully",
	})
}

// deleteUser deletes a user
func deleteUser(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	userID := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Delete user
	deleteQuery := `DELETE FROM users WHERE users_id = ?`

	result, err := db.Exec(deleteQuery, userID)
	if err != nil {
		respondWithErrorUser(w, http.StatusInternalServerError, "Error deleting user")
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		respondWithErrorUser(w, http.StatusNotFound, "User not found")
		return
	}

	respondWithJSONUser(w, UserResponse{
		Success: true,
		Message: "User deleted successfully",
	})
}

// SetupUserRoutes sets up all user-related routes
func SetupUserRoutes(router *mux.Router) {
	router.HandleFunc("/register", registerUser).Methods("POST")
	router.HandleFunc("/changepassword", changePassword).Methods("POST")
	router.HandleFunc("/users", getUsers).Methods("GET")
	router.HandleFunc("/user/{id}", getUser).Methods("GET")
	router.HandleFunc("/user", createUser).Methods("POST") // Admin creates user
	router.HandleFunc("/user/{id}", updateUser).Methods("PUT")
	router.HandleFunc("/user/{id}/approve", approveUser).Methods("PUT")
	router.HandleFunc("/user/{id}", deleteUser).Methods("DELETE")
}
