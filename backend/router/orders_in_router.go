package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"src/database"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type OrdersMasuk struct {
	OrdersID       string `json:"orders_id"`
	LogsID         string `json:"logs_id"`
	BarangID       string `json:"barang_id"`
	GudangID       string `json:"gudang_id"`
	OrdersAmount   int    `json:"orders_amount"`
	OrdersPayType  int    `json:"orders_pay_type"`
	OrdersValue    int    `json:"orders_value"`
	OrdersDate     string `json:"orders_date"`
	OrdersDeadline string `json:"orders_deadline"`
	OrdersStatus   int    `json:"orders_status"`
	// Additional fields from JOINs for display
	BarangNama string `json:"barang_nama,omitempty"`
	BrandNama  string `json:"brand_nama,omitempty"`
	GudangNama string `json:"gudang_nama,omitempty"`
	LogsStatus int    `json:"logs_status,omitempty"`
	LogsDate   string `json:"logs_date,omitempty"`
	LogsDesc   string `json:"logs_desc,omitempty"`
}

type CombinedOrderMasukBatch struct {
	LogsDate       string             `json:"logs_date"`
	LogsDesc       string             `json:"logs_desc"`
	OrdersPayType  int                `json:"orders_pay_type"`
	OrdersDeadline string             `json:"orders_deadline"`
	Orders         []OrderMasukDetail `json:"orders"`
}

type OrderMasukDetail struct {
	GudangID     string `json:"gudang_id,omitempty"` // Deprecated: kept for backward compatibility
	LantaiID     string `json:"lantai_id"`           // New: floor-level tracking
	BarangID     string `json:"barang_id"`
	OrdersAmount int    `json:"orders_amount"`
	OrdersValue  int    `json:"orders_value"`
}

// Helper function to respond with JSON
func respondWithJSONOrdersMasuk(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

// Helper function to respond with error
func respondWithErrorOrdersMasuk(w http.ResponseWriter, code int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

// Create batch orders masuk with single barang_logs entry
func createBatchOrderMasuk(w http.ResponseWriter, r *http.Request) {
	var batch CombinedOrderMasukBatch
	if err := json.NewDecoder(r.Body).Decode(&batch); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate required fields
	if batch.LogsDesc == "" {
		batch.LogsDesc = "-"
	}
	if batch.OrdersPayType != 1 && batch.OrdersPayType != 3 {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "orders_pay_type must be 1 (Lunas) or 3 (Kredit)")
		return
	}
	if len(batch.Orders) == 0 {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "At least one order is required")
		return
	}

	// Validate each order
	for i, order := range batch.Orders {
		// Support both lantai_id (new) and gudang_id (legacy)
		if order.LantaiID == "" && order.GudangID == "" {
			respondWithErrorOrdersMasuk(w, http.StatusBadRequest, fmt.Sprintf("lantai_id is required for order %d", i+1))
			return
		}
		if order.BarangID == "" {
			respondWithErrorOrdersMasuk(w, http.StatusBadRequest, fmt.Sprintf("barang_id is required for order %d", i+1))
			return
		}
		if order.OrdersAmount <= 0 {
			respondWithErrorOrdersMasuk(w, http.StatusBadRequest, fmt.Sprintf("orders_amount must be greater than 0 for order %d", i+1))
			return
		}
		if order.OrdersValue <= 0 {
			respondWithErrorOrdersMasuk(w, http.StatusBadRequest, fmt.Sprintf("orders_value must be greater than 0 for order %d", i+1))
			return
		}
	}

	// Validate deadline for Kredit payments
	if batch.OrdersPayType == 3 && batch.OrdersDeadline == "" {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "orders_deadline is required for Kredit payment")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Begin transaction for data consistency
	tx, err := db.Begin()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}

	// Validate all barang_id and lantai_id exist
	for i, order := range batch.Orders {
		var existingBarangID string
		err = tx.QueryRow("SELECT barang_id FROM barang WHERE barang_id = ?", order.BarangID).Scan(&existingBarangID)
		if err == sql.ErrNoRows {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusNotFound, fmt.Sprintf("Barang with ID %s not found for order %d", order.BarangID, i+1))
			return
		} else if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error validating barang_id")
			return
		}

		// Validate lantai_id if provided (new format)
		if order.LantaiID != "" {
			var existingLantaiID string
			err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE lantai_id = ?", order.LantaiID).Scan(&existingLantaiID)
			if err == sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusNotFound, fmt.Sprintf("Lantai with ID %s not found for order %d", order.LantaiID, i+1))
				return
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error validating lantai_id")
				return
			}
		} else if order.GudangID != "" {
			// Legacy support: validate gudang_id
			var existingGudangID string
			err = tx.QueryRow("SELECT gudang_id FROM list_gudang WHERE gudang_id = ?", order.GudangID).Scan(&existingGudangID)
			if err == sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusNotFound, fmt.Sprintf("Gudang with ID %s not found for order %d", order.GudangID, i+1))
				return
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error validating gudang_id")
				return
			}
		}
	}

	// Step 1: Create barang_logs entry with logs_status = 1 (Masuk)
	var lastLogsID string
	err = tx.QueryRow("SELECT logs_id FROM barang_logs ORDER BY logs_id DESC LIMIT 1").Scan(&lastLogsID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error generating logs_id")
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

	// Insert barang_logs with logs_status = 1 (Masuk)
	logsStmt, err := tx.Prepare("INSERT INTO barang_logs (logs_id, logs_status, logs_date, logs_desc) VALUES (?, ?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error preparing logs insert")
		return
	}
	defer logsStmt.Close()

	_, err = logsStmt.Exec(newLogsID, 1, logsDate, batch.LogsDesc)
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error inserting barang_logs")
		return
	}

	// Step 2: Create multiple orders_masuk entries
	var lastOrdersID string
	err = tx.QueryRow("SELECT orders_id FROM orders_masuk ORDER BY orders_id DESC LIMIT 1").Scan(&lastOrdersID)
	if err != nil && err != sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error generating orders_id")
		return
	}
	nextOrdersNum := 1
	if lastOrdersID != "" {
		fmt.Sscanf(lastOrdersID, "OM_%d", &nextOrdersNum)
		nextOrdersNum++
	}

	// Determine orders_status based on payment type
	// 1 (Lunas) = status 1, 3 (Kredit) = status 0
	ordersStatus := 1
	if batch.OrdersPayType == 3 {
		ordersStatus = 0
	}

	// Set deadline - if Lunas, use current date
	ordersDeadline := batch.OrdersDeadline
	if batch.OrdersPayType == 1 {
		ordersDeadline = logsDate
	}

	// Prepare orders_masuk insert statement
	ordersStmt, err := tx.Prepare("INSERT INTO orders_masuk (orders_id, logs_id, barang_id, gudang_id, lantai_id, orders_amount, orders_pay_type, orders_value, orders_deadline, orders_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error preparing orders insert")
		return
	}
	defer ordersStmt.Close()

	// Insert each order and update stock if Lunas
	createdOrders := []map[string]interface{}{}
	for _, order := range batch.Orders {
		newOrdersID := fmt.Sprintf("OM_%07d", nextOrdersNum)
		nextOrdersNum++

		// Determine gudang_id: use lantai_id to get gudang_id if lantai_id is provided
		var gudangID string
		var lantaiID string

		if order.LantaiID != "" {
			// New format: get gudang_id from lantai_id
			err = tx.QueryRow("SELECT gudang_id FROM gudang_lantai WHERE lantai_id = ?", order.LantaiID).Scan(&gudangID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching gudang_id from lantai_id")
				return
			}
			lantaiID = order.LantaiID
		} else {
			// Legacy format: use gudang_id directly, get first lantai_id
			gudangID = order.GudangID
			err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&lantaiID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching lantai_id from gudang_id")
				return
			}
		}

		// Insert into orders_masuk with both gudang_id and lantai_id
		_, err = ordersStmt.Exec(newOrdersID, newLogsID, order.BarangID, gudangID, lantaiID, order.OrdersAmount, batch.OrdersPayType, order.OrdersValue, ordersDeadline, ordersStatus)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error inserting order")
			return
		}

		// Update stock if orders_status is 1 (Lunas/done)
		if ordersStatus == 1 {
			// Check if stock record exists using lantai_id
			var currentStock int
			err = tx.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", order.BarangID, lantaiID).Scan(&currentStock)

			if err == sql.ErrNoRows {
				// Create stock record if it doesn't exist - need to generate stock_id
				var lastStockID string
				err = tx.QueryRow("SELECT stock_id FROM stock_gudang ORDER BY stock_id DESC LIMIT 1").Scan(&lastStockID)
				if err != nil && err != sql.ErrNoRows {
					tx.Rollback()
					respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error generating stock_id")
					return
				}

				nextNum := 1
				if lastStockID != "" {
					numPart := lastStockID[3:] // "ST_000010" -> "000010"
					n, _ := strconv.Atoi(numPart)
					nextNum = n + 1
				}
				newStockID := fmt.Sprintf("ST_%06d", nextNum)

				// Insert with lantai_id instead of gudang_id
				_, err = tx.Exec("INSERT INTO stock_gudang (stock_id, barang_id, lantai_id, stock_barang) VALUES (?, ?, ?, ?)", newStockID, order.BarangID, lantaiID, order.OrdersAmount)
				if err != nil {
					tx.Rollback()
					respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error creating stock")
					return
				}
			} else if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error checking stock")
				return
			} else {
				// Update existing stock (add for masuk)
				newStock := currentStock + order.OrdersAmount
				_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?", newStock, order.BarangID, lantaiID)
				if err != nil {
					tx.Rollback()
					respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error updating stock")
					return
				}
			}
		}

		createdOrders = append(createdOrders, map[string]interface{}{
			"orders_id":       newOrdersID,
			"barang_id":       order.BarangID,
			"gudang_id":       gudangID,
			"lantai_id":       lantaiID,
			"orders_amount":   order.OrdersAmount,
			"orders_value":    order.OrdersValue,
			"orders_pay_type": batch.OrdersPayType,
			"orders_deadline": ordersDeadline,
			"orders_status":   ordersStatus,
		})
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	respondWithJSONOrdersMasuk(w, map[string]interface{}{
		"logs_id":         newLogsID,
		"logs_status":     1,
		"logs_date":       logsDate,
		"logs_desc":       batch.LogsDesc,
		"orders_pay_type": batch.OrdersPayType,
		"orders_deadline": ordersDeadline,
		"orders_status":   ordersStatus,
		"orders":          createdOrders,
		"status":          "Created",
		"message":         fmt.Sprintf("Successfully created pesan barang with %d items", len(createdOrders)),
	})
}

// Get all orders masuk with detailed information
func getOrdersMasuk(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	query := `
		SELECT 
			om.orders_id, om.logs_id, om.barang_id, om.gudang_id, 
			om.orders_amount, om.orders_pay_type, om.orders_value,
			om.orders_deadline, om.orders_status,
			b.barang_nama, br.brand_nama, g.gudang_nama,
			bl.logs_status, bl.logs_date, bl.logs_desc
		FROM orders_masuk om
		JOIN barang_logs bl ON om.logs_id = bl.logs_id
		JOIN barang b ON om.barang_id = b.barang_id
		JOIN brand br ON b.brand_id = br.brand_id
		JOIN gudang_lantai gl ON om.lantai_id = gl.lantai_id
		JOIN list_gudang g ON gl.gudang_id = g.gudang_id
		ORDER BY om.orders_id DESC
	`

	rows, err := db.Query(query)
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error querying orders")
		return
	}
	defer rows.Close()

	var orders []OrdersMasuk
	for rows.Next() {
		var order OrdersMasuk
		err := rows.Scan(
			&order.OrdersID, &order.LogsID, &order.BarangID, &order.GudangID,
			&order.OrdersAmount, &order.OrdersPayType, &order.OrdersValue,
			&order.OrdersDeadline, &order.OrdersStatus,
			&order.BarangNama, &order.BrandNama, &order.GudangNama,
			&order.LogsStatus, &order.LogsDate, &order.LogsDesc,
		)
		if err != nil {
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error scanning order")
			return
		}
		orders = append(orders, order)
	}

	respondWithJSONOrdersMasuk(w, orders)
}

// Update orders_masuk status (for Kredit to Lunas)
func updateOrdersMasukStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	ordersID := vars["id"]

	var req struct {
		OrdersStatus int `json:"orders_status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate orders_status
	if req.OrdersStatus != 0 && req.OrdersStatus != 1 {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "orders_status must be 0 or 1")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	tx, err := db.Begin()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}

	// Get current order info including lantai_id
	var currentStatus, ordersAmount int
	var barangID, gudangID string
	var lantaiIDNull sql.NullString
	err = tx.QueryRow("SELECT orders_status, barang_id, gudang_id, lantai_id, orders_amount FROM orders_masuk WHERE orders_id = ?", ordersID).Scan(&currentStatus, &barangID, &gudangID, &lantaiIDNull, &ordersAmount)
	if err == sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusNotFound, "Order not found")
		return
	} else if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching order")
		return
	}

	// Use lantai_id from order, fallback to first floor if empty
	var lantaiID string
	if lantaiIDNull.Valid && lantaiIDNull.String != "" {
		lantaiID = lantaiIDNull.String
	} else {
		// Fallback: get first floor of the gudang
		err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&lantaiID)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching lantai_id for gudang")
			return
		}
	}

	// Calculate stock change
	var stockChange int
	if currentStatus == 0 && req.OrdersStatus == 1 {
		// Changing from pending (Kredit) to done (Lunas) - add stock
		stockChange = ordersAmount
	} else if currentStatus == 1 && req.OrdersStatus == 0 {
		// Changing from done to pending - subtract stock
		stockChange = -ordersAmount
	}

	// Update order status
	_, err = tx.Exec("UPDATE orders_masuk SET orders_status = ? WHERE orders_id = ?", req.OrdersStatus, ordersID)
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error updating order status")
		return
	}

	// Update stock if there's a change
	if stockChange != 0 {
		var currentStock int
		err = tx.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", barangID, lantaiID).Scan(&currentStock)

		if err == sql.ErrNoRows && stockChange > 0 {
			// Create stock record if it doesn't exist and we're adding stock
			var lastStockID string
			err = tx.QueryRow("SELECT stock_id FROM stock_gudang ORDER BY stock_id DESC LIMIT 1").Scan(&lastStockID)
			if err != nil && err != sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error generating stock_id")
				return
			}

			nextNum := 1
			if lastStockID != "" {
				numPart := lastStockID[3:]
				n, _ := strconv.Atoi(numPart)
				nextNum = n + 1
			}
			newStockID := fmt.Sprintf("ST_%06d", nextNum)

			_, err = tx.Exec("INSERT INTO stock_gudang (stock_id, barang_id, lantai_id, stock_barang) VALUES (?, ?, ?, ?)", newStockID, barangID, lantaiID, stockChange)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error creating stock")
				return
			}
		} else if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching stock")
			return
		} else {
			newStock := currentStock + stockChange
			if newStock < 0 {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "Cannot reduce stock below zero")
				return
			}

			_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?", newStock, barangID, lantaiID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error updating stock")
				return
			}
		}
	}

	if err := tx.Commit(); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	respondWithJSONOrdersMasuk(w, map[string]interface{}{
		"message":       "Order status updated successfully",
		"orders_id":     ordersID,
		"orders_status": req.OrdersStatus,
		"stock_change":  stockChange,
	})
}

// Update orders masuk (full update including amount, value, deadline, pay_type, status)
func updateOrdersMasuk(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	ordersID := vars["id"]

	var req struct {
		OrdersAmount   int    `json:"orders_amount"`
		OrdersValue    int    `json:"orders_value"`
		OrdersDeadline string `json:"orders_deadline"`
		OrdersPayType  int    `json:"orders_pay_type"`
		OrdersStatus   int    `json:"orders_status"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	// Validate pay_type
	if req.OrdersPayType != 1 && req.OrdersPayType != 3 {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "orders_pay_type must be 1 (Lunas) or 3 (Kredit)")
		return
	}

	// Validate deadline for Kredit
	if req.OrdersPayType == 3 && req.OrdersDeadline == "" {
		respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "orders_deadline is required for Kredit payment")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Begin transaction
	tx, err := db.Begin()
	if err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error starting transaction")
		return
	}

	// Get current order data including lantai_id
	var oldAmount, oldStatus int
	var barangID, gudangID string
	var lantaiIDNull sql.NullString
	err = tx.QueryRow("SELECT orders_amount, orders_status, barang_id, gudang_id, lantai_id FROM orders_masuk WHERE orders_id = ?", ordersID).Scan(&oldAmount, &oldStatus, &barangID, &gudangID, &lantaiIDNull)
	if err == sql.ErrNoRows {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusNotFound, "Order not found")
		return
	} else if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching order")
		return
	}

	// Use lantai_id from order, fallback to first floor if empty
	var lantaiID string
	if lantaiIDNull.Valid && lantaiIDNull.String != "" {
		lantaiID = lantaiIDNull.String
	} else {
		// Fallback: get first floor of the gudang
		err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", gudangID).Scan(&lantaiID)
		if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching lantai_id for gudang")
			return
		}
	}

	// Update order
	_, err = tx.Exec(`UPDATE orders_masuk 
		SET orders_amount = ?, orders_value = ?, orders_deadline = ?, orders_pay_type = ?, orders_status = ? 
		WHERE orders_id = ?`,
		req.OrdersAmount, req.OrdersValue, req.OrdersDeadline, req.OrdersPayType, req.OrdersStatus, ordersID)
	if err != nil {
		tx.Rollback()
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error updating order")
		return
	}

	// Handle stock changes
	// Calculate stock impact from status change
	var stockChange int
	if oldStatus == 0 && req.OrdersStatus == 1 {
		// Status changed from pending to done - add new amount to stock
		stockChange = req.OrdersAmount
	} else if oldStatus == 1 && req.OrdersStatus == 0 {
		// Status changed from done to pending - remove old amount from stock
		stockChange = -oldAmount
	} else if oldStatus == 1 && req.OrdersStatus == 1 {
		// Status stayed done, but amount changed - adjust stock by difference
		stockChange = req.OrdersAmount - oldAmount
	}
	// If oldStatus == 0 && req.OrdersStatus == 0, no stock change needed

	// Apply stock changes if needed
	if stockChange != 0 {
		var currentStock int
		err = tx.QueryRow("SELECT stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?", barangID, lantaiID).Scan(&currentStock)

		if err == sql.ErrNoRows && stockChange > 0 {
			// Create stock record if it doesn't exist and we're adding stock
			var lastStockID string
			err = tx.QueryRow("SELECT stock_id FROM stock_gudang ORDER BY stock_id DESC LIMIT 1").Scan(&lastStockID)
			if err != nil && err != sql.ErrNoRows {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error generating stock_id")
				return
			}

			nextNum := 1
			if lastStockID != "" {
				numPart := lastStockID[3:]
				n, _ := strconv.Atoi(numPart)
				nextNum = n + 1
			}
			newStockID := fmt.Sprintf("ST_%06d", nextNum)

			_, err = tx.Exec("INSERT INTO stock_gudang (stock_id, barang_id, lantai_id, stock_barang) VALUES (?, ?, ?, ?)", newStockID, barangID, lantaiID, stockChange)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error creating stock")
				return
			}
		} else if err != nil {
			tx.Rollback()
			respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error fetching stock")
			return
		} else {
			newStock := currentStock + stockChange
			if newStock < 0 {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusBadRequest, "Cannot reduce stock below zero")
				return
			}

			_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE barang_id = ? AND lantai_id = ?", newStock, barangID, lantaiID)
			if err != nil {
				tx.Rollback()
				respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error updating stock")
				return
			}
		}
	}

	if err := tx.Commit(); err != nil {
		respondWithErrorOrdersMasuk(w, http.StatusInternalServerError, "Error committing transaction")
		return
	}

	respondWithJSONOrdersMasuk(w, map[string]interface{}{
		"message":       "Order updated successfully",
		"orders_id":     ordersID,
		"orders_amount": req.OrdersAmount,
		"orders_value":  req.OrdersValue,
		"orders_status": req.OrdersStatus,
		"stock_change":  stockChange,
	})
}

// SetupOrdersInRoutes sets up all orders masuk (incoming orders) routes
func SetupOrdersInRoutes(router *mux.Router) {
	// Create batch orders masuk
	router.HandleFunc("/orders/masuk/batch", createBatchOrderMasuk).Methods("POST")

	// Get all orders masuk
	router.HandleFunc("/orders/masuk", getOrdersMasuk).Methods("GET")

	// Update orders masuk (full update)
	router.HandleFunc("/orders/masuk/{id}", updateOrdersMasuk).Methods("PUT")

	// Update orders masuk status only
	router.HandleFunc("/orders/masuk/{id}/status", updateOrdersMasukStatus).Methods("PUT")
}
