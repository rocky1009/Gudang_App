package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"src/database"
	"strconv"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type Gudang struct {
	ID     string `json:"gudang_id"`
	Nama   string `json:"gudang_nama"`
	Alamat string `json:"gudang_alamat"`
}

func createGudang(w http.ResponseWriter, r *http.Request) {
	type GudangRequest struct {
		Nama         string `json:"gudang_nama"`
		Alamat       string `json:"gudang_alamat"`
		JumlahLantai int    `json:"jumlah_lantai"`
	}
	var gudang GudangRequest
	if err := json.NewDecoder(r.Body).Decode(&gudang); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate jumlah_lantai
	if gudang.JumlahLantai < 1 {
		respondWithError(w, http.StatusBadRequest, "Jumlah lantai must be at least 1")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Transaction error")
		return
	}

	// Get last gudang_id
	var lastID string
	err = tx.QueryRow("SELECT gudang_id FROM list_gudang ORDER BY gudang_id DESC LIMIT 1").Scan(&lastID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Error fetching last gudang_id")
		return
	}
	nextNum := 1
	if lastID != "" {
		numPart := lastID[3:] // "GU_0002" -> "0002"
		n, _ := strconv.Atoi(numPart)
		nextNum = n + 1
	}
	newID := fmt.Sprintf("GU_%04d", nextNum) // "GU_0003"

	// Insert gudang
	stmt, err := tx.Prepare("INSERT INTO list_gudang (gudang_id, gudang_nama, gudang_alamat) VALUES (?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(newID, gudang.Nama, gudang.Alamat)
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Insert gudang error: "+err.Error())
		return
	}

	// Get last lantai_id
	var lastLantaiID string
	err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai ORDER BY lantai_id DESC LIMIT 1").Scan(&lastLantaiID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Error fetching last lantai_id")
		return
	}
	nextLantaiNum := 1
	if lastLantaiID != "" {
		numPart := lastLantaiID[3:] // "GL_0006" -> "0006"
		n, _ := strconv.Atoi(numPart)
		nextLantaiNum = n + 1
	}

	// Insert floors (lantai)
	lantaiStmt, err := tx.Prepare("INSERT INTO gudang_lantai (lantai_id, gudang_id, lantai_no, lantai_nama) VALUES (?, ?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Prepare lantai statement error")
		return
	}
	defer lantaiStmt.Close()

	for i := 1; i <= gudang.JumlahLantai; i++ {
		lantaiID := fmt.Sprintf("GL_%04d", nextLantaiNum)
		lantaiNama := fmt.Sprintf("%s Lt.%d", gudang.Nama, i)

		_, err = lantaiStmt.Exec(lantaiID, newID, i, lantaiNama)
		if err != nil {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, fmt.Sprintf("Insert lantai %d error: %s", i, err.Error()))
			return
		}
		nextLantaiNum++
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		respondWithError(w, http.StatusInternalServerError, "Commit error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"gudang_id":     newID,
		"gudang_nama":   gudang.Nama,
		"gudang_alamat": gudang.Alamat,
		"jumlah_lantai": gudang.JumlahLantai,
	})
}

func getGudangs(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	rows, err := db.Query("SELECT gudang_id, gudang_nama, gudang_alamat FROM list_gudang")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var gudangs []Gudang
	for rows.Next() {
		var g Gudang
		if err := rows.Scan(&g.ID, &g.Nama, &g.Alamat); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		gudangs = append(gudangs, g)
	}
	respondWithJSON(w, gudangs)
}

func getGudang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	var g Gudang
	err = db.QueryRow("SELECT gudang_id, gudang_nama, gudang_alamat FROM list_gudang WHERE gudang_id = ?", id).Scan(&g.ID, &g.Nama, &g.Alamat)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Gudang not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}

	// Get the count of floors for this gudang
	var jumlahLantai int
	err = db.QueryRow("SELECT COUNT(*) FROM gudang_lantai WHERE gudang_id = ?", id).Scan(&jumlahLantai)
	if err != nil {
		jumlahLantai = 0
	}

	// Return gudang with floor count
	respondWithJSON(w, map[string]interface{}{
		"gudang_id":     g.ID,
		"gudang_nama":   g.Nama,
		"gudang_alamat": g.Alamat,
		"jumlah_lantai": jumlahLantai,
	})
}

func updateGudang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	type GudangRequest struct {
		Nama         string `json:"gudang_nama"`
		Alamat       string `json:"gudang_alamat"`
		JumlahLantai int    `json:"jumlah_lantai"`
	}
	var gudang GudangRequest
	if err := json.NewDecoder(r.Body).Decode(&gudang); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate jumlah_lantai
	if gudang.JumlahLantai < 1 {
		respondWithError(w, http.StatusBadRequest, "Jumlah lantai must be at least 1")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Transaction error")
		return
	}

	// Check if gudang exists first
	var exists int
	err = tx.QueryRow("SELECT COUNT(*) FROM list_gudang WHERE gudang_id = ?", id).Scan(&exists)
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	if exists == 0 {
		tx.Rollback()
		respondWithError(w, http.StatusNotFound, "Gudang not found")
		return
	}

	// Update gudang
	stmt, err := tx.Prepare("UPDATE list_gudang SET gudang_nama = ?, gudang_alamat = ? WHERE gudang_id = ?")
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(gudang.Nama, gudang.Alamat, id)
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	// Get current number of floors
	var currentFloorCount int
	err = tx.QueryRow("SELECT COUNT(*) FROM gudang_lantai WHERE gudang_id = ?", id).Scan(&currentFloorCount)
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Error counting floors")
		return
	}

	// Handle floor changes
	if gudang.JumlahLantai > currentFloorCount {
		// Add new floors
		// Get last lantai_id globally
		var lastLantaiID string
		err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai ORDER BY lantai_id DESC LIMIT 1").Scan(&lastLantaiID)
		if err != nil && err != sql.ErrNoRows {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, "Error fetching last lantai_id")
			return
		}
		nextLantaiNum := 1
		if lastLantaiID != "" {
			numPart := lastLantaiID[3:] // "GL_0006" -> "0006"
			n, _ := strconv.Atoi(numPart)
			nextLantaiNum = n + 1
		}

		// Insert new floors
		lantaiStmt, err := tx.Prepare("INSERT INTO gudang_lantai (lantai_id, gudang_id, lantai_no, lantai_nama) VALUES (?, ?, ?, ?)")
		if err != nil {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, "Prepare lantai statement error")
			return
		}
		defer lantaiStmt.Close()

		for i := currentFloorCount + 1; i <= gudang.JumlahLantai; i++ {
			lantaiID := fmt.Sprintf("GL_%04d", nextLantaiNum)
			lantaiNama := fmt.Sprintf("%s Lt.%d", gudang.Nama, i)

			_, err = lantaiStmt.Exec(lantaiID, id, i, lantaiNama)
			if err != nil {
				tx.Rollback()
				respondWithError(w, http.StatusInternalServerError, fmt.Sprintf("Insert lantai %d error: %s", i, err.Error()))
				return
			}
			nextLantaiNum++
		}
	} else if gudang.JumlahLantai < currentFloorCount {
		// Delete excess floors (from highest to lowest)
		deleteStmt, err := tx.Prepare("DELETE FROM gudang_lantai WHERE gudang_id = ? AND lantai_no > ?")
		if err != nil {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, "Prepare delete statement error")
			return
		}
		defer deleteStmt.Close()

		_, err = deleteStmt.Exec(id, gudang.JumlahLantai)
		if err != nil {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, "Delete excess floors error: "+err.Error())
			return
		}
	}

	// Update lantai names for all floors if gudang name changed
	updateNamesStmt, err := tx.Prepare("UPDATE gudang_lantai SET lantai_nama = ? WHERE gudang_id = ? AND lantai_no = ?")
	if err != nil {
		tx.Rollback()
		respondWithError(w, http.StatusInternalServerError, "Prepare update names statement error")
		return
	}
	defer updateNamesStmt.Close()

	for i := 1; i <= gudang.JumlahLantai; i++ {
		lantaiNama := fmt.Sprintf("%s Lt.%d", gudang.Nama, i)
		_, err = updateNamesStmt.Exec(lantaiNama, id, i)
		if err != nil {
			tx.Rollback()
			respondWithError(w, http.StatusInternalServerError, fmt.Sprintf("Update lantai name %d error: %s", i, err.Error()))
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		respondWithError(w, http.StatusInternalServerError, "Commit error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"gudang_id":     id,
		"gudang_nama":   gudang.Nama,
		"gudang_alamat": gudang.Alamat,
		"jumlah_lantai": gudang.JumlahLantai,
	})
}

func deleteGudang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	stmt, err := db.Prepare("DELETE FROM list_gudang WHERE gudang_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	res, err := stmt.Exec(id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Delete error: "+err.Error())
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		respondWithError(w, http.StatusNotFound, "Gudang not found")
		return
	}

	respondWithJSON(w, map[string]string{
		"gudang_id": id,
		"status":    "Deleted",
	})
}

// Get all gudang lantai records
func getGudangLantaiAll(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `
		SELECT 
			gl.lantai_id,
			gl.gudang_id,
			gl.lantai_no,
			gl.lantai_nama,
			lg.gudang_nama
		FROM gudang_lantai gl
		JOIN list_gudang lg ON gl.gudang_id = lg.gudang_id
		ORDER BY lg.gudang_nama, gl.lantai_no
	`

	rows, err := db.Query(query)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var lantaiList []map[string]interface{}
	for rows.Next() {
		var lantaiID, gudangID, lantaiNama, gudangNama string
		var lantaiNo int
		if err := rows.Scan(&lantaiID, &gudangID, &lantaiNo, &lantaiNama, &gudangNama); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		lantaiList = append(lantaiList, map[string]interface{}{
			"lantai_id":   lantaiID,
			"gudang_id":   gudangID,
			"lantai_no":   lantaiNo,
			"lantai_nama": lantaiNama,
			"gudang_nama": gudangNama,
		})
	}
	respondWithJSON(w, lantaiList)
}

// SetupGudangRoutes sets up all gudang-related routes
func SetupGudangRoutes(router *mux.Router) {
	router.HandleFunc("/creategudang", createGudang).Methods("POST")
	router.HandleFunc("/getgudangs", getGudangs).Methods("GET")
	router.HandleFunc("/getgudang/{id}", getGudang).Methods("GET")
	router.HandleFunc("/getgudanglantai", getGudangLantaiAll).Methods("GET")
	router.HandleFunc("/updategudang/{id}", updateGudang).Methods("PUT")
	router.HandleFunc("/deletegudang/{id}", deleteGudang).Methods("DELETE")
}
