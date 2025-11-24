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
)

type OrdersKeluar struct {
	OrdersID     string `json:"orders_id"`
	LogsID       string `json:"logs_id"`
	BarangID     string `json:"barang_id"`
	GudangID     string `json:"gudang_id"`
	OrdersAmount int    `json:"orders_amount"`
	OrdersStatus int    `json:"orders_status"`
	// Additional fields from JOINs for display
	BarangNama string `json:"barang_nama,omitempty"`
	BrandNama  string `json:"brand_nama,omitempty"`
	GudangNama string `json:"gudang_nama,omitempty"`
	LogsStatus int    `json:"logs_status,omitempty"`
	LogsDate   string `json:"logs_date,omitempty"`
	LogsDesc   string `json:"logs_desc,omitempty"`
}

type CombinedOrderKeluarBatch struct {
	LogsDate     string              `json:"logs_date"`
	LogsDesc     string              `json:"logs_desc"`
	OrdersStatus int                 `json:"orders_status"`
	Orders       []OrderKeluarDetail `json:"orders"`
}

type OrderKeluarDetail struct {
	GudangID     string `json:"gudang_id,omitempty"` // Deprecated: kept for backward compatibility
	LantaiID     string `json:"lantai_id"`           // New: floor-level tracking
	BarangID     string `json:"barang_id"`
	OrdersAmount int    `json:"orders_amount"`
}

// Helper function to respond with JSON
func respondWithJSONOrdersOut(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Helper function to respond with error
func respondWithErrorOrdersOut(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

// Create batch orders keluar with single barang_logs entry
func createBatchOrderKeluar(w http.ResponseWriter, r *http.Request) {
	var batch CombinedOrderKeluarBatch
	if err := json.NewDecoder(r.Body).Decode(&batch); err != nil {
		respondWithErrorOrdersOut(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate required fields
	if batch.LogsDesc == "" {
		batch.LogsDesc = "-"
	}
	if len(batch.Orders) == 0 {
		respondWithErrorOrdersOut(w, http.StatusBadRequest, "At least one order is required")
		return
	}

	// Validate each order
	for i, order := range batch.Orders {
		// Support both lantai_id (new) and gudang_id (legacy)
		if order.LantaiID == "" && order.GudangID == "" {
			respondWithErrorOrdersOut(w, http.StatusBadRequest, fmt.Sprintf("lantai_id is required for order %d", i+1))
			return
		}
		if order.BarangID == "" {
			respondWithErrorOrdersOut(w, http.StatusBadRequest, fmt.Sprintf("barang_id is required for order %d", i+1))
			return
		}
		if order.OrdersAmount <= 0 {
			respondWithErrorOrdersOut(w, http.StatusBadRequest, fmt.Sprintf("orders_amount must be greater than 0 for order %d", i+1))
			return
		}
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Begin transaction for data consistency
	tx, err := db.Begin()
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}

	// Validate all barang_id and lantai_id exist
	for i, order := range batch.Orders {
		var existingBarangID string
		err = tx.QueryRow("SELECT barang_id FROM barang WHERE barang_id = ?", order.BarangID).Scan(&existingBarangID)
		if err == sql.ErrNoRows {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusNotFound, fmt.Sprintf("Barang with ID %s not found for order %d", order.BarangID, i+1))
			return
		} else if err != nil {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error validating barang_id")
			return
		}

		// Validate lantai_id if provided (new format)
		if order.LantaiID != "" {
			var existingLantaiID string
			err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE lantai_id = ?", order.LantaiID).Scan(&existingLantaiID)
			if err == sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusNotFound, fmt.Sprintf("Lantai with ID %s not found for order %d", order.LantaiID, i+1))
				return
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error validating lantai_id")
				return
			}
		} else if order.GudangID != "" {
			// Legacy support: validate gudang_id
			var existingGudangID string
			err = tx.QueryRow("SELECT gudang_id FROM list_gudang WHERE gudang_id = ?", order.GudangID).Scan(&existingGudangID)
			if err == sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusNotFound, fmt.Sprintf("Gudang with ID %s not found for order %d", order.GudangID, i+1))
				return
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error validating gudang_id")
				return
			}
		}
	}

	// Step 1: Create barang_logs entry with logs_status = 2 (Keluar)
	var lastLogsID string
	err = tx.QueryRow("SELECT logs_id FROM barang_logs ORDER BY logs_id DESC LIMIT 1").Scan(&lastLogsID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error generating logs_id")
		return
	}
	nextLogsNum := 1
	if lastLogsID != "" {
		fmt.Sscanf(lastLogsID, "LO_%d", &nextLogsNum)
		nextLogsNum++
	}
	newLogsID := fmt.Sprintf("LO_%07d", nextLogsNum)

	// Handle date - if not provided, use current date
	var logsDate string
	if batch.LogsDate == "" {
		logsDate = time.Now().Format("2006-01-02")
	} else {
		logsDate = batch.LogsDate
	}

	// Insert barang_logs with logs_status = 2 (Keluar)
	logsStmt, err := tx.Prepare("INSERT INTO barang_logs (logs_id, logs_status, logs_date, logs_desc) VALUES (?, ?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error preparing logs insert")
		return
	}
	defer logsStmt.Close()

	_, err = logsStmt.Exec(newLogsID, 2, logsDate, batch.LogsDesc)
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error inserting barang_logs")
		return
	}

	// Step 2: Create multiple orders_keluar entries
	var lastOrdersID string
	err = tx.QueryRow("SELECT orders_id FROM orders_keluar ORDER BY orders_id DESC LIMIT 1").Scan(&lastOrdersID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error generating orders_id")
		return
	}
	nextOrdersNum := 1
	if lastOrdersID != "" {
		fmt.Sscanf(lastOrdersID, "OK_%d", &nextOrdersNum)
		nextOrdersNum++
	}

	// Prepare orders_keluar insert statement - now includes lantai_id
	ordersStmt, err := tx.Prepare("INSERT INTO orders_keluar (orders_id, logs_id, barang_id, gudang_id, lantai_id, orders_amount, orders_status) VALUES (?, ?, ?, ?, ?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error preparing orders insert")
		return
	}
	defer ordersStmt.Close()

	// Insert each order and update stock
	createdOrders := []map[string]interface{}{}
	for _, order := range batch.Orders {
		newOrdersID := fmt.Sprintf("OK_%07d", nextOrdersNum)
		nextOrdersNum++

		// Determine gudang_id: use lantai_id to get gudang_id if lantai_id is provided
		var gudangID string
		var lantaiID string

		if order.LantaiID != "" {
			// New format: get gudang_id from lantai_id
			err = tx.QueryRow("SELECT gudang_id FROM gudang_lantai WHERE lantai_id = ?", order.LantaiID).Scan(&gudangID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error fetching gudang_id from lantai_id")
				return
			}
			lantaiID = order.LantaiID
		} else {
			// Legacy format: use gudang_id directly, get first lantai_id
			gudangID = order.GudangID
			err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&lantaiID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error fetching lantai_id from gudang_id")
				return
			}
		}

		// Insert into orders_keluar with both gudang_id (compatibility) and lantai_id (new)
		_, err = ordersStmt.Exec(newOrdersID, newLogsID, order.BarangID, gudangID, lantaiID, order.OrdersAmount, batch.OrdersStatus)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error inserting order")
			return
		}

		// Update stock if orders_status is 1 (done)
		if batch.OrdersStatus == 1 {
			// Get current stock from stock_gudang using lantai_id
			var currentStock int
			err = tx.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", order.BarangID, lantaiID).Scan(&currentStock)
			if err == sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusNotFound, fmt.Sprintf("Stock not found for barang %s in lantai %s", order.BarangID, lantaiID))
				return
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error checking stock")
				return
			}

			// Check if enough stock
			if currentStock < order.OrdersAmount {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusBadRequest, fmt.Sprintf("Insufficient stock for barang %s in lantai %s (available: %d, requested: %d)", order.BarangID, lantaiID, currentStock, order.OrdersAmount))
				return
			}

			// Update stock (subtract for keluar)
			newStock := currentStock - order.OrdersAmount
			_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?", newStock, order.BarangID, lantaiID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error updating stock")
				return
			}
		}

		createdOrders = append(createdOrders, map[string]interface{}{
			"orders_id":     newOrdersID,
			"barang_id":     order.BarangID,
			"gudang_id":     gudangID,
			"lantai_id":     lantaiID,
			"orders_amount": order.OrdersAmount,
			"orders_status": batch.OrdersStatus,
		})
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	respondWithJSONOrdersOut(w, map[string]interface{}{
		"logs_id":       newLogsID,
		"logs_status":   2,
		"logs_date":     logsDate,
		"logs_desc":     batch.LogsDesc,
		"orders_status": batch.OrdersStatus,
		"orders":        createdOrders,
		"status":        "Created",
		"message":       fmt.Sprintf("Successfully created barang keluar with %d items", len(createdOrders)),
	})
}

// Get all orders keluar with detailed information
func getOrdersKeluar(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `
		SELECT 
			ok.orders_id, ok.logs_id, ok.barang_id, ok.gudang_id, 
			ok.orders_amount, ok.orders_status,
			b.barang_nama, br.brand_nama, g.gudang_nama,
			bl.logs_status, bl.logs_date, bl.logs_desc
		FROM orders_keluar ok
		JOIN barang_logs bl ON ok.logs_id = bl.logs_id
		JOIN barang b ON ok.barang_id = b.barang_id
		JOIN brand br ON b.brand_id = br.brand_id
		JOIN list_gudang g ON ok.gudang_id = g.gudang_id
		ORDER BY ok.orders_id DESC
	`

	rows, err := db.Query(query)
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error querying orders")
		return
	}
	defer rows.Close()

	var orders []OrdersKeluar
	for rows.Next() {
		var order OrdersKeluar
		err := rows.Scan(
			&order.OrdersID, &order.LogsID, &order.BarangID, &order.GudangID,
			&order.OrdersAmount, &order.OrdersStatus,
			&order.BarangNama, &order.BrandNama, &order.GudangNama,
			&order.LogsStatus, &order.LogsDate, &order.LogsDesc,
		)
		if err != nil {
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error scanning order")
			return
		}
		orders = append(orders, order)
	}

	respondWithJSONOrdersOut(w, orders)
}

// Update orders_keluar status
func updateOrdersKeluarStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	ordersID := vars["id"]

	var req struct {
		OrdersStatus int `json:"orders_status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithErrorOrdersOut(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate orders_status
	if req.OrdersStatus != 0 && req.OrdersStatus != 1 {
		respondWithErrorOrdersOut(w, http.StatusBadRequest, "orders_status must be 0 or 1")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	tx, err := db.Begin()
	if err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}

	// Get current order info including lantai_id
	var currentStatus, ordersAmount int
	var barangID, gudangID string
	var lantaiID sql.NullString
	err = tx.QueryRow("SELECT orders_status, barang_id, gudang_id, lantai_id, orders_amount FROM orders_keluar WHERE orders_id = ?", ordersID).Scan(&currentStatus, &barangID, &gudangID, &lantaiID, &ordersAmount)
	if err == sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusNotFound, "Order not found")
		return
	} else if err != nil {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error fetching order")
		return
	}

	// If lantai_id is not stored or empty (old records), get it from gudang_id
	var finalLantaiID string
	if lantaiID.Valid && lantaiID.String != "" {
		finalLantaiID = lantaiID.String
	} else {
		err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&finalLantaiID)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error fetching lantai_id")
			return
		}
	}

	// Calculate stock change
	var stockChange int
	if currentStatus == 0 && req.OrdersStatus == 1 {
		// Changing from pending to done - subtract stock
		stockChange = -ordersAmount
	} else if currentStatus == 1 && req.OrdersStatus == 0 {
		// Changing from done to pending - add stock back
		stockChange = ordersAmount
	}

	// Update order status
	_, err = tx.Exec("UPDATE orders_keluar SET orders_status = ? WHERE orders_id = ?", req.OrdersStatus, ordersID)
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error updating order status")
		return
	}

	// Update stock if there's a change
	if stockChange != 0 {
		var currentStock int
		err = tx.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", barangID, finalLantaiID).Scan(&currentStock)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error fetching stock")
			return
		}

		newStock := currentStock + stockChange
		if newStock < 0 {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusBadRequest, "Insufficient stock")
			return
		}

		_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?", newStock, barangID, finalLantaiID)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error updating stock")
			return
		}
	}

	if err := tx.Commit(); err != nil {
		respondWithErrorOrdersOut(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	respondWithJSONOrdersOut(w, map[string]interface{}{
		"message":       "Order status updated successfully",
		"orders_id":     ordersID,
		"orders_status": req.OrdersStatus,
		"stock_change":  stockChange,
	})
}

// SetupOrdersOutRoutes sets up all orders keluar routes
func SetupOrdersOutRoutes(router *mux.Router) {
	// Create batch orders keluar
	router.HandleFunc("/orders/keluar/batch", createBatchOrderKeluar).Methods("POST")

	// Get all orders keluar
	router.HandleFunc("/orders/keluar", getOrdersKeluar).Methods("GET")

	// Update orders keluar status
	router.HandleFunc("/orders/keluar/{id}/status", updateOrdersKeluarStatus).Methods("PUT")
}
