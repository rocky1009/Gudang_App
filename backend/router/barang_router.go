package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"src/database"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type Barang struct {
	ID             string      `json:"barang_id"`
	Nama           string      `json:"barang_nama"`
	HargaAsli      int         `json:"barang_harga_asli"`
	HargaJual      int         `json:"barang_harga_jual"`
	Diskon         string      `json:"barang_diskon"`
	DeadlineDiskon string      `json:"barang_deadline_diskon"`
	Status         int         `json:"barang_status"`
	BrandNama      string      `json:"brand_nama"`
	StockTotal     int         `json:"stock_total"`
	StockGudang    []StockInfo `json:"stock_gudang"`
}

type StockInfo struct {
	GudangNama  string `json:"gudang_nama"`
	StockBarang int    `json:"stock_barang"`
}

type BarangRequest struct {
	Nama           string            `json:"nama"`                  // Flutter field name compatibility
	BarangNama     string            `json:"barang_nama,omitempty"` // Alternative field name for compatibility
	BrandNama      string            `json:"brand_nama"`            // Changed from BrandID to BrandNama
	HargaAsli      int               `json:"barang_harga_asli"`
	HargaJual      int               `json:"barang_harga_jual"`
	Diskon         string            `json:"barang_diskon,omitempty"`
	DeadlineDiskon string            `json:"barang_deadline_diskon,omitempty"`
	Status         int               `json:"barang_status"`
	StockGudang    []StockUpdateInfo `json:"stock_gudang,omitempty"` // New field for stock updates
}

type StockUpdateInfo struct {
	GudangNama  string `json:"gudang_nama"`
	StockBarang int    `json:"stock_barang"`
}

type StockLantaiUpdateInfo struct {
	LantaiID    string `json:"lantai_id"`
	StockBarang int    `json:"stock_barang"`
}

type StockRequest struct {
	BarangID    string                  `json:"barang_id"`
	BarangNama  string                  `json:"barang_nama,omitempty"`  // For display purposes
	StockGudang []StockUpdateInfo       `json:"stock_gudang,omitempty"` // Legacy: warehouse level
	StockLantai []StockLantaiUpdateInfo `json:"stock_lantai,omitempty"` // New: floor level
}

// InventoryItemSummary represents inventory summary for a single item
type InventoryItemSummary struct {
	BarangID          string      `json:"barang_id"`
	BarangNama        string      `json:"barang_nama"`
	BrandNama         string      `json:"brand_nama"`
	BarangHargaAsli   int         `json:"barang_harga_asli"`
	BarangHargaJual   int         `json:"barang_harga_jual"`
	BarangStatus      int         `json:"barang_status"`
	TotalStock        int         `json:"total_stock"`
	StockGudang       []StockInfo `json:"stock_gudang"`
	LastSaleDate      string      `json:"last_sale_date"`
	DaysSinceLastSale int         `json:"days_since_last_sale"`
	TotalSalesCount   int         `json:"total_sales_count"`
	StockStatus       string      `json:"stock_status"` // "available", "low_stock", "out_of_stock"
}

// InventorySummaryResponse represents the complete inventory summary report
type InventorySummaryResponse struct {
	TotalItems            int                    `json:"total_items"`
	AvailableItems        int                    `json:"available_items"`
	LowStockItems         int                    `json:"low_stock_items"`
	OutOfStockItems       int                    `json:"out_of_stock_items"`
	InactiveItems         int                    `json:"inactive_items"`
	Items                 []InventoryItemSummary `json:"items"`
	FilterApplied         string                 `json:"filter_applied,omitempty"`
	LowStockThreshold     int                    `json:"low_stock_threshold"`
	InactiveDaysThreshold int                    `json:"inactive_days_threshold"`
}

// Helper method to get the barang name from either field
func (br *BarangRequest) GetNama() string {
	if br.Nama != "" {
		return br.Nama
	}
	return br.BarangNama
}

// Helper function to convert NULL values to "-"
func nullStringToString(ns sql.NullString) string {
	if ns.Valid {
		return ns.String
	}
	return "-"
}

// Helper function to handle diskon values for database operations
func processNullableStringValue(value string) interface{} {
	if value == "" || value == "-" {
		return nil
	}
	return value
}

// Helper function to handle deadline diskon date values
func processDeadlineDiskonValue(deadline string) interface{} {
	if deadline == "" || deadline == "-" {
		return nil
	}
	return deadline
}

// Helper function to get brand_id from brand_nama
func getBrandIDFromName(db *sql.DB, brandNama string) (string, error) {
	var brandID string
	err := db.QueryRow("SELECT brand_id FROM brand WHERE brand_nama = ?", brandNama).Scan(&brandID)
	if err == sql.ErrNoRows {
		return "", fmt.Errorf("invalid brand_nama: brand '%s' does not exist", brandNama)
	} else if err != nil {
		return "", fmt.Errorf("error looking up brand: %v", err)
	}
	return brandID, nil
}

// Helper function to update stock information
func updateStockInfo(db *sql.DB, barangID string, stockUpdates []StockUpdateInfo) error {
	for i, stockUpdate := range stockUpdates {
		// Get gudang_id from gudang_nama
		var gudangID string
		err := db.QueryRow("SELECT gudang_id FROM list_gudang WHERE gudang_nama = ?", stockUpdate.GudangNama).Scan(&gudangID)
		if err == sql.ErrNoRows {
			return fmt.Errorf("invalid gudang_nama at index %d: '%s' does not exist", i, stockUpdate.GudangNama)
		} else if err != nil {
			return fmt.Errorf("error looking up gudang at index %d: %v", i, err)
		}

		// Get the first lantai_id for this gudang (default to lantai 1)
		var lantaiID string
		err = db.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&lantaiID)
		if err == sql.ErrNoRows {
			return fmt.Errorf("no floors found for gudang '%s' at index %d", stockUpdate.GudangNama, i)
		} else if err != nil {
			return fmt.Errorf("error looking up lantai for gudang '%s' at index %d: %v", stockUpdate.GudangNama, i, err)
		}

		// Check if stock record exists
		var existingStockID string
		err = db.QueryRow("SELECT stock_id FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", barangID, lantaiID).Scan(&existingStockID)

		if err == sql.ErrNoRows {
			// Create new stock record if it doesn't exist
			// Get last stock_id
			var lastStockID string
			err = db.QueryRow("SELECT stock_id FROM stock_gudang ORDER BY stock_id DESC LIMIT 1").Scan(&lastStockID)
			if err != nil && err != sql.ErrNoRows {
				return fmt.Errorf("error fetching last stock_id for index %d: %v", i, err)
			}

			nextNum := 1
			if lastStockID != "" {
				numPart := lastStockID[3:] // "ST_000010" -> "000010"
				n, _ := strconv.Atoi(numPart)
				nextNum = n + 1
			}
			newStockID := fmt.Sprintf("ST_%06d", nextNum) // "ST_000011"

			_, err = db.Exec("INSERT INTO stock_gudang (stock_id, barang_id, lantai_id, stock_barang) VALUES (?, ?, ?, ?)",
				newStockID, barangID, lantaiID, stockUpdate.StockBarang)
			if err != nil {
				return fmt.Errorf("error creating stock record for gudang '%s' at index %d: %v", stockUpdate.GudangNama, i, err)
			}
		} else if err != nil {
			return fmt.Errorf("error checking existing stock for gudang '%s' at index %d: %v", stockUpdate.GudangNama, i, err)
		} else {
			// Update existing stock record
			_, err = db.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?",
				stockUpdate.StockBarang, barangID, lantaiID)
			if err != nil {
				return fmt.Errorf("error updating stock record for gudang '%s' at index %d: %v", stockUpdate.GudangNama, i, err)
			}
		}
	}
	return nil
}

// Helper function to update stock information per floor
func updateStockInfoByLantai(db *sql.DB, barangID string, stockUpdates []StockLantaiUpdateInfo) error {
	for i, stockUpdate := range stockUpdates {
		// Verify lantai exists
		var existsCheck int
		err := db.QueryRow("SELECT COUNT(*) FROM gudang_lantai WHERE lantai_id = ?", stockUpdate.LantaiID).Scan(&existsCheck)
		if err != nil {
			return fmt.Errorf("error checking lantai at index %d: %v", i, err)
		}
		if existsCheck == 0 {
			return fmt.Errorf("invalid lantai_id at index %d: '%s' does not exist", i, stockUpdate.LantaiID)
		}

		// Check if stock record exists
		var existingStockID string
		err = db.QueryRow("SELECT stock_id FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", barangID, stockUpdate.LantaiID).Scan(&existingStockID)

		if err == sql.ErrNoRows {
			// Create new stock record if it doesn't exist
			// Get last stock_id
			var lastStockID string
			err = db.QueryRow("SELECT stock_id FROM stock_gudang ORDER BY stock_id DESC LIMIT 1").Scan(&lastStockID)
			if err != nil && err != sql.ErrNoRows {
				return fmt.Errorf("error fetching last stock_id for index %d: %v", i, err)
			}

			nextNum := 1
			if lastStockID != "" {
				numPart := lastStockID[3:] // "ST_000010" -> "000010"
				n, _ := strconv.Atoi(numPart)
				nextNum = n + 1
			}
			newStockID := fmt.Sprintf("ST_%06d", nextNum) // "ST_000011"

			_, err = db.Exec("INSERT INTO stock_gudang (stock_id, barang_id, lantai_id, stock_barang) VALUES (?, ?, ?, ?)",
				newStockID, barangID, stockUpdate.LantaiID, stockUpdate.StockBarang)
			if err != nil {
				return fmt.Errorf("error creating stock record for lantai '%s' at index %d: %v", stockUpdate.LantaiID, i, err)
			}
		} else if err != nil {
			return fmt.Errorf("error checking existing stock for lantai '%s' at index %d: %v", stockUpdate.LantaiID, i, err)
		} else {
			// Update existing stock record
			_, err = db.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?",
				stockUpdate.StockBarang, barangID, stockUpdate.LantaiID)
			if err != nil {
				return fmt.Errorf("error updating stock record for lantai '%s' at index %d: %v", stockUpdate.LantaiID, i, err)
			}
		}
	}
	return nil
}

func createBarang(w http.ResponseWriter, r *http.Request) {
	var barang BarangRequest
	if err := json.NewDecoder(r.Body).Decode(&barang); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if barang.BrandNama == "" {
		respondWithError(w, http.StatusBadRequest, "brand_nama is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get brand_id from brand_nama
	brandID, err := getBrandIDFromName(db, barang.BrandNama)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Get last barang_id
	var lastID string
	err = db.QueryRow("SELECT barang_id FROM barang ORDER BY barang_id DESC LIMIT 1").Scan(&lastID)
	if err != nil && err != sql.ErrNoRows {
		respondWithError(w, http.StatusInternalServerError, "Error fetching last barang_id")
		return
	}
	nextNum := 1
	if lastID != "" {
		numPart := lastID[3:] // "BA_00002" -> "00002"
		n, _ := strconv.Atoi(numPart)
		nextNum = n + 1
	}
	newID := fmt.Sprintf("BA_%05d", nextNum) // "BA_00003"

	// Handle NULL values for diskon and deadline_diskon
	diskonValue := processNullableStringValue(barang.Diskon)
	deadlineDiskonValue := processDeadlineDiskonValue(barang.DeadlineDiskon)

	stmt, err := db.Prepare("INSERT INTO barang (barang_id, barang_nama, brand_id, barang_harga_asli, barang_harga_jual, barang_diskon, barang_deadline_diskon, barang_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(newID, barang.GetNama(), brandID, barang.HargaAsli, barang.HargaJual, diskonValue, deadlineDiskonValue, barang.Status)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Insert error: "+err.Error())
		return
	}

	// Return the created barang with the new ID for the next page
	respondWithJSON(w, map[string]interface{}{
		"barang_id":              newID,
		"barang_nama":            barang.GetNama(),
		"brand_id":               brandID,
		"brand_nama":             barang.BrandNama,
		"barang_harga_asli":      barang.HargaAsli,
		"barang_harga_jual":      barang.HargaJual,
		"barang_diskon":          barang.Diskon,
		"barang_deadline_diskon": barang.DeadlineDiskon,
		"barang_status":          barang.Status,
		"status":                 "Created",
		"message":                "Barang created successfully. Please proceed to add stock information.",
	})
}

func getBarangs(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get query parameters for search and filter
	searchName := r.URL.Query().Get("search")
	filterBrand := r.URL.Query().Get("brand")

	// Build dynamic query based on parameters
	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status,
			br.brand_nama,
			lg.gudang_nama,
			COALESCE(SUM(sg.stock_barang), 0) as stock_barang
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN stock_gudang sg ON b.barang_id = sg.barang_id
		LEFT JOIN gudang_lantai gl ON sg.lantai_id = gl.lantai_id
		LEFT JOIN list_gudang lg ON gl.gudang_id = lg.gudang_id`

	var args []interface{}
	var conditions []string

	// Add search condition if search parameter is provided
	if searchName != "" {
		conditions = append(conditions, "b.barang_nama LIKE ?")
		args = append(args, "%"+searchName+"%")
	}

	// Add brand filter condition if brand parameter is provided
	if filterBrand != "" && filterBrand != "Semua Brand" {
		conditions = append(conditions, "br.brand_nama = ?")
		args = append(args, filterBrand)
	}

	// Add WHERE clause if there are conditions
	if len(conditions) > 0 {
		query += " WHERE " + conditions[0]
		for i := 1; i < len(conditions); i++ {
			query += " AND " + conditions[i]
		}
	}

	query += " GROUP BY b.barang_id, b.barang_nama, b.barang_harga_asli, b.barang_harga_jual, b.barang_diskon, b.barang_deadline_diskon, b.barang_status, br.brand_nama, lg.gudang_nama ORDER BY b.barang_id, lg.gudang_nama"

	rows, err := db.Query(query, args...)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	barangMap := make(map[string]*Barang)

	for rows.Next() {
		var barangID, nama, brandNama string
		var hargaAsli, hargaJual, status, stockBarang int
		var diskon, deadlineDiskon sql.NullString
		var gudangNama sql.NullString

		if err := rows.Scan(&barangID, &nama, &hargaAsli, &hargaJual, &diskon, &deadlineDiskon, &status, &brandNama, &gudangNama, &stockBarang); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}

		// Check if barang already exists in map
		if _, exists := barangMap[barangID]; !exists {
			barangMap[barangID] = &Barang{
				ID:             barangID,
				Nama:           nama,
				HargaAsli:      hargaAsli,
				HargaJual:      hargaJual,
				Diskon:         nullStringToString(diskon),
				DeadlineDiskon: nullStringToString(deadlineDiskon),
				Status:         status,
				BrandNama:      brandNama,
				StockTotal:     0,
				StockGudang:    []StockInfo{},
			}
		}

		// Add stock info if gudang exists
		if gudangNama.Valid && gudangNama.String != "" {
			stockInfo := StockInfo{
				GudangNama:  gudangNama.String,
				StockBarang: stockBarang,
			}
			barangMap[barangID].StockGudang = append(barangMap[barangID].StockGudang, stockInfo)
			barangMap[barangID].StockTotal += stockBarang
		}
	}

	// Convert map to slice
	var barangs []Barang
	for _, barang := range barangMap {
		barangs = append(barangs, *barang)
	}

	// Sort by barang_id to ensure consistent ordering
	sort.Slice(barangs, func(i, j int) bool {
		return barangs[i].ID < barangs[j].ID
	})

	respondWithJSON(w, barangs)
}

func getWarehousesForStock(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := "SELECT gudang_id, gudang_nama FROM list_gudang ORDER BY gudang_nama"
	rows, err := db.Query(query)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var warehouses []map[string]string
	for rows.Next() {
		var gudangID, gudangNama string
		if err := rows.Scan(&gudangID, &gudangNama); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		warehouses = append(warehouses, map[string]string{
			"gudang_id":   gudangID,
			"gudang_nama": gudangNama,
		})
	}

	respondWithJSON(w, map[string]interface{}{
		"warehouses": warehouses,
	})
}

func getBarangForStock(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["id"]

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
			b.barang_harga_asli,
			b.barang_harga_jual,
			br.brand_nama
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		WHERE b.barang_id = ?
	`

	var barangInfo struct {
		ID        string `json:"barang_id"`
		Nama      string `json:"barang_nama"`
		HargaAsli int    `json:"barang_harga_asli"`
		HargaJual int    `json:"barang_harga_jual"`
		BrandNama string `json:"brand_nama"`
	}

	err = db.QueryRow(query, barangID).Scan(
		&barangInfo.ID,
		&barangInfo.Nama,
		&barangInfo.HargaAsli,
		&barangInfo.HargaJual,
		&barangInfo.BrandNama,
	)

	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+barangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}

	respondWithJSON(w, barangInfo)
}

func getCurrentStockInfo(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if barang exists and get its name
	var existingBarangID, barangNama string
	err = db.QueryRow("SELECT barang_id, barang_nama FROM barang WHERE barang_id = ?", barangID).Scan(&existingBarangID, &barangNama)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+barangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	// Get current stock information for all floors in all warehouses
	currentStockQuery := `
		SELECT 
			lg.gudang_id,
			lg.gudang_nama,
			gl.lantai_id,
			gl.lantai_no,
			gl.lantai_nama,
			COALESCE(sg.stock_barang, 0) as current_stock
		FROM list_gudang lg
		INNER JOIN gudang_lantai gl ON lg.gudang_id = gl.gudang_id
		LEFT JOIN stock_gudang sg ON gl.lantai_id = sg.lantai_id AND sg.barang_id = ?
		ORDER BY lg.gudang_id ASC, gl.lantai_no`

	currentStockRows, err := db.Query(currentStockQuery, barangID)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error fetching current stock: "+err.Error())
		return
	}
	defer currentStockRows.Close()

	var currentStocks []map[string]interface{}
	for currentStockRows.Next() {
		var gudangID, gudangNama, lantaiID, lantaiNama string
		var lantaiNo, currentStock int
		if err := currentStockRows.Scan(&gudangID, &gudangNama, &lantaiID, &lantaiNo, &lantaiNama, &currentStock); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Error scanning current stock: "+err.Error())
			return
		}
		currentStocks = append(currentStocks, map[string]interface{}{
			"gudang_id":    gudangID,
			"gudang_nama":  gudangNama,
			"lantai_id":    lantaiID,
			"lantai_no":    lantaiNo,
			"lantai_nama":  lantaiNama,
			"stock_barang": currentStock,
		})
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":      barangID,
		"barang_nama":    barangNama,
		"current_stocks": currentStocks,
	})
}

func createBarangStock(w http.ResponseWriter, r *http.Request) {
	var stockReq StockRequest
	if err := json.NewDecoder(r.Body).Decode(&stockReq); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if stockReq.BarangID == "" {
		respondWithError(w, http.StatusBadRequest, "barang_id is required")
		return
	}

	if len(stockReq.StockGudang) == 0 {
		respondWithError(w, http.StatusBadRequest, "stock_gudang is required and cannot be empty")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if barang exists and get its name for user-friendly response
	var existingBarangID, barangNama string
	err = db.QueryRow("SELECT barang_id, barang_nama FROM barang WHERE barang_id = ?", stockReq.BarangID).Scan(&existingBarangID, &barangNama)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+stockReq.BarangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	// Process stock information for multiple warehouses
	err = updateStockInfo(db, stockReq.BarangID, stockReq.StockGudang)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, "Stock creation error: "+err.Error())
		return
	}

	// Return success response with created stock information
	var createdStocks []map[string]interface{}
	for _, stock := range stockReq.StockGudang {
		createdStocks = append(createdStocks, map[string]interface{}{
			"gudang_nama":  stock.GudangNama,
			"stock_barang": stock.StockBarang,
		})
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":      stockReq.BarangID,
		"barang_nama":    barangNama,
		"created_stocks": createdStocks,
		"status":         "Stock Created Successfully",
		"message":        fmt.Sprintf("Stock information added for %s in %d warehouses", barangNama, len(stockReq.StockGudang)),
	})
}

func getBarang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

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
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_diskon,
			b.barang_deadline_diskon,
			b.barang_status,
			br.brand_nama,
			lg.gudang_nama,
			COALESCE(SUM(sg.stock_barang), 0) as stock_barang
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN stock_gudang sg ON b.barang_id = sg.barang_id
		LEFT JOIN gudang_lantai gl ON sg.lantai_id = gl.lantai_id
		LEFT JOIN list_gudang lg ON gl.gudang_id = lg.gudang_id
		WHERE b.barang_id = ?
		GROUP BY b.barang_id, b.barang_nama, b.barang_harga_asli, b.barang_harga_jual, b.barang_diskon, b.barang_deadline_diskon, b.barang_status, br.brand_nama, lg.gudang_nama
		ORDER BY lg.gudang_nama
	`

	rows, err := db.Query(query, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var b *Barang

	for rows.Next() {
		var barangID, nama, brandNama string
		var hargaAsli, hargaJual, status, stockBarang int
		var diskon, deadlineDiskon sql.NullString
		var gudangNama sql.NullString

		if err := rows.Scan(&barangID, &nama, &hargaAsli, &hargaJual, &diskon, &deadlineDiskon, &status, &brandNama, &gudangNama, &stockBarang); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}

		// Initialize barang if first row
		if b == nil {
			b = &Barang{
				ID:             barangID,
				Nama:           nama,
				HargaAsli:      hargaAsli,
				HargaJual:      hargaJual,
				Diskon:         nullStringToString(diskon),
				DeadlineDiskon: nullStringToString(deadlineDiskon),
				Status:         status,
				BrandNama:      brandNama,
				StockTotal:     0,
				StockGudang:    []StockInfo{},
			}
		}

		// Add stock info if gudang exists
		if gudangNama.Valid && gudangNama.String != "" {
			stockInfo := StockInfo{
				GudangNama:  gudangNama.String,
				StockBarang: stockBarang,
			}
			b.StockGudang = append(b.StockGudang, stockInfo)
			b.StockTotal += stockBarang
		}
	}

	if b == nil {
		respondWithError(w, http.StatusNotFound, "Barang not found")
		return
	}

	respondWithJSON(w, *b)
}

func getBrandsForFilter(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := "SELECT DISTINCT brand_nama FROM brand ORDER BY brand_nama"
	rows, err := db.Query(query)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var brands []string
	// Add "Semua Brand" as the first option
	brands = append(brands, "Semua Brand")

	for rows.Next() {
		var brandName string
		if err := rows.Scan(&brandName); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		brands = append(brands, brandName)
	}

	respondWithJSON(w, map[string]interface{}{
		"brands": brands,
	})
}

func updateBarang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	var barang BarangRequest
	if err := json.NewDecoder(r.Body).Decode(&barang); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if barang.BrandNama == "" {
		respondWithError(w, http.StatusBadRequest, "brand_nama is required")
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
	err = db.QueryRow("SELECT barang_id FROM barang WHERE barang_id = ?", id).Scan(&existingBarangID)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+id+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	// Get brand_id from brand_nama
	brandID, err := getBrandIDFromName(db, barang.BrandNama)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Handle NULL values for diskon and deadline_diskon
	diskonValue := processNullableStringValue(barang.Diskon)
	deadlineDiskonValue := processDeadlineDiskonValue(barang.DeadlineDiskon)

	stmt, err := db.Prepare("UPDATE barang SET barang_nama = ?, brand_id = ?, barang_harga_asli = ?, barang_harga_jual = ?, barang_diskon = ?, barang_deadline_diskon = ?, barang_status = ? WHERE barang_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(barang.GetNama(), brandID, barang.HargaAsli, barang.HargaJual, diskonValue, deadlineDiskonValue, barang.Status, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":              id,
		"barang_nama":            barang.GetNama(),
		"brand_id":               brandID,
		"brand_nama":             barang.BrandNama,
		"barang_harga_asli":      barang.HargaAsli,
		"barang_harga_jual":      barang.HargaJual,
		"barang_diskon":          barang.Diskon,
		"barang_deadline_diskon": barang.DeadlineDiskon,
		"barang_status":          barang.Status,
		"status":                 "Updated",
		"message":                "Barang information updated successfully",
	})
}

func updateBarangStock(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	barangID := params["id"]

	var stockReq StockRequest
	if err := json.NewDecoder(r.Body).Decode(&stockReq); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Use barang_id from URL parameter
	stockReq.BarangID = barangID

	// Validate required fields
	if stockReq.BarangID == "" {
		respondWithError(w, http.StatusBadRequest, "barang_id is required")
		return
	}

	// Check if we have floor-level stock (new format) or warehouse-level stock (legacy)
	useFloorLevel := len(stockReq.StockLantai) > 0

	if !useFloorLevel && len(stockReq.StockGudang) == 0 {
		respondWithError(w, http.StatusBadRequest, "stock_lantai or stock_gudang is required and cannot be empty")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if barang exists and get its name for user-friendly response
	var existingBarangID, barangNama string
	err = db.QueryRow("SELECT barang_id, barang_nama FROM barang WHERE barang_id = ?", stockReq.BarangID).Scan(&existingBarangID, &barangNama)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang with ID "+stockReq.BarangID+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking barang existence: "+err.Error())
		return
	}

	if useFloorLevel {
		// Process floor-level stock updates
		err = updateStockInfoByLantai(db, stockReq.BarangID, stockReq.StockLantai)
		if err != nil {
			respondWithError(w, http.StatusBadRequest, "Stock update error: "+err.Error())
			return
		}

		respondWithJSON(w, map[string]interface{}{
			"barang_id":   stockReq.BarangID,
			"barang_nama": barangNama,
			"status":      "Stock Updated Successfully",
			"message":     fmt.Sprintf("Stock information updated for %s in %d floors", barangNama, len(stockReq.StockLantai)),
		})
		return
	}

	// Legacy: Process warehouse-level stock updates
	currentStockQuery := `
		SELECT 
			lg.gudang_nama,
			COALESCE(SUM(sg.stock_barang), 0) as current_stock
		FROM list_gudang lg
		LEFT JOIN gudang_lantai gl ON lg.gudang_id = gl.gudang_id
		LEFT JOIN stock_gudang sg ON gl.lantai_id = sg.lantai_id AND sg.barang_id = ?
		WHERE lg.gudang_nama IN (?` + strings.Repeat(",?", len(stockReq.StockGudang)-1) + `)
		GROUP BY lg.gudang_nama
		ORDER BY lg.gudang_nama`

	var args []interface{}
	args = append(args, stockReq.BarangID)
	for _, stock := range stockReq.StockGudang {
		args = append(args, stock.GudangNama)
	}

	currentStockRows, err := db.Query(currentStockQuery, args...)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error fetching current stock: "+err.Error())
		return
	}
	defer currentStockRows.Close()

	var previousStocks []map[string]interface{}
	for currentStockRows.Next() {
		var gudangNama string
		var currentStock int
		if err := currentStockRows.Scan(&gudangNama, &currentStock); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Error scanning current stock: "+err.Error())
			return
		}
		previousStocks = append(previousStocks, map[string]interface{}{
			"gudang_nama":    gudangNama,
			"previous_stock": currentStock,
		})
	}

	// Process stock information for multiple warehouses
	err = updateStockInfo(db, stockReq.BarangID, stockReq.StockGudang)
	if err != nil {
		respondWithError(w, http.StatusBadRequest, "Stock update error: "+err.Error())
		return
	}

	// Combine previous and updated stock information
	var stockComparisons []map[string]interface{}
	for _, stock := range stockReq.StockGudang {
		comparison := map[string]interface{}{
			"gudang_nama":    stock.GudangNama,
			"previous_stock": 0,
			"new_stock":      stock.StockBarang,
		}

		// Find matching previous stock
		for _, prevStock := range previousStocks {
			if prevStock["gudang_nama"] == stock.GudangNama {
				comparison["previous_stock"] = prevStock["previous_stock"]
				break
			}
		}

		stockComparisons = append(stockComparisons, comparison)
	}

	respondWithJSON(w, map[string]interface{}{
		"barang_id":         stockReq.BarangID,
		"barang_nama":       barangNama,
		"stock_comparisons": stockComparisons,
		"status":            "Stock Updated Successfully",
		"message":           fmt.Sprintf("Stock information updated for %s in %d warehouses", barangNama, len(stockReq.StockGudang)),
	})
}

func deleteBarang(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First delete related stock_gudang records
	_, err = db.Exec("DELETE FROM stock_gudang WHERE barang_id = ?", id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error deleting related stock records: "+err.Error())
		return
	}

	// Then delete the barang
	stmt, err := db.Prepare("DELETE FROM barang WHERE barang_id = ?")
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
		respondWithError(w, http.StatusNotFound, "Barang not found")
		return
	}

	respondWithJSON(w, map[string]string{
		"barang_id": id,
		"status":    "Deleted",
	})
}

// getInventorySummary retrieves comprehensive inventory summary report
// Query params:
// - filter: "all" (default), "available", "low_stock", "out_of_stock", "inactive"
// - brand: filter by brand name (optional)
// - low_stock_threshold: number to consider as low stock (default: 10)
// - inactive_days: days since last sale to consider inactive (default: 90)
func getInventorySummary(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get query parameters
	filter := r.URL.Query().Get("filter")
	brandFilter := r.URL.Query().Get("brand")
	lowStockThresholdStr := r.URL.Query().Get("low_stock_threshold")
	inactiveDaysStr := r.URL.Query().Get("inactive_days")

	// Set defaults
	if filter == "" {
		filter = "all"
	}

	lowStockThreshold := 10
	if lowStockThresholdStr != "" {
		if val, err := strconv.Atoi(lowStockThresholdStr); err == nil && val > 0 {
			lowStockThreshold = val
		}
	}

	inactiveDays := 90
	if inactiveDaysStr != "" {
		if val, err := strconv.Atoi(inactiveDaysStr); err == nil && val > 0 {
			inactiveDays = val
		}
	}

	// Build main query to get all barang with stock and sales info
	query := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			br.brand_nama,
			b.barang_harga_asli,
			b.barang_harga_jual,
			b.barang_status,
			COALESCE(SUM(sg.stock_barang), 0) as total_stock,
			MAX(s.sales_date) as last_sale_date,
			COUNT(DISTINCT si.sales_id) as total_sales_count
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN stock_gudang sg ON b.barang_id = sg.barang_id
		LEFT JOIN gudang_lantai gl ON sg.lantai_id = gl.lantai_id
		LEFT JOIN list_gudang lg ON gl.gudang_id = lg.gudang_id
		LEFT JOIN sale_items si ON b.barang_id = si.barang_id
		LEFT JOIN sales s ON si.sales_id = s.sales_id AND s.sales_status = 1
	`

	var args []interface{}
	var conditions []string

	// Add brand filter if specified
	if brandFilter != "" && brandFilter != "Semua Brand" {
		conditions = append(conditions, "br.brand_nama = ?")
		args = append(args, brandFilter)
	}

	// Add WHERE clause if there are conditions
	if len(conditions) > 0 {
		query += " WHERE " + strings.Join(conditions, " AND ")
	}

	query += " GROUP BY b.barang_id, b.barang_nama, br.brand_nama, b.barang_harga_asli, b.barang_harga_jual, b.barang_status ORDER BY b.barang_nama"

	rows, err := db.Query(query, args...)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var allItems []InventoryItemSummary
	availableCount := 0
	lowStockCount := 0
	outOfStockCount := 0
	inactiveCount := 0

	for rows.Next() {
		var item InventoryItemSummary
		var lastSaleDate sql.NullString

		err := rows.Scan(
			&item.BarangID,
			&item.BarangNama,
			&item.BrandNama,
			&item.BarangHargaAsli,
			&item.BarangHargaJual,
			&item.BarangStatus,
			&item.TotalStock,
			&lastSaleDate,
			&item.TotalSalesCount,
		)
		if err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}

		// Process last sale date and calculate days since last sale
		if lastSaleDate.Valid && lastSaleDate.String != "" {
			item.LastSaleDate = lastSaleDate.String
			// Calculate days since last sale
			lastSaleTime, err := time.Parse("2006-01-02", lastSaleDate.String)
			if err == nil {
				daysSince := int(time.Since(lastSaleTime).Hours() / 24)
				item.DaysSinceLastSale = daysSince
			} else {
				item.DaysSinceLastSale = -1
			}
		} else {
			item.LastSaleDate = "Never"
			item.DaysSinceLastSale = -1 // -1 means never sold
		}

		// Determine stock status
		if item.TotalStock == 0 {
			item.StockStatus = "out_of_stock"
			outOfStockCount++
		} else if item.TotalStock <= lowStockThreshold {
			item.StockStatus = "low_stock"
			lowStockCount++
		} else {
			item.StockStatus = "available"
			availableCount++
		}

		// Check if item is inactive (no sales in X days or never sold)
		if item.DaysSinceLastSale == -1 || item.DaysSinceLastSale >= inactiveDays {
			inactiveCount++
		}

		// Get detailed stock per warehouse (aggregated from all floors)
		stockQuery := `
			SELECT lg.gudang_nama, COALESCE(SUM(sg.stock_barang), 0) as stock_barang
			FROM list_gudang lg
			LEFT JOIN gudang_lantai gl ON lg.gudang_id = gl.gudang_id
			LEFT JOIN stock_gudang sg ON gl.lantai_id = sg.lantai_id AND sg.barang_id = ?
			GROUP BY lg.gudang_nama
			ORDER BY lg.gudang_nama
		`
		stockRows, err := db.Query(stockQuery, item.BarangID)
		if err != nil {
			respondWithError(w, http.StatusInternalServerError, "Stock query error: "+err.Error())
			return
		}

		item.StockGudang = []StockInfo{}
		for stockRows.Next() {
			var stockInfo StockInfo
			if err := stockRows.Scan(&stockInfo.GudangNama, &stockInfo.StockBarang); err != nil {
				stockRows.Close()
				respondWithError(w, http.StatusInternalServerError, "Stock scan error: "+err.Error())
				return
			}
			item.StockGudang = append(item.StockGudang, stockInfo)
		}
		stockRows.Close()

		allItems = append(allItems, item)
	}

	// Filter items based on filter parameter
	var filteredItems []InventoryItemSummary
	for _, item := range allItems {
		include := false

		switch filter {
		case "all":
			include = true
		case "available":
			include = item.StockStatus == "available"
		case "low_stock":
			include = item.StockStatus == "low_stock"
		case "out_of_stock":
			include = item.StockStatus == "out_of_stock"
		case "inactive":
			include = item.DaysSinceLastSale == -1 || item.DaysSinceLastSale >= inactiveDays
		default:
			include = true
		}

		if include {
			filteredItems = append(filteredItems, item)
		}
	}

	// Handle empty results
	if filteredItems == nil {
		filteredItems = []InventoryItemSummary{}
	}

	// Build response
	response := InventorySummaryResponse{
		TotalItems:            len(allItems),
		AvailableItems:        availableCount,
		LowStockItems:         lowStockCount,
		OutOfStockItems:       outOfStockCount,
		InactiveItems:         inactiveCount,
		Items:                 filteredItems,
		FilterApplied:         filter,
		LowStockThreshold:     lowStockThreshold,
		InactiveDaysThreshold: inactiveDays,
	}

	respondWithJSON(w, response)
}

/*
Two-Step Barang Creation Workflow:

Step 1: Create Barang (Page 1)
- POST /createbarang
- Input: barang_nama, brand_nama, harga_asli, harga_jual, promo, diskon, status
- Output: barang_id, barang_nama, and other details for confirmation

Step 2: Add Stock Information (Page 2)
- GET /getbarangforstock/{barang_id} - Get barang details to show user
- GET /getwarehouses - Get list of available warehouses
- POST /createbarangstock - Add stock for multiple warehouses
- Input: barang_id (from Step 1), stock_gudang array with gudang_nama and stock_barang
- Output: Confirmation with barang_nama and created stock details

Separated Update Operations:

Update Barang Information:
- PUT /updatebarang/{barang_id} - Update only barang table information
- Input: barang_nama, brand_nama, harga_asli, harga_jual, promo, diskon, status
- Output: Updated barang information

Update Stock Information:
- GET /getcurrentstock/{barang_id} - Get current stock amounts for all warehouses
- PUT /updatebarangstock/{barang_id} - Update only stock information
- Input: stock_gudang array with gudang_nama and stock_barang
- Output: Updated stock information with previous vs new stock comparison

This workflow ensures:
- User sees barang_nama instead of barang_id for better UX
- barang_id is automatically passed from Step 1 to Step 2
- Multiple warehouse stocks can be added/updated in one request
- Separate endpoints for updating barang vs stock information
- Proper validation and error handling at each step
*/

// SetupBarangRoutes sets up all barang-related routes
func SetupBarangRoutes(router *mux.Router) {
	router.HandleFunc("/createbarang", createBarang).Methods("POST")
	router.HandleFunc("/getbarangs", getBarangs).Methods("GET")
	router.HandleFunc("/getbarang/{id}", getBarang).Methods("GET")
	router.HandleFunc("/updatebarang/{id}", updateBarang).Methods("PUT")
	router.HandleFunc("/updatebarangstock/{id}", updateBarangStock).Methods("PUT")
	router.HandleFunc("/deletebarang/{id}", deleteBarang).Methods("DELETE")
	router.HandleFunc("/getbrands", getBrandsForFilter).Methods("GET")
	router.HandleFunc("/getwarehouses", getWarehousesForStock).Methods("GET")
	router.HandleFunc("/getbarangforstock/{id}", getBarangForStock).Methods("GET")
	router.HandleFunc("/getcurrentstock/{id}", getCurrentStockInfo).Methods("GET")
	router.HandleFunc("/createbarangstock", createBarangStock).Methods("POST")

	// Inventory report routes
	router.HandleFunc("/getinventorysummary", getInventorySummary).Methods("GET")
}
