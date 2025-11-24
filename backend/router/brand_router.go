package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"src/database" // Add this import

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type Brand struct {
	ID     string `json:"brand_id"`
	Nama   string `json:"brand_nama"`
	Kontak string `json:"brand_kontak"`
	Tlp    string `json:"brand_tlp"`
}

// Helper function to handle JSON responses
func respondWithJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Helper function to handle errors
func respondWithError(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

func createBrand(w http.ResponseWriter, r *http.Request) {
	type BrandRequest struct {
		Nama   string `json:"brand_nama"`
		Kontak string `json:"brand_kontak"`
		Tlp    string `json:"brand_tlp"`
	}
	var brand BrandRequest
	if err := json.NewDecoder(r.Body).Decode(&brand); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	db, err := database.GetDBConnection() // Changed this line
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get last brand_id
	var lastID string
	err = db.QueryRow("SELECT brand_id FROM brand ORDER BY brand_id DESC LIMIT 1").Scan(&lastID)
	if err != nil && err != sql.ErrNoRows {
		respondWithError(w, http.StatusInternalServerError, "Error fetching last brand_id")
		return
	}
	nextNum := 1
	if lastID != "" {
		numPart := lastID[3:] // "BR_0002" -> "0002"
		n, _ := strconv.Atoi(numPart)
		nextNum = n + 1
	}
	newID := fmt.Sprintf("BR_%04d", nextNum) // "BR_0003"

	stmt, err := db.Prepare("INSERT INTO brand (brand_id, brand_nama, brand_kontak, brand_tlp) VALUES (?, ?, ?, ?)")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(newID, brand.Nama, brand.Kontak, brand.Tlp)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Insert error: "+err.Error())
		return
	}

	respondWithJSON(w, Brand{
		ID:     newID,
		Nama:   brand.Nama,
		Kontak: brand.Kontak,
		Tlp:    brand.Tlp,
	})
}

func getBrands(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection() // Changed this line
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	rows, err := db.Query("SELECT brand_id, brand_nama, brand_kontak, brand_tlp FROM brand")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var brands []Brand
	for rows.Next() {
		var b Brand
		if err := rows.Scan(&b.ID, &b.Nama, &b.Kontak, &b.Tlp); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		brands = append(brands, b)
	}
	respondWithJSON(w, brands)
}

func getBrand(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection() // Changed this line
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	var b Brand
	err = db.QueryRow("SELECT brand_id, brand_nama, brand_kontak, brand_tlp FROM brand WHERE brand_id = ?", id).Scan(&b.ID, &b.Nama, &b.Kontak, &b.Tlp)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Brand not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	respondWithJSON(w, b)
}

func updateBrand(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	type BrandRequest struct {
		Nama   string `json:"brand_nama"`
		Kontak string `json:"brand_kontak"`
		Tlp    string `json:"brand_tlp"`
	}
	var brand BrandRequest
	if err := json.NewDecoder(r.Body).Decode(&brand); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	db, err := database.GetDBConnection() // Changed this line
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	stmt, err := db.Prepare("UPDATE brand SET brand_nama = ?, brand_kontak = ?, brand_tlp = ? WHERE brand_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	res, err := stmt.Exec(brand.Nama, brand.Kontak, brand.Tlp, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		respondWithError(w, http.StatusNotFound, "Brand not found")
		return
	}

	respondWithJSON(w, Brand{
		ID:     id,
		Nama:   brand.Nama,
		Kontak: brand.Kontak,
		Tlp:    brand.Tlp,
	})
}

func deleteBrand(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection() // Changed this line
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	stmt, err := db.Prepare("DELETE FROM brand WHERE brand_id = ?")
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
		respondWithError(w, http.StatusNotFound, "Brand not found")
		return
	}

	respondWithJSON(w, map[string]string{
		"brand_id": id,
		"status":   "Deleted",
	})
}

// SetupBrandRoutes sets up all brand-related routes
func SetupBrandRoutes(router *mux.Router) {
	router.HandleFunc("/createbrand", createBrand).Methods("POST")
	router.HandleFunc("/getbrands", getBrands).Methods("GET")
	router.HandleFunc("/getbrand/{id}", getBrand).Methods("GET")
	router.HandleFunc("/updatebrand/{id}", updateBrand).Methods("PUT")
	router.HandleFunc("/deletebrand/{id}", deleteBrand).Methods("DELETE")
}
