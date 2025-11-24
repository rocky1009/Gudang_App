package router

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"src/database"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type DiscountBarang struct {
	BarangID       string `json:"barang_id"`
	BarangNama     string `json:"barang_nama"`
	BrandID        string `json:"brand_id"`
	BrandNama      string `json:"brand_nama"`
	HargaAsli      int    `json:"barang_harga_asli"`
	HargaJual      int    `json:"barang_harga_jual"`
	Diskon         string `json:"barang_diskon"`
	DeadlineDiskon string `json:"barang_deadline_diskon"`
	Status         int    `json:"barang_status"`
}

type DiscountRequest struct {
	Diskon         string `json:"barang_diskon"`
	DeadlineDiskon string `json:"barang_deadline_diskon"`
}

// Get all brands for brand selection dropdown
func getBrandsForDiscount(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := "SELECT brand_id, brand_nama FROM brand ORDER BY brand_nama"
	rows, err := db.Query(query)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var brands []map[string]string
	for rows.Next() {
		var brandID, brandName string
		if err := rows.Scan(&brandID, &brandName); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		brands = append(brands, map[string]string{
			"brand_id":   brandID,
			"brand_nama": brandName,
		})
	}

	respondWithJSON(w, map[string]interface{}{
		"brands": brands,
	})
}

// Get barang by brand_nama for barang selection dropdown
func getBarangByBrand(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	brandNama := params["brand_nama"]

	if brandNama == "" {
		respondWithError(w, http.StatusBadRequest, "brand_nama is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			b.brand_id,
			br.brand_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		WHERE br.brand_nama = ?
		ORDER BY b.barang_nama`

	rows, err := db.Query(query, brandNama)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var barangs []DiscountBarang
	for rows.Next() {
		var b DiscountBarang
		var diskon, deadlineDiskon sql.NullString

		if err := rows.Scan(&b.BarangID, &b.BarangNama, &b.BrandID, &b.BrandNama, &b.HargaAsli, &b.HargaJual, &diskon, &deadlineDiskon, &b.Status); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}

		// Handle nullable strings - return "-" if NULL
		if diskon.Valid {
			b.Diskon = diskon.String
		} else {
			b.Diskon = "-"
		}

		if deadlineDiskon.Valid {
			b.DeadlineDiskon = deadlineDiskon.String
		} else {
			b.DeadlineDiskon = "-"
		}

		barangs = append(barangs, b)
	}

	respondWithJSON(w, barangs)
}

// Get specific barang discount information
func getBarangDiscount(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["barang_id"]

	if barangID == "" {
		respondWithError(w, http.StatusBadRequest, "barang_id is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			b.brand_id,
			br.brand_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		WHERE b.barang_id = ?`

	var b DiscountBarang
	var diskon, deadlineDiskon sql.NullString

	err = db.QueryRow(query, barangID).Scan(&b.BarangID, &b.BarangNama, &b.BrandID, &b.BrandNama, &b.HargaAsli, &b.HargaJual, &diskon, &deadlineDiskon, &b.Status)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}

	// Handle nullable strings - return "-" if NULL
	if diskon.Valid {
		b.Diskon = diskon.String
	} else {
		b.Diskon = "-"
	}

	if deadlineDiskon.Valid {
		b.DeadlineDiskon = deadlineDiskon.String
	} else {
		b.DeadlineDiskon = "-"
	}

	respondWithJSON(w, b)
}

// Update barang discount
func updateBarangDiscount(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["barang_id"]

	if barangID == "" {
		respondWithError(w, http.StatusBadRequest, "barang_id is required")
		return
	}

	var discount DiscountRequest
	if err := json.NewDecoder(r.Body).Decode(&discount); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if barang exists
	var existingBarangID string
	err = db.QueryRow("SELECT barang_id FROM barang WHERE barang_id = ?", barangID).Scan(&existingBarangID)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+barangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	// Handle NULL values for diskon and deadline_diskon
	var diskonValue interface{}
	var deadlineDiskonValue interface{}

	if discount.Diskon == "" || discount.Diskon == "-" {
		diskonValue = nil
	} else {
		diskonValue = discount.Diskon
	}

	if discount.DeadlineDiskon == "" || discount.DeadlineDiskon == "-" {
		deadlineDiskonValue = nil
	} else {
		deadlineDiskonValue = discount.DeadlineDiskon
	}

	stmt, err := db.Prepare("UPDATE barang SET barang_diskon = ?, barang_deadline_diskon = ? WHERE barang_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(diskonValue, deadlineDiskonValue, barangID)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	// Get updated barang information to return
	var updatedBarang DiscountBarang
	var diskon, deadlineDiskon sql.NullString

	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			b.brand_id,
			br.brand_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		WHERE b.barang_id = ?`

	err = db.QueryRow(query, barangID).Scan(&updatedBarang.BarangID, &updatedBarang.BarangNama, &updatedBarang.BrandID, &updatedBarang.BrandNama, &updatedBarang.HargaAsli, &updatedBarang.HargaJual, &diskon, &deadlineDiskon, &updatedBarang.Status)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error fetching updated barang: "+err.Error())
		return
	}

	// Handle nullable strings - return "-" if NULL
	if diskon.Valid {
		updatedBarang.Diskon = diskon.String
	} else {
		updatedBarang.Diskon = "-"
	}

	if deadlineDiskon.Valid {
		updatedBarang.DeadlineDiskon = deadlineDiskon.String
	} else {
		updatedBarang.DeadlineDiskon = "-"
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":              updatedBarang.BarangID,
		"barang_nama":            updatedBarang.BarangNama,
		"brand_nama":             updatedBarang.BrandNama,
		"barang_harga_asli":      updatedBarang.HargaAsli,
		"barang_harga_jual":      updatedBarang.HargaJual,
		"barang_diskon":          updatedBarang.Diskon,
		"barang_deadline_diskon": updatedBarang.DeadlineDiskon,
		"barang_status":          updatedBarang.Status,
		"status":                 "Updated",
		"message":                "Discount updated successfully",
	})
}

// Delete barang discount (set to NULL)
func deleteBarangDiscount(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["barang_id"]

	if barangID == "" {
		respondWithError(w, http.StatusBadRequest, "barang_id is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if barang exists
	var existingBarangID string
	err = db.QueryRow("SELECT barang_id FROM barang WHERE barang_id = ?", barangID).Scan(&existingBarangID)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+barangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	// Set both discount fields to NULL
	stmt, err := db.Prepare("UPDATE barang SET barang_diskon = NULL, barang_deadline_diskon = NULL WHERE barang_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(barangID)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Delete error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":              barangID,
		"barang_diskon":          "-",
		"barang_deadline_diskon": "-",
		"status":                 "Deleted",
		"message":                "Discount deleted successfully",
	})
}

// Get all barangs with current discount information (for overview page)
func getAllBarangDiscounts(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get query parameters for filtering
	brandFilter := r.URL.Query().Get("brand")              // Filter by brand_nama
	statusFilter := r.URL.Query().Get("status")            // Filter by barang_status
	hasDiscountFilter := r.URL.Query().Get("has_discount") // Filter by having discount (true/false)

	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			b.brand_id,
			br.brand_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id`

	var args []interface{}
	var conditions []string

	// Add filter conditions
	if brandFilter != "" && brandFilter != "Semua Brand" {
		conditions = append(conditions, "br.brand_nama = ?")
		args = append(args, brandFilter)
	}

	if statusFilter != "" {
		conditions = append(conditions, "b.barang_status = ?")
		args = append(args, statusFilter)
	}

	if hasDiscountFilter != "" {
		if hasDiscountFilter == "true" {
			conditions = append(conditions, "b.barang_diskon IS NOT NULL")
		} else if hasDiscountFilter == "false" {
			conditions = append(conditions, "b.barang_diskon IS NULL")
		}
	}

	// Add WHERE clause if there are conditions
	if len(conditions) > 0 {
		query += " WHERE " + conditions[0]
		for i := 1; i < len(conditions); i++ {
			query += " AND " + conditions[i]
		}
	}

	query += " ORDER BY br.brand_nama, b.barang_nama"

	rows, err := db.Query(query, args...)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var barangs []DiscountBarang
	for rows.Next() {
		var b DiscountBarang
		var diskon, deadlineDiskon sql.NullString

		if err := rows.Scan(&b.BarangID, &b.BarangNama, &b.BrandID, &b.BrandNama, &b.HargaAsli, &b.HargaJual, &diskon, &deadlineDiskon, &b.Status); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}

		// Handle nullable strings - return "-" if NULL
		if diskon.Valid {
			b.Diskon = diskon.String
		} else {
			b.Diskon = "-"
		}

		if deadlineDiskon.Valid {
			b.DeadlineDiskon = deadlineDiskon.String
		} else {
			b.DeadlineDiskon = "-"
		}

		barangs = append(barangs, b)
	}

	respondWithJSON(w, barangs)
}

// SetupDiscountRoutes sets up all discount-related routes
func SetupDiscountRoutes(router *mux.Router) {
	// Get brands for dropdown
	router.HandleFunc("/getbrandsfordiscount", getBrandsForDiscount).Methods("GET")

	// Get barang by brand for dropdown
	router.HandleFunc("/getbarangbybrand/{brand_nama}", getBarangByBrand).Methods("GET")

	// Get specific barang discount info
	router.HandleFunc("/getbarangdiscount/{barang_id}", getBarangDiscount).Methods("GET")

	// Update barang discount
	router.HandleFunc("/updatebarangdiscount/{barang_id}", updateBarangDiscount).Methods("PUT")

	// Delete barang discount
	router.HandleFunc("/deletebarangdiscount/{barang_id}", deleteBarangDiscount).Methods("DELETE")

	// Get all barangs with discount info (overview)
	router.HandleFunc("/getallbarangdiscounts", getAllBarangDiscounts).Methods("GET")
}
