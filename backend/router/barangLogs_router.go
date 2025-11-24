package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sort"
	"src/database"
	"strconv"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type BarangLogs struct {
	LogsID     string `json:"logs_id"`
	LogsStatus int    `json:"logs_status"`
	LogsDate   string `json:"logs_date"`
	LogsDesc   string `json:"logs_desc"`
}

type BarangLogsRequest struct {
	LogsStatus int    `json:"logs_status"`
	LogsDate   string `json:"logs_date"`
	LogsDesc   string `json:"logs_desc"`
}

func createBarangLogs(w http.ResponseWriter, r *http.Request) {
	var logs BarangLogsRequest
	if err := json.NewDecoder(r.Body).Decode(&logs); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if logs.LogsDesc == "" {
		respondWithError(w, http.StatusBadRequest, "logs_desc is required")
		return
	}
	if logs.LogsStatus != 1 && logs.LogsStatus != 2 {
		respondWithError(w, http.StatusBadRequest, "logs_status must be 1 (Masuk) or 2 (Keluar)")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get last logs_id
	var lastID string
	err = db.QueryRow("SELECT logs_id FROM barang_logs ORDER BY logs_id DESC LIMIT 1").Scan(&lastID)
	if err != nil && err != sql.ErrNoRows {
		respondWithError(w, http.StatusInternalServerError, "Error fetching last logs_id")
		return
	}
	nextNum := 1
	if lastID != "" {
		numPart := lastID[3:] // "LO_0000004" -> "0000004"
		n, _ := strconv.Atoi(numPart)
		nextNum = n + 1
	}
	newID := fmt.Sprintf("LO_%07d", nextNum) // "LO_0000005"

	// Handle date - if not provided, use current date
	var logsDate string
	if logs.LogsDate == "" {
		logsDate = time.Now().Format("2006-01-02")
	} else {
		logsDate = logs.LogsDate
	}

	stmt, err := db.Prepare("INSERT INTO barang_logs (logs_id, logs_status, logs_date, logs_desc) VALUES (?, ?, ?, ?)")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(newID, logs.LogsStatus, logsDate, logs.LogsDesc)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Insert error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"logs_id":     newID,
		"logs_status": logs.LogsStatus,
		"logs_date":   logsDate,
		"logs_desc":   logs.LogsDesc,
		"status":      "Created",
		"message":     "Barang logs created successfully",
	})
}

func getBarangLogs(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get query parameters for filtering
	statusFilter := r.URL.Query().Get("status") // Filter by logs_status
	dateFilter := r.URL.Query().Get("date")     // Filter by logs_date

	// Query for logs_status = 1 (Masuk) from orders_masuk table
	queryMasuk := `
		SELECT 
			bl.logs_id,
			bl.logs_status,
			bl.logs_date,
			bl.logs_desc,
			GROUP_CONCAT(
				CONCAT_WS('|',
					om.orders_id,
					om.barang_id,
					b.barang_nama,
					br.brand_id,
					br.brand_nama,
					om.gudang_id,
					lg.gudang_nama,
					om.orders_amount,
					om.orders_value,
					om.orders_pay_type,
					om.orders_status,
					om.orders_deadline
				) SEPARATOR ';;'
			) as orders_data
		FROM barang_logs bl
		LEFT JOIN orders_masuk om ON bl.logs_id = om.logs_id
		LEFT JOIN barang b ON om.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN list_gudang lg ON om.gudang_id = lg.gudang_id
		WHERE bl.logs_status = 1`

	// Query for logs_status = 2 (Keluar) from orders_keluar table
	queryKeluar := `
		SELECT 
			bl.logs_id,
			bl.logs_status,
			bl.logs_date,
			bl.logs_desc,
			GROUP_CONCAT(
				CONCAT_WS('|',
					ok.orders_id,
					ok.barang_id,
					b.barang_nama,
					br.brand_id,
					br.brand_nama,
					ok.gudang_id,
					lg.gudang_nama,
					ok.orders_amount,
					0,
					0,
					ok.orders_status,
					''
				) SEPARATOR ';;'
			) as orders_data
		FROM barang_logs bl
		LEFT JOIN orders_keluar ok ON bl.logs_id = ok.logs_id
		LEFT JOIN barang b ON ok.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN list_gudang lg ON ok.gudang_id = lg.gudang_id
		WHERE bl.logs_status = 2`

	var argsMasuk, argsKeluar []interface{}

	// Add filter conditions for Masuk
	if dateFilter != "" {
		queryMasuk += " AND bl.logs_date = ?"
		argsMasuk = append(argsMasuk, dateFilter)
	}
	queryMasuk += " GROUP BY bl.logs_id"

	// Add filter conditions for Keluar
	if dateFilter != "" {
		queryKeluar += " AND bl.logs_date = ?"
		argsKeluar = append(argsKeluar, dateFilter)
	}
	queryKeluar += " GROUP BY bl.logs_id"

	var logs []map[string]interface{}

	// Determine which query to run based on status filter
	if statusFilter == "" || statusFilter == "1" {
		// Get Masuk orders
		rowsMasuk, err := db.Query(queryMasuk, argsMasuk...)
		if err != nil {
			respondWithError(w, http.StatusInternalServerError, "Query error (masuk): "+err.Error())
			return
		}
		defer rowsMasuk.Close()

		for rowsMasuk.Next() {
			var (
				logsID             string
				logsStatus         int
				logsDate, logsDesc string
				ordersData         sql.NullString
			)

			if err := rowsMasuk.Scan(&logsID, &logsStatus, &logsDate, &logsDesc, &ordersData); err != nil {
				respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
				return
			}

			log := map[string]interface{}{
				"logs_id":     logsID,
				"logs_status": logsStatus,
				"logs_date":   logsDate,
				"logs_desc":   logsDesc,
				"orders":      []map[string]interface{}{},
			}

			// Parse orders data
			if ordersData.Valid && ordersData.String != "" {
				orders := parseOrdersData(ordersData.String)
				log["orders"] = orders
			}

			logs = append(logs, log)
		}
	}

	if statusFilter == "" || statusFilter == "2" {
		// Get Keluar orders
		rowsKeluar, err := db.Query(queryKeluar, argsKeluar...)
		if err != nil {
			respondWithError(w, http.StatusInternalServerError, "Query error (keluar): "+err.Error())
			return
		}
		defer rowsKeluar.Close()

		for rowsKeluar.Next() {
			var (
				logsID             string
				logsStatus         int
				logsDate, logsDesc string
				ordersData         sql.NullString
			)

			if err := rowsKeluar.Scan(&logsID, &logsStatus, &logsDate, &logsDesc, &ordersData); err != nil {
				respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
				return
			}

			log := map[string]interface{}{
				"logs_id":     logsID,
				"logs_status": logsStatus,
				"logs_date":   logsDate,
				"logs_desc":   logsDesc,
				"orders":      []map[string]interface{}{},
			}

			// Parse orders data
			if ordersData.Valid && ordersData.String != "" {
				orders := parseOrdersData(ordersData.String)
				log["orders"] = orders
			}

			logs = append(logs, log)
		}
	}

	// Sort by logs_date DESC, logs_id DESC
	sort.Slice(logs, func(i, j int) bool {
		dateI := logs[i]["logs_date"].(string)
		dateJ := logs[j]["logs_date"].(string)
		if dateI != dateJ {
			return dateI > dateJ
		}
		return logs[i]["logs_id"].(string) > logs[j]["logs_id"].(string)
	})

	respondWithJSON(w, logs)
}

// Helper function to parse concatenated orders data
func parseOrdersData(ordersDataStr string) []map[string]interface{} {
	// Split by ';;' manually
	ordersStrings := []string{}
	currentOrder := ""
	for i := 0; i < len(ordersDataStr); i++ {
		if i < len(ordersDataStr)-1 && ordersDataStr[i:i+2] == ";;" {
			if currentOrder != "" {
				ordersStrings = append(ordersStrings, currentOrder)
				currentOrder = ""
			}
			i++ // Skip the second semicolon
		} else {
			currentOrder += string(ordersDataStr[i])
		}
	}
	if currentOrder != "" {
		ordersStrings = append(ordersStrings, currentOrder)
	}

	orders := []map[string]interface{}{}
	for _, orderStr := range ordersStrings {
		parts := []string{}
		currentPart := ""
		for _, char := range orderStr {
			if char == '|' {
				parts = append(parts, currentPart)
				currentPart = ""
			} else {
				currentPart += string(char)
			}
		}
		// Don't add the last empty part if string ends with |
		if currentPart != "" {
			parts = append(parts, currentPart)
		}

		// Need at least 11 parts (0-10) for a valid order
		// parts[11] (orders_deadline) can be empty for orders_keluar
		if len(parts) >= 11 {
			ordersAmount, _ := strconv.Atoi(parts[7])
			ordersValue, _ := strconv.Atoi(parts[8])
			ordersPayType, _ := strconv.Atoi(parts[9])
			ordersStatus, _ := strconv.Atoi(parts[10])

			// Get deadline if it exists (for orders_masuk)
			deadline := ""
			if len(parts) > 11 {
				deadline = parts[11]
			}

			order := map[string]interface{}{
				"orders_id":       parts[0],
				"barang_id":       parts[1],
				"barang_nama":     parts[2],
				"brand_id":        parts[3],
				"brand_nama":      parts[4],
				"gudang_id":       parts[5],
				"gudang_nama":     parts[6],
				"orders_amount":   ordersAmount,
				"orders_value":    ordersValue,
				"orders_pay_type": ordersPayType,
				"orders_status":   ordersStatus,
				"orders_deadline": deadline,
			}
			orders = append(orders, order)
		}
	}
	return orders
}

func getBarangLog(w http.ResponseWriter, r *http.Request) {
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
			bl.logs_id,
			bl.logs_status,
			bl.logs_date,
			bl.logs_desc,
			GROUP_CONCAT(
				CONCAT_WS('|',
					o.orders_id,
					o.barang_id,
					b.barang_nama,
					br.brand_id,
					br.brand_nama,
					o.gudang_id,
					lg.gudang_nama,
					o.orders_amount,
					o.orders_value,
					o.orders_pay_type,
					o.orders_status,
					o.orders_deadline
				) SEPARATOR ';;'
			) as orders_data
		FROM barang_logs bl
		LEFT JOIN orders o ON bl.logs_id = o.logs_id
		LEFT JOIN barang b ON o.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN list_gudang lg ON o.gudang_id = lg.gudang_id
		WHERE bl.logs_id = ?
		GROUP BY bl.logs_id`

	var (
		logsID             string
		logsStatus         int
		logsDate, logsDesc string
		ordersData         sql.NullString
	)

	err = db.QueryRow(query, id).Scan(&logsID, &logsStatus,
		&logsDate, &logsDesc, &ordersData)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang logs not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}

	log := map[string]interface{}{
		"logs_id":     logsID,
		"logs_status": logsStatus,
		"logs_date":   logsDate,
		"logs_desc":   logsDesc,
		"orders":      []map[string]interface{}{},
	}

	// Parse orders data
	if ordersData.Valid && ordersData.String != "" {
		// Split by ';;' manually
		ordersStrings := []string{}
		currentOrder := ""
		for i := 0; i < len(ordersData.String); i++ {
			if i < len(ordersData.String)-1 && ordersData.String[i:i+2] == ";;" {
				if currentOrder != "" {
					ordersStrings = append(ordersStrings, currentOrder)
					currentOrder = ""
				}
				i++ // Skip the second semicolon
			} else {
				currentOrder += string(ordersData.String[i])
			}
		}
		if currentOrder != "" {
			ordersStrings = append(ordersStrings, currentOrder)
		}

		orders := []map[string]interface{}{}
		for _, orderStr := range ordersStrings {
			parts := []string{}
			currentPart := ""
			for _, char := range orderStr {
				if char == '|' {
					parts = append(parts, currentPart)
					currentPart = ""
				} else {
					currentPart += string(char)
				}
			}
			if currentPart != "" {
				parts = append(parts, currentPart)
			}

			if len(parts) >= 12 {
				ordersAmount, _ := strconv.Atoi(parts[7])
				ordersValue, _ := strconv.Atoi(parts[8])
				ordersPayType, _ := strconv.Atoi(parts[9])
				ordersStatus, _ := strconv.Atoi(parts[10])

				order := map[string]interface{}{
					"orders_id":       parts[0],
					"barang_id":       parts[1],
					"barang_nama":     parts[2],
					"brand_id":        parts[3],
					"brand_nama":      parts[4],
					"gudang_id":       parts[5],
					"gudang_nama":     parts[6],
					"orders_amount":   ordersAmount,
					"orders_value":    ordersValue,
					"orders_pay_type": ordersPayType,
					"orders_status":   ordersStatus,
					"orders_deadline": parts[11],
				}
				orders = append(orders, order)
			}
		}
		log["orders"] = orders
	}

	respondWithJSON(w, log)
}

func updateBarangLogs(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	var logs BarangLogsRequest
	if err := json.NewDecoder(r.Body).Decode(&logs); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if logs.LogsDesc == "" {
		respondWithError(w, http.StatusBadRequest, "logs_desc is required")
		return
	}
	if logs.LogsStatus != 1 && logs.LogsStatus != 2 {
		respondWithError(w, http.StatusBadRequest, "logs_status must be 1 (Masuk) or 2 (Keluar)")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if logs exists
	var existingLogsID string
	err = db.QueryRow("SELECT logs_id FROM barang_logs WHERE logs_id = ?", id).Scan(&existingLogsID)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang logs with ID "+id+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking logs existence: "+err.Error())
		return
	}

	stmt, err := db.Prepare("UPDATE barang_logs SET logs_status = ?, logs_date = ?, logs_desc = ? WHERE logs_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(logs.LogsStatus, logs.LogsDate, logs.LogsDesc, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"logs_id":     id,
		"logs_status": logs.LogsStatus,
		"logs_date":   logs.LogsDate,
		"logs_desc":   logs.LogsDesc,
		"status":      "Updated",
		"message":     "Barang logs updated successfully",
	})
}

func deleteBarangLogs(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	// Get fresh database connection
	db, err := database.GetDBConnection()
	if err != nil {
		log.Printf("Database connection error: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Test connection before starting transaction
	if err := db.Ping(); err != nil {
		log.Printf("Database ping failed: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Database connection unavailable")
		return
	}

	// First, collect stock restoration data BEFORE starting transaction
	// This reduces the transaction time and avoids connection timeouts
	type StockUpdate struct {
		BarangID     string
		GudangID     string
		LantaiID     string
		OrdersAmount int
		OrdersStatus int
	}
	var stockUpdates []StockUpdate
	var logsStatus int

	// Get log status and collect orders data
	err = db.QueryRow("SELECT logs_status FROM barang_logs WHERE logs_id = ?", id).Scan(&logsStatus)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Barang logs not found")
		return
	} else if err != nil {
		log.Printf("Error fetching barang logs: %v", err)
		respondWithError(w, http.StatusInternalServerError, fmt.Sprintf("Error fetching barang logs: %v", err))
		return
	}

	// Collect stock update data based on log type
	var rows *sql.Rows
	if logsStatus == 1 {
		rows, err = db.Query(`
			SELECT barang_id, gudang_id, lantai_id, orders_amount, orders_status 
			FROM orders_masuk 
			WHERE logs_id = ?`, id)
	} else if logsStatus == 2 {
		rows, err = db.Query(`
			SELECT barang_id, gudang_id, lantai_id, orders_amount, orders_status 
			FROM orders_keluar 
			WHERE logs_id = ?`, id)
	}

	if err != nil {
		log.Printf("Error fetching orders: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Error fetching orders")
		return
	}
	defer rows.Close()

	for rows.Next() {
		var update StockUpdate
		if err := rows.Scan(&update.BarangID, &update.GudangID, &update.LantaiID, &update.OrdersAmount, &update.OrdersStatus); err != nil {
			log.Printf("Error scanning orders: %v", err)
			continue // Skip this order but continue with others
		}
		stockUpdates = append(stockUpdates, update)
	}
	rows.Close() // Close rows before starting transaction

	// Now start transaction for deletion
	tx, err := db.Begin()
	if err != nil {
		log.Printf("Error starting transaction: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}
	defer tx.Rollback() // Will be no-op if commit succeeds

	// Delete orders first (cascading delete)
	if logsStatus == 1 {
		_, err = tx.Exec("DELETE FROM orders_masuk WHERE logs_id = ?", id)
		if err != nil {
			tx.Rollback()
			log.Printf("Error deleting orders_masuk: %v", err)
			respondWithError(w, http.StatusInternalServerError, "Error deleting orders_masuk")
			return
		}
	} else if logsStatus == 2 {
		_, err = tx.Exec("DELETE FROM orders_keluar WHERE logs_id = ?", id)
		if err != nil {
			tx.Rollback()
			log.Printf("Error deleting orders_keluar: %v", err)
			respondWithError(w, http.StatusInternalServerError, "Error deleting orders_keluar")
			return
		}
	}

	// Delete the barang_logs entry
	res, err := tx.Exec("DELETE FROM barang_logs WHERE logs_id = ?", id)
	if err != nil {
		tx.Rollback()
		log.Printf("Error deleting barang_logs: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Error deleting barang_logs: "+err.Error())
		return
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		tx.Rollback()
		respondWithError(w, http.StatusNotFound, "Barang logs not found")
		return
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		log.Printf("Error committing transaction: %v", err)
		respondWithError(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	// Now update stock AFTER successful deletion (outside transaction)
	// This makes the operation more resilient - deletion succeeds even if stock update fails
	stockRestoreWarnings := []string{}
	for _, update := range stockUpdates {
		// Only restore stock if the order was completed (status = 1)
		if update.OrdersStatus == 1 {
			// Use stored lantai_id if available, otherwise get it from gudang_id
			lantaiID := update.LantaiID
			if lantaiID == "" {
				err = db.QueryRow(`
					SELECT lantai_id 
					FROM gudang_lantai 
					WHERE gudang_id = ? 
					ORDER BY lantai_no 
					LIMIT 1`, update.GudangID).Scan(&lantaiID)

				if err != nil {
					if err == sql.ErrNoRows {
						warning := fmt.Sprintf("Floor not found for gudang_id=%s", update.GudangID)
						log.Printf("Warning: %s", warning)
						stockRestoreWarnings = append(stockRestoreWarnings, warning)
						continue
					} else {
						warning := fmt.Sprintf("Error fetching floor for gudang_id=%s: %v", update.GudangID, err)
						log.Printf("Warning: %s", warning)
						stockRestoreWarnings = append(stockRestoreWarnings, warning)
						continue
					}
				}
			}

			var currentStock int
			err = db.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?",
				update.BarangID, lantaiID).Scan(&currentStock)

			if err != nil {
				if err == sql.ErrNoRows {
					warning := fmt.Sprintf("Stock record not found for barang_id=%s, lantai_id=%d", update.BarangID, lantaiID)
					log.Printf("Warning: %s", warning)
					stockRestoreWarnings = append(stockRestoreWarnings, warning)
					continue
				} else {
					warning := fmt.Sprintf("Error fetching stock for barang_id=%s, lantai_id=%d: %v", update.BarangID, lantaiID, err)
					log.Printf("Warning: %s", warning)
					stockRestoreWarnings = append(stockRestoreWarnings, warning)
					continue
				}
			}

			// Calculate new stock based on log type
			var newStock int
			if logsStatus == 1 {
				// Masuk: subtract amount (reverse addition)
				newStock = currentStock - update.OrdersAmount
			} else {
				// Keluar: add amount back (reverse subtraction)
				newStock = currentStock + update.OrdersAmount
			}

			if newStock < 0 {
				newStock = 0 // Prevent negative stock
			}

			_, err = db.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?",
				newStock, update.BarangID, lantaiID)
			if err != nil {
				warning := fmt.Sprintf("Error updating stock for barang_id=%s, lantai_id=%d: %v", update.BarangID, lantaiID, err)
				log.Printf("Warning: %s", warning)
				stockRestoreWarnings = append(stockRestoreWarnings, warning)
			}
		}
	}

	message := "Barang logs and all associated orders deleted successfully"
	if len(stockRestoreWarnings) > 0 {
		message += " (with some stock restoration warnings - check logs)"
	} else if len(stockUpdates) > 0 {
		message += " with stock restored"
	}

	respondWithJSON(w, map[string]interface{}{
		"logs_id":  id,
		"status":   "Deleted",
		"message":  message,
		"warnings": stockRestoreWarnings,
	})
}

// SetupBarangLogsRoutes sets up all barang logs-related routes

// SetupBarangLogsRoutes sets up all barang logs-related routes
func SetupBarangLogsRoutes(router *mux.Router) {
	router.HandleFunc("/createbaranglogs", createBarangLogs).Methods("POST")
	router.HandleFunc("/getbaranglogs", getBarangLogs).Methods("GET")
	router.HandleFunc("/getbaranglog/{id}", getBarangLog).Methods("GET")
	router.HandleFunc("/updatebaranglogs/{id}", updateBarangLogs).Methods("PUT")
	router.HandleFunc("/deletebaranglogs/{id}", deleteBarangLogs).Methods("DELETE")
}
