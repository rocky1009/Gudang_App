package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"src/database"
	"strconv"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

// Sales represents a sale record
type Sales struct {
	SalesID        string `json:"sales_id"`
	CustomerID     string `json:"customer_id"`
	CustomerName   string `json:"customer_name,omitempty"`
	CustomerKontak string `json:"customer_kontak,omitempty"`
	CustomerAlamat string `json:"customer_alamat,omitempty"`
	SalesTotal     int    `json:"sales_total"`
	SalesPayment   string `json:"sales_payment"`
	SalesDate      string `json:"sales_date"`
	SalesStatus    int    `json:"sales_status"`
}

// SaleItems represents individual items in a sale
type SaleItems struct {
	SaleItemsID     string `json:"sale_items_id"`
	SalesID         string `json:"sales_id"`
	BarangID        string `json:"barang_id"`
	BarangNama      string `json:"barang_nama,omitempty"`
	GudangID        string `json:"gudang_id"`
	GudangNama      string `json:"gudang_nama,omitempty"`
	LantaiID        string `json:"lantai_id"`
	LantaiNama      string `json:"lantai_nama,omitempty"`
	SaleItemsAmount int    `json:"sale_items_amount"`
	SaleValue       int    `json:"sale_value"`
}

// SalesRequest for creating sales
type SalesRequest struct {
	CustomerID   string `json:"customer_id"`
	SalesPayment string `json:"sales_payment"`
	SalesDate    string `json:"sales_date"`
	SalesStatus  int    `json:"sales_status"`
}

// SaleItemsRequest for creating sale items
type SaleItemsRequest struct {
	BarangID        string `json:"barang_id"`
	GudangID        string `json:"gudang_id"`
	LantaiID        string `json:"lantai_id"`
	SaleItemsAmount int    `json:"sale_items_amount"`
	SaleValue       int    `json:"sale_value"`
}

// CombinedSalesRequest for creating sales with items in one request
type CombinedSalesRequest struct {
	CustomerID   string             `json:"customer_id"`
	SalesPayment string             `json:"sales_payment"`
	SalesDate    string             `json:"sales_date"`
	SalesStatus  int                `json:"sales_status"`
	SaleItems    []SaleItemsRequest `json:"sale_items"`
}

// BatchSalesRequest for creating multiple sales at once
type BatchSalesRequest struct {
	CustomerID   string             `json:"customer_id"`
	SalesPayment string             `json:"sales_payment"`
	SalesDate    string             `json:"sales_date"`
	SalesStatus  int                `json:"sales_status"`
	SaleItems    []SaleItemsRequest `json:"sale_items"`
}

// SalesDetail for detailed response with items
type SalesDetail struct {
	SalesID        string      `json:"sales_id"`
	CustomerID     string      `json:"customer_id"`
	CustomerName   string      `json:"customer_name"`
	CustomerKontak string      `json:"customer_kontak"`
	CustomerAlamat string      `json:"customer_alamat"`
	SalesTotal     int         `json:"sales_total"`
	SalesPayment   string      `json:"sales_payment"`
	SalesDate      string      `json:"sales_date"`
	SalesStatus    int         `json:"sales_status"`
	SaleItems      []SaleItems `json:"sale_items"`
}

// SetupSalesRoutes registers all sales-related routes
func SetupSalesRoutes(router *mux.Router) {
	router.HandleFunc("/getsales", getSales).Methods("GET")
	router.HandleFunc("/getsale/{id}", getSalesDetail).Methods("GET")
	router.HandleFunc("/createsales", createSales).Methods("POST")
	router.HandleFunc("/createcombinedsales", createCombinedSales).Methods("POST")
	router.HandleFunc("/createbatchsales", createBatchSales).Methods("POST")
	router.HandleFunc("/updatesales/{id}", updateSales).Methods("PUT")
	router.HandleFunc("/deletesales/{id}", deleteSales).Methods("DELETE")

	// Sale Items routes
	router.HandleFunc("/getsaleitems", getSaleItems).Methods("GET")
	router.HandleFunc("/getsaleitem/{id}", getSaleItem).Methods("GET")
	router.HandleFunc("/createsaleitem", createSaleItem).Methods("POST")
	router.HandleFunc("/updatesaleitem/{id}", updateSaleItem).Methods("PUT")
	router.HandleFunc("/deletesaleitem/{id}", deleteSaleItem).Methods("DELETE")

	// Stock query route
	router.HandleFunc("/getstock/{barang_id}/{gudang_id}", getStockForBarangGudang).Methods("GET")
	router.HandleFunc("/getfloors/{gudang_id}", getFloorsByGudang).Methods("GET")
	router.HandleFunc("/getfloorstock/{barang_id}/{gudang_id}/{lantai_id}", getStockForBarangGudangLantai).Methods("GET")

	// Sales Report routes
	router.HandleFunc("/getdailyreport", getDailySalesReport).Methods("GET")
	router.HandleFunc("/getmonthlyreport", getMonthlySalesReport).Methods("GET")
	router.HandleFunc("/getyearlyreport", getYearlySalesReport).Methods("GET")

	// Item Sales Report routes
	router.HandleFunc("/getitemsalesreport", getItemSalesReport).Methods("GET")
}

// getSales retrieves all sales with customer information and sale items
func getSales(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	// Get all sales first
	salesQuery := `
		SELECT s.sales_id, s.customer_id, c.customer_nama, c.customer_kontak, c.customer_alamat,
		       s.sales_total, s.sales_payment, s.sales_date, s.sales_status
		FROM sales s
		LEFT JOIN customer c ON s.customer_id = c.customer_id
		ORDER BY s.sales_date DESC, s.sales_id DESC
	`

	rows, err := db.Query(salesQuery)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Create a map to store sales by ID
	salesMap := make(map[string]*SalesDetail)
	var salesOrder []string // To maintain order

	for rows.Next() {
		var s SalesDetail
		s.SaleItems = []SaleItems{} // Initialize empty slice
		err := rows.Scan(&s.SalesID, &s.CustomerID, &s.CustomerName, &s.CustomerKontak, &s.CustomerAlamat,
			&s.SalesTotal, &s.SalesPayment, &s.SalesDate, &s.SalesStatus)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		salesMap[s.SalesID] = &s
		salesOrder = append(salesOrder, s.SalesID)
	}

	// If no sales found, return empty array
	if len(salesMap) == 0 {
		respondWithJSON(w, []SalesDetail{})
		return
	}

	// Get all sale items for all sales in one query (more efficient)
	itemsQuery := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama,
		       si.gudang_id, g.gudang_nama, si.lantai_id, gl.lantai_nama,
		       si.sale_items_amount, si.sale_value
		FROM sale_items si
		LEFT JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN list_gudang g ON si.gudang_id = g.gudang_id
		LEFT JOIN gudang_lantai gl ON si.lantai_id = gl.lantai_id
		ORDER BY si.sales_id, si.sale_items_id
	`

	itemRows, err := db.Query(itemsQuery)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer itemRows.Close()

	// Group items by sales_id
	for itemRows.Next() {
		var item SaleItems
		var lantaiID, lantaiNama sql.NullString
		err := itemRows.Scan(&item.SaleItemsID, &item.SalesID, &item.BarangID, &item.BarangNama,
			&item.GudangID, &item.GudangNama, &lantaiID, &lantaiNama,
			&item.SaleItemsAmount, &item.SaleValue)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Handle nullable lantai fields
		if lantaiID.Valid {
			item.LantaiID = lantaiID.String
		}
		if lantaiNama.Valid {
			item.LantaiNama = lantaiNama.String
		}

		// Add item to corresponding sale
		if sale, exists := salesMap[item.SalesID]; exists {
			sale.SaleItems = append(sale.SaleItems, item)
		}
	}

	// Convert map to ordered slice
	var salesList []SalesDetail
	for _, salesID := range salesOrder {
		salesList = append(salesList, *salesMap[salesID])
	}

	respondWithJSON(w, salesList)
}

// getSalesDetail retrieves a single sale with all its items
func getSalesDetail(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	salesID := vars["id"]

	// Get sales information
	salesQuery := `
		SELECT s.sales_id, s.customer_id, c.customer_nama, c.customer_kontak, c.customer_alamat,
		       s.sales_total, s.sales_payment, s.sales_date, s.sales_status
		FROM sales s
		LEFT JOIN customer c ON s.customer_id = c.customer_id
		WHERE s.sales_id = ?
	`

	var detail SalesDetail
	err = db.QueryRow(salesQuery, salesID).Scan(
		&detail.SalesID, &detail.CustomerID, &detail.CustomerName, &detail.CustomerKontak, &detail.CustomerAlamat,
		&detail.SalesTotal, &detail.SalesPayment, &detail.SalesDate, &detail.SalesStatus,
	)

	if err == sql.ErrNoRows {
		http.Error(w, "Sales not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Get sale items
	itemsQuery := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama,
		       si.gudang_id, g.gudang_nama, si.lantai_id, gl.lantai_nama,
		       si.sale_items_amount, si.sale_value
		FROM sale_items si
		LEFT JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN list_gudang g ON si.gudang_id = g.gudang_id
		LEFT JOIN gudang_lantai gl ON si.lantai_id = gl.lantai_id
		WHERE si.sales_id = ?
		ORDER BY si.sale_items_id
	`

	rows, err := db.Query(itemsQuery, salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []SaleItems
	for rows.Next() {
		var item SaleItems
		var lantaiID, lantaiNama sql.NullString
		err := rows.Scan(&item.SaleItemsID, &item.SalesID, &item.BarangID, &item.BarangNama,
			&item.GudangID, &item.GudangNama, &lantaiID, &lantaiNama,
			&item.SaleItemsAmount, &item.SaleValue)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Handle nullable lantai fields
		if lantaiID.Valid {
			item.LantaiID = lantaiID.String
		}
		if lantaiNama.Valid {
			item.LantaiNama = lantaiNama.String
		}

		items = append(items, item)
	}

	detail.SaleItems = items
	respondWithJSON(w, detail)
}

// createSales creates a new sales record only
func createSales(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	var req SalesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validation
	if req.CustomerID == "" {
		http.Error(w, "customer_id is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment == "" {
		http.Error(w, "sales_payment is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment != "1" && req.SalesPayment != "2" && req.SalesPayment != "3" {
		http.Error(w, "sales_payment must be 1 (Tunai), 2 (Transfer), or 3 (Kredit)", http.StatusBadRequest)
		return
	}

	if req.SalesStatus != 1 && req.SalesStatus != 2 {
		http.Error(w, "sales_status must be 1 (Selesai) or 2 (Diproses)", http.StatusBadRequest)
		return
	}

	// Validate customer exists
	var customerExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM customer WHERE customer_id = ?)", req.CustomerID).Scan(&customerExists)
	if err != nil || !customerExists {
		http.Error(w, "Invalid customer_id: customer does not exist", http.StatusBadRequest)
		return
	}

	// Set default date if not provided
	if req.SalesDate == "" {
		req.SalesDate = time.Now().Format("2006-01-02")
	}

	// Generate new sales ID
	var lastID string
	err = db.QueryRow("SELECT sales_id FROM sales ORDER BY sales_id DESC LIMIT 1").Scan(&lastID)

	var newID string
	if err == sql.ErrNoRows {
		newID = "SL_0000001"
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	} else {
		lastNum, _ := strconv.Atoi(lastID[3:])
		newID = fmt.Sprintf("SL_%07d", lastNum+1)
	}

	// Insert sales with initial total of 0
	query := `INSERT INTO sales (sales_id, customer_id, sales_total, sales_payment, sales_date, sales_status) 
	          VALUES (?, ?, 0, ?, ?, ?)`

	_, err = db.Exec(query, newID, req.CustomerID, req.SalesPayment, req.SalesDate, req.SalesStatus)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"sales_id":      newID,
		"customer_id":   req.CustomerID,
		"sales_total":   0,
		"sales_payment": req.SalesPayment,
		"sales_date":    req.SalesDate,
		"sales_status":  req.SalesStatus,
		"status":        "Created",
		"message":       "Sales record created successfully",
	}

	w.WriteHeader(http.StatusCreated)
	respondWithJSON(w, response)
}

// createCombinedSales creates a sales record with items in one transaction
func createCombinedSales(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	var req CombinedSalesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validation
	if req.CustomerID == "" {
		http.Error(w, "customer_id is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment == "" {
		http.Error(w, "sales_payment is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment != "1" && req.SalesPayment != "2" && req.SalesPayment != "3" {
		http.Error(w, "sales_payment must be 1 (Tunai), 2 (Transfer), or 3 (Kredit)", http.StatusBadRequest)
		return
	}

	if req.SalesStatus != 1 && req.SalesStatus != 2 {
		http.Error(w, "sales_status must be 1 (Selesai) or 2 (Diproses)", http.StatusBadRequest)
		return
	}

	if len(req.SaleItems) == 0 {
		http.Error(w, "at least one sale item is required", http.StatusBadRequest)
		return
	}

	// Validate customer exists
	var customerExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM customer WHERE customer_id = ?)", req.CustomerID).Scan(&customerExists)
	if err != nil || !customerExists {
		http.Error(w, "Invalid customer_id: customer does not exist", http.StatusBadRequest)
		return
	}

	// Set default date if not provided
	if req.SalesDate == "" {
		req.SalesDate = time.Now().Format("2006-01-02")
	}

	// Validate all sale items before starting transaction
	for i, item := range req.SaleItems {
		if item.BarangID == "" {
			http.Error(w, fmt.Sprintf("barang_id is required for item #%d", i+1), http.StatusBadRequest)
			return
		}
		if item.GudangID == "" {
			http.Error(w, fmt.Sprintf("gudang_id is required for item #%d", i+1), http.StatusBadRequest)
			return
		}
		if item.SaleItemsAmount <= 0 {
			http.Error(w, fmt.Sprintf("sale_items_amount must be greater than 0 for item #%d", i+1), http.StatusBadRequest)
			return
		}
		if item.SaleValue <= 0 {
			http.Error(w, fmt.Sprintf("sale_value must be greater than 0 for item #%d", i+1), http.StatusBadRequest)
			return
		}

		// Validate barang exists
		var barangExists bool
		err := db.QueryRow("SELECT EXISTS(SELECT 1 FROM barang WHERE barang_id = ?)", item.BarangID).Scan(&barangExists)
		if err != nil || !barangExists {
			http.Error(w, fmt.Sprintf("Invalid barang_id for item #%d: barang does not exist", i+1), http.StatusBadRequest)
			return
		}

		// Validate gudang exists
		var gudangExists bool
		err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM list_gudang WHERE gudang_id = ?)", item.GudangID).Scan(&gudangExists)
		if err != nil || !gudangExists {
			http.Error(w, fmt.Sprintf("Invalid gudang_id for item #%d: gudang does not exist", i+1), http.StatusBadRequest)
			return
		}

		// Validate lantai exists and belongs to gudang
		if item.LantaiID != "" {
			var lantaiExists bool
			err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM gudang_lantai WHERE lantai_id = ? AND gudang_id = ?)", item.LantaiID, item.GudangID).Scan(&lantaiExists)
			if err != nil || !lantaiExists {
				http.Error(w, fmt.Sprintf("Invalid lantai_id for item #%d: lantai does not exist or does not belong to gudang", i+1), http.StatusBadRequest)
				return
			}
		}
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Generate new sales ID
	var lastSalesID string
	err = tx.QueryRow("SELECT sales_id FROM sales ORDER BY sales_id DESC LIMIT 1").Scan(&lastSalesID)

	var newSalesID string
	if err == sql.ErrNoRows {
		newSalesID = "SL_0000001"
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	} else {
		lastNum, _ := strconv.Atoi(lastSalesID[3:])
		newSalesID = fmt.Sprintf("SL_%07d", lastNum+1)
	}

	// Calculate total
	salesTotal := 0
	for _, item := range req.SaleItems {
		salesTotal += item.SaleValue * item.SaleItemsAmount
	}

	// Insert sales
	salesQuery := `INSERT INTO sales (sales_id, customer_id, sales_total, sales_payment, sales_date, sales_status) 
	               VALUES (?, ?, ?, ?, ?, ?)`

	_, err = tx.Exec(salesQuery, newSalesID, req.CustomerID, salesTotal, req.SalesPayment, req.SalesDate, req.SalesStatus)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Get last sale item ID
	var lastItemID string
	err = tx.QueryRow("SELECT sale_items_id FROM sale_items ORDER BY sale_items_id DESC LIMIT 1").Scan(&lastItemID)

	var itemIDNum int
	if err == sql.ErrNoRows {
		itemIDNum = 1
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	} else {
		itemIDNum, _ = strconv.Atoi(lastItemID[3:])
		itemIDNum++
	}

	// Insert sale items and reduce stock
	itemQuery := `INSERT INTO sale_items (sale_items_id, sales_id, barang_id, gudang_id, lantai_id, sale_items_amount, sale_value) 
	              VALUES (?, ?, ?, ?, ?, ?, ?)`

	var createdItems []SaleItems
	for _, item := range req.SaleItems {
		newItemID := fmt.Sprintf("SI_%07d", itemIDNum)

		_, err = tx.Exec(itemQuery, newItemID, newSalesID, item.BarangID, item.GudangID, item.LantaiID, item.SaleItemsAmount, item.SaleValue)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Reduce stock in stock_gudang (using lantai_id)
		var currentStock int
		var stockID string
		lantaiID := item.LantaiID
		if lantaiID == "" {
			// If no lantai specified, get first available lantai for this gudang
			err = tx.QueryRow("SELECT lantai_id FROM gudang_lantai WHERE gudang_id = ? ORDER BY lantai_no LIMIT 1", item.GudangID).Scan(&lantaiID)
			if err != nil {
				http.Error(w, fmt.Sprintf("Error finding lantai for gudang: %v", err), http.StatusInternalServerError)
				return
			}
		}
		err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND lantai_id = ?",
			item.BarangID, lantaiID).Scan(&stockID, &currentStock)

		if err == sql.ErrNoRows {
			tx.Rollback()
			http.Error(w, fmt.Sprintf("Stock not found for barang_id %s in gudang_id %s", item.BarangID, item.GudangID), http.StatusBadRequest)
			return
		} else if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		newStock := currentStock - item.SaleItemsAmount
		if newStock < 0 {
			tx.Rollback()
			http.Error(w, fmt.Sprintf("Insufficient stock for item #%d. Available: %d, Required: %d", itemIDNum-int(itemIDNum), currentStock, item.SaleItemsAmount), http.StatusBadRequest)
			return
		}

		_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", newStock, stockID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		createdItems = append(createdItems, SaleItems{
			SaleItemsID:     newItemID,
			SalesID:         newSalesID,
			BarangID:        item.BarangID,
			GudangID:        item.GudangID,
			SaleItemsAmount: item.SaleItemsAmount,
			SaleValue:       item.SaleValue,
		})

		itemIDNum++
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"sales_id":      newSalesID,
		"customer_id":   req.CustomerID,
		"sales_total":   salesTotal,
		"sales_payment": req.SalesPayment,
		"sales_date":    req.SalesDate,
		"sales_status":  req.SalesStatus,
		"sale_items":    createdItems,
		"status":        "Created",
		"message":       fmt.Sprintf("Sales with %d items created successfully", len(createdItems)),
	}

	w.WriteHeader(http.StatusCreated)
	respondWithJSON(w, response)
}

// createBatchSales creates a sales record with multiple items (alias for createCombinedSales)
func createBatchSales(w http.ResponseWriter, r *http.Request) {
	createCombinedSales(w, r)
}

// updateSales updates a sales record
func updateSales(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	salesID := vars["id"]

	var req SalesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validation
	if req.CustomerID == "" {
		http.Error(w, "customer_id is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment == "" {
		http.Error(w, "sales_payment is required", http.StatusBadRequest)
		return
	}

	if req.SalesPayment != "1" && req.SalesPayment != "2" && req.SalesPayment != "3" {
		http.Error(w, "sales_payment must be 1 (Tunai), 2 (Transfer), or 3 (Kredit)", http.StatusBadRequest)
		return
	}

	if req.SalesStatus != 1 && req.SalesStatus != 2 {
		http.Error(w, "sales_status must be 1 (Selesai) or 2 (Diproses)", http.StatusBadRequest)
		return
	}

	// Validate customer exists
	var customerExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM customer WHERE customer_id = ?)", req.CustomerID).Scan(&customerExists)
	if err != nil || !customerExists {
		http.Error(w, "Invalid customer_id: customer does not exist", http.StatusBadRequest)
		return
	}

	if req.SalesDate == "" {
		req.SalesDate = time.Now().Format("2006-01-02")
	}

	// Recalculate total from sale items
	var salesTotal int
	err = db.QueryRow(`
		SELECT COALESCE(SUM(sale_items_amount * sale_value), 0) 
		FROM sale_items 
		WHERE sales_id = ?
	`, salesID).Scan(&salesTotal)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update sales
	query := `UPDATE sales 
	          SET customer_id = ?, sales_total = ?, sales_payment = ?, sales_date = ?, sales_status = ?
	          WHERE sales_id = ?`

	result, err := db.Exec(query, req.CustomerID, salesTotal, req.SalesPayment, req.SalesDate, req.SalesStatus, salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Sales not found", http.StatusNotFound)
		return
	}

	response := map[string]interface{}{
		"sales_id":      salesID,
		"customer_id":   req.CustomerID,
		"sales_total":   salesTotal,
		"sales_payment": req.SalesPayment,
		"sales_date":    req.SalesDate,
		"sales_status":  req.SalesStatus,
		"status":        "Updated",
		"message":       "Sales updated successfully",
	}

	respondWithJSON(w, response)
}

// deleteSales deletes a sales record and all its items
func deleteSales(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	salesID := vars["id"]

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Get all sale items to restore stock before deletion
	itemsQuery := `SELECT barang_id, gudang_id, sale_items_amount FROM sale_items WHERE sales_id = ?`
	rows, err := tx.Query(itemsQuery, salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Restore stock for each item
	for rows.Next() {
		var barangID, gudangID string
		var amount int
		if err := rows.Scan(&barangID, &gudangID, &amount); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		var stockID string
		var currentStock int
		err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND gudang_id = ?",
			barangID, gudangID).Scan(&stockID, &currentStock)

		if err != nil && err != sql.ErrNoRows {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if err != sql.ErrNoRows {
			_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", currentStock+amount, stockID)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
		}
	}

	// Delete sale items first (due to foreign key constraint)
	_, err = tx.Exec("DELETE FROM sale_items WHERE sales_id = ?", salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Delete sales
	result, err := tx.Exec("DELETE FROM sales WHERE sales_id = ?", salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Sales not found", http.StatusNotFound)
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"status":  "Deleted",
		"message": "Sales and all related items deleted successfully",
	}

	respondWithJSON(w, response)
}

// getSaleItems retrieves all sale items
func getSaleItems(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	query := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama,
		       si.gudang_id, g.gudang_nama, si.lantai_id, gl.lantai_nama,
		       si.sale_items_amount, si.sale_value
		FROM sale_items si
		LEFT JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN list_gudang g ON si.gudang_id = g.gudang_id
		LEFT JOIN gudang_lantai gl ON si.lantai_id = gl.lantai_id
		ORDER BY si.sale_items_id DESC
	`

	rows, err := db.Query(query)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []SaleItems
	for rows.Next() {
		var item SaleItems
		var lantaiID, lantaiNama sql.NullString
		err := rows.Scan(&item.SaleItemsID, &item.SalesID, &item.BarangID, &item.BarangNama,
			&item.GudangID, &item.GudangNama, &lantaiID, &lantaiNama,
			&item.SaleItemsAmount, &item.SaleValue)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Handle nullable lantai fields
		if lantaiID.Valid {
			item.LantaiID = lantaiID.String
		}
		if lantaiNama.Valid {
			item.LantaiNama = lantaiNama.String
		}

		items = append(items, item)
	}

	respondWithJSON(w, items)
}

// getSaleItem retrieves a single sale item
func getSaleItem(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	itemID := vars["id"]

	query := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama,
		       si.gudang_id, g.gudang_nama, si.lantai_id, gl.lantai_nama,
		       si.sale_items_amount, si.sale_value
		FROM sale_items si
		LEFT JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN list_gudang g ON si.gudang_id = g.gudang_id
		LEFT JOIN gudang_lantai gl ON si.lantai_id = gl.lantai_id
		WHERE si.sale_items_id = ?
	`

	var item SaleItems
	var lantaiID, lantaiNama sql.NullString
	err = db.QueryRow(query, itemID).Scan(
		&item.SaleItemsID, &item.SalesID, &item.BarangID, &item.BarangNama,
		&item.GudangID, &item.GudangNama, &lantaiID, &lantaiNama,
		&item.SaleItemsAmount, &item.SaleValue,
	)

	if err == sql.ErrNoRows {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Handle nullable lantai fields
	if lantaiID.Valid {
		item.LantaiID = lantaiID.String
	}
	if lantaiNama.Valid {
		item.LantaiNama = lantaiNama.String
	}

	respondWithJSON(w, item)
}

// createSaleItem creates a new sale item for an existing sales record
func createSaleItem(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	var req struct {
		SalesID         string `json:"sales_id"`
		BarangID        string `json:"barang_id"`
		GudangID        string `json:"gudang_id"`
		SaleItemsAmount int    `json:"sale_items_amount"`
		SaleValue       int    `json:"sale_value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validation
	if req.SalesID == "" {
		http.Error(w, "sales_id is required", http.StatusBadRequest)
		return
	}

	if req.BarangID == "" {
		http.Error(w, "barang_id is required", http.StatusBadRequest)
		return
	}

	if req.GudangID == "" {
		http.Error(w, "gudang_id is required", http.StatusBadRequest)
		return
	}

	if req.SaleItemsAmount <= 0 {
		http.Error(w, "sale_items_amount must be greater than 0", http.StatusBadRequest)
		return
	}

	if req.SaleValue <= 0 {
		http.Error(w, "sale_value must be greater than 0", http.StatusBadRequest)
		return
	}

	// Validate sales exists
	var salesExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM sales WHERE sales_id = ?)", req.SalesID).Scan(&salesExists)
	if err != nil || !salesExists {
		http.Error(w, "Invalid sales_id: sales does not exist", http.StatusBadRequest)
		return
	}

	// Validate barang exists
	var barangExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM barang WHERE barang_id = ?)", req.BarangID).Scan(&barangExists)
	if err != nil || !barangExists {
		http.Error(w, "Invalid barang_id: barang does not exist", http.StatusBadRequest)
		return
	}

	// Validate gudang exists
	var gudangExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM list_gudang WHERE gudang_id = ?)", req.GudangID).Scan(&gudangExists)
	if err != nil || !gudangExists {
		http.Error(w, "Invalid gudang_id: gudang does not exist", http.StatusBadRequest)
		return
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Generate new sale item ID
	var lastID string
	err = tx.QueryRow("SELECT sale_items_id FROM sale_items ORDER BY sale_items_id DESC LIMIT 1").Scan(&lastID)

	var newID string
	if err == sql.ErrNoRows {
		newID = "SI_0000001"
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	} else {
		lastNum, _ := strconv.Atoi(lastID[3:])
		newID = fmt.Sprintf("SI_%07d", lastNum+1)
	}

	// Check and reduce stock
	var currentStock int
	var stockID string
	err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND gudang_id = ?",
		req.BarangID, req.GudangID).Scan(&stockID, &currentStock)

	if err == sql.ErrNoRows {
		tx.Rollback()
		http.Error(w, fmt.Sprintf("Stock not found for barang_id %s in gudang_id %s", req.BarangID, req.GudangID), http.StatusBadRequest)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	newStock := currentStock - req.SaleItemsAmount
	if newStock < 0 {
		tx.Rollback()
		http.Error(w, fmt.Sprintf("Insufficient stock. Available: %d, Required: %d", currentStock, req.SaleItemsAmount), http.StatusBadRequest)
		return
	}

	_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", newStock, stockID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Insert sale item
	itemQuery := `INSERT INTO sale_items (sale_items_id, sales_id, barang_id, gudang_id, sale_items_amount, sale_value) 
	              VALUES (?, ?, ?, ?, ?, ?)`

	_, err = tx.Exec(itemQuery, newID, req.SalesID, req.BarangID, req.GudangID, req.SaleItemsAmount, req.SaleValue)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update sales total
	var newTotal int
	err = tx.QueryRow(`
		SELECT COALESCE(SUM(sale_items_amount * sale_value), 0) 
		FROM sale_items 
		WHERE sales_id = ?
	`, req.SalesID).Scan(&newTotal)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec("UPDATE sales SET sales_total = ? WHERE sales_id = ?", newTotal, req.SalesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"sale_items_id":     newID,
		"sales_id":          req.SalesID,
		"barang_id":         req.BarangID,
		"gudang_id":         req.GudangID,
		"sale_items_amount": req.SaleItemsAmount,
		"sale_value":        req.SaleValue,
		"status":            "Created",
		"message":           "Sale item created successfully",
	}

	w.WriteHeader(http.StatusCreated)
	respondWithJSON(w, response)
}

// updateSaleItem updates a sale item
func updateSaleItem(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	itemID := vars["id"]

	var req struct {
		BarangID        string `json:"barang_id"`
		GudangID        string `json:"gudang_id"`
		SaleItemsAmount int    `json:"sale_items_amount"`
		SaleValue       int    `json:"sale_value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validation
	if req.BarangID == "" {
		http.Error(w, "barang_id is required", http.StatusBadRequest)
		return
	}

	if req.GudangID == "" {
		http.Error(w, "gudang_id is required", http.StatusBadRequest)
		return
	}

	if req.SaleItemsAmount <= 0 {
		http.Error(w, "sale_items_amount must be greater than 0", http.StatusBadRequest)
		return
	}

	if req.SaleValue <= 0 {
		http.Error(w, "sale_value must be greater than 0", http.StatusBadRequest)
		return
	}

	// Validate barang exists
	var barangExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM barang WHERE barang_id = ?)", req.BarangID).Scan(&barangExists)
	if err != nil || !barangExists {
		http.Error(w, "Invalid barang_id: barang does not exist", http.StatusBadRequest)
		return
	}

	// Validate gudang exists
	var gudangExists bool
	err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM list_gudang WHERE gudang_id = ?)", req.GudangID).Scan(&gudangExists)
	if err != nil || !gudangExists {
		http.Error(w, "Invalid gudang_id: gudang does not exist", http.StatusBadRequest)
		return
	}

	// Get sales_id for this item
	var salesID string
	err = db.QueryRow("SELECT sales_id FROM sale_items WHERE sale_items_id = ?", itemID).Scan(&salesID)
	if err == sql.ErrNoRows {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Get old sale item data to restore stock
	var oldBarangID, oldGudangID string
	var oldAmount int
	err = tx.QueryRow("SELECT barang_id, gudang_id, sale_items_amount FROM sale_items WHERE sale_items_id = ?", itemID).Scan(&oldBarangID, &oldGudangID, &oldAmount)
	if err == sql.ErrNoRows {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Restore old stock (add back the old amount)
	var oldStockID string
	var oldCurrentStock int
	err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND gudang_id = ?",
		oldBarangID, oldGudangID).Scan(&oldStockID, &oldCurrentStock)

	if err != nil && err != sql.ErrNoRows {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err != sql.ErrNoRows {
		_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", oldCurrentStock+oldAmount, oldStockID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	// Check and reduce new stock
	var newStockID string
	var newCurrentStock int
	err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND gudang_id = ?",
		req.BarangID, req.GudangID).Scan(&newStockID, &newCurrentStock)

	if err == sql.ErrNoRows {
		tx.Rollback()
		http.Error(w, fmt.Sprintf("Stock not found for barang_id %s in gudang_id %s", req.BarangID, req.GudangID), http.StatusBadRequest)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	newStock := newCurrentStock - req.SaleItemsAmount
	if newStock < 0 {
		tx.Rollback()
		http.Error(w, fmt.Sprintf("Insufficient stock. Available: %d, Required: %d", newCurrentStock, req.SaleItemsAmount), http.StatusBadRequest)
		return
	}

	_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", newStock, newStockID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update sale item
	query := `UPDATE sale_items 
	          SET barang_id = ?, gudang_id = ?, sale_items_amount = ?, sale_value = ?
	          WHERE sale_items_id = ?`

	result, err := tx.Exec(query, req.BarangID, req.GudangID, req.SaleItemsAmount, req.SaleValue, itemID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	}

	// Update sales total
	var newTotal int
	err = tx.QueryRow(`
		SELECT COALESCE(SUM(sale_items_amount * sale_value), 0) 
		FROM sale_items 
		WHERE sales_id = ?
	`, salesID).Scan(&newTotal)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec("UPDATE sales SET sales_total = ? WHERE sales_id = ?", newTotal, salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"sale_items_id":     itemID,
		"barang_id":         req.BarangID,
		"gudang_id":         req.GudangID,
		"sale_items_amount": req.SaleItemsAmount,
		"sale_value":        req.SaleValue,
		"status":            "Updated",
		"message":           "Sale item updated successfully",
	}

	respondWithJSON(w, response)
}

// deleteSaleItem deletes a sale item and updates sales total
func deleteSaleItem(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	itemID := vars["id"]

	// Get sales_id for this item
	var salesID string
	err = db.QueryRow("SELECT sales_id FROM sale_items WHERE sale_items_id = ?", itemID).Scan(&salesID)
	if err == sql.ErrNoRows {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Get sale item data before deletion to restore stock
	var barangID, gudangID string
	var amount int
	err = tx.QueryRow("SELECT barang_id, gudang_id, sale_items_amount FROM sale_items WHERE sale_items_id = ?", itemID).Scan(&barangID, &gudangID, &amount)
	if err == sql.ErrNoRows {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Restore stock (add back the sold amount)
	var stockID string
	var currentStock int
	err = tx.QueryRow("SELECT stock_id, stock_barang FROM stock_gudang WHERE barang_id = ? AND gudang_id = ?",
		barangID, gudangID).Scan(&stockID, &currentStock)

	if err != nil && err != sql.ErrNoRows {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err != sql.ErrNoRows {
		_, err = tx.Exec("UPDATE stock_gudang SET stock_barang = ? WHERE stock_id = ?", currentStock+amount, stockID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	// Delete sale item
	result, err := tx.Exec("DELETE FROM sale_items WHERE sale_items_id = ?", itemID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Sale item not found", http.StatusNotFound)
		return
	}

	// Update sales total
	var newTotal int
	err = tx.QueryRow(`
		SELECT COALESCE(SUM(sale_items_amount * sale_value), 0) 
		FROM sale_items 
		WHERE sales_id = ?
	`, salesID).Scan(&newTotal)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = tx.Exec("UPDATE sales SET sales_total = ? WHERE sales_id = ?", newTotal, salesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"status":  "Deleted",
		"message": "Sale item deleted successfully and sales total updated",
	}

	respondWithJSON(w, response)
}

// getStockForBarangGudang retrieves stock information for a specific item in a specific warehouse
func getStockForBarangGudang(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	barangID := vars["barang_id"]
	gudangID := vars["gudang_id"]

	var stockID string
	var stockAmount int
	err = db.QueryRow(`
		SELECT stock_id, stock_barang 
		FROM stock_gudang 
		WHERE barang_id = ? AND gudang_id = ?
	`, barangID, gudangID).Scan(&stockID, &stockAmount)

	if err == sql.ErrNoRows {
		// No stock record found, return 0
		response := map[string]interface{}{
			"barang_id":    barangID,
			"gudang_id":    gudangID,
			"stock_barang": 0,
			"found":        false,
		}
		respondWithJSON(w, response)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"stock_id":     stockID,
		"barang_id":    barangID,
		"gudang_id":    gudangID,
		"stock_barang": stockAmount,
		"found":        true,
	}

	respondWithJSON(w, response)
}

// getFloorsByGudang retrieves all floors for a specific warehouse with stock information
func getFloorsByGudang(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	gudangID := vars["gudang_id"]

	query := `
		SELECT gl.lantai_id, gl.lantai_no, gl.lantai_nama, gl.gudang_id
		FROM gudang_lantai gl
		WHERE gl.gudang_id = ?
		ORDER BY gl.lantai_no
	`

	rows, err := db.Query(query, gudangID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type FloorInfo struct {
		LantaiID   string `json:"lantai_id"`
		LantaiNo   int    `json:"lantai_no"`
		LantaiNama string `json:"lantai_nama"`
		GudangID   string `json:"gudang_id"`
	}

	var floors []FloorInfo
	for rows.Next() {
		var floor FloorInfo
		err := rows.Scan(&floor.LantaiID, &floor.LantaiNo, &floor.LantaiNama, &floor.GudangID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		floors = append(floors, floor)
	}

	respondWithJSON(w, floors)
}

// getStockForBarangGudangLantai retrieves stock information for a specific item in a specific warehouse floor
func getStockForBarangGudangLantai(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	vars := mux.Vars(r)
	barangID := vars["barang_id"]
	gudangID := vars["gudang_id"]
	lantaiID := vars["lantai_id"]

	// First verify that the lantai belongs to the gudang
	var lantaiExists bool
	err = db.QueryRow(`
		SELECT EXISTS(SELECT 1 FROM gudang_lantai WHERE lantai_id = ? AND gudang_id = ?)
	`, lantaiID, gudangID).Scan(&lantaiExists)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if !lantaiExists {
		http.Error(w, "Lantai does not belong to the specified gudang", http.StatusBadRequest)
		return
	}

	var stockID string
	var stockAmount int
	err = db.QueryRow(`
		SELECT stock_id, stock_barang 
		FROM stock_gudang 
		WHERE barang_id = ? AND lantai_id = ?
	`, barangID, lantaiID).Scan(&stockID, &stockAmount)

	if err == sql.ErrNoRows {
		// No stock record found, return 0
		response := map[string]interface{}{
			"barang_id":    barangID,
			"gudang_id":    gudangID,
			"lantai_id":    lantaiID,
			"stock_barang": 0,
			"found":        false,
		}
		respondWithJSON(w, response)
		return
	} else if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"stock_id":     stockID,
		"barang_id":    barangID,
		"gudang_id":    gudangID,
		"lantai_id":    lantaiID,
		"stock_barang": stockAmount,
		"found":        true,
	}

	respondWithJSON(w, response)
}

// SaleItemReport represents a sale item with profit calculation
type SaleItemReport struct {
	SaleItemsID     string `json:"sale_items_id"`
	BarangID        string `json:"barang_id"`
	BarangNama      string `json:"barang_nama"`
	BrandID         string `json:"brand_id"`
	BrandNama       string `json:"brand_nama"`
	SaleItemsAmount int    `json:"sale_items_amount"`
	SaleValue       int    `json:"sale_value"`
	BarangHargaAsli int    `json:"barang_harga_asli"`
	ItemProfit      int    `json:"item_profit"`
}

// SalesReportDetail represents a complete sales transaction with profit
type SalesReportDetail struct {
	SalesID        string           `json:"sales_id"`
	SalesDate      string           `json:"sales_date"`
	SalesTotal     int              `json:"sales_total"`
	SalesPayment   string           `json:"sales_payment"`
	SalesStatus    int              `json:"sales_status"`
	CustomerID     string           `json:"customer_id"`
	CustomerName   string           `json:"customer_name"`
	CustomerKontak string           `json:"customer_kontak"`
	CustomerAlamat string           `json:"customer_alamat"`
	SaleItems      []SaleItemReport `json:"sale_items"`
	TotalProfit    int              `json:"total_profit"`
}

// MonthlyReportSummary represents monthly report summary
type MonthlyReportSummary struct {
	Month             string              `json:"month"`
	TotalTransactions int                 `json:"total_transactions"`
	TotalSales        int                 `json:"total_sales"`
	TotalProfit       int                 `json:"total_profit"`
	Transactions      []SalesReportDetail `json:"transactions"`
}

// YearlyReportSummary represents yearly summary by month
type YearlyReportSummary struct {
	Month             string `json:"month"`
	TotalTransactions int    `json:"total_transactions"`
	TotalSales        int    `json:"total_sales"`
	TotalProfit       int    `json:"total_profit"`
}

// DailyReportSummary represents daily report summary
type DailyReportSummary struct {
	Date              string              `json:"date"`
	TotalTransactions int                 `json:"total_transactions"`
	TotalSales        int                 `json:"total_sales"`
	TotalProfit       int                 `json:"total_profit"`
	Transactions      []SalesReportDetail `json:"transactions"`
}

// YearlyDetailSummary represents full yearly summary with all transactions
type YearlyDetailSummary struct {
	Year              string              `json:"year"`
	TotalTransactions int                 `json:"total_transactions"`
	TotalSales        int                 `json:"total_sales"`
	TotalProfit       int                 `json:"total_profit"`
	Transactions      []SalesReportDetail `json:"transactions"`
}

// ItemSalesStats represents sales statistics for a single item
type ItemSalesStats struct {
	BarangID          string  `json:"barang_id"`
	BarangNama        string  `json:"barang_nama"`
	BrandNama         string  `json:"brand_nama"`
	BarangHargaJual   int     `json:"barang_harga_jual"`
	TransactionCount  int     `json:"transaction_count"`
	TotalQuantitySold int     `json:"total_quantity_sold"`
	TotalRevenue      int     `json:"total_revenue"`
	AvgSalePrice      float64 `json:"avg_sale_price"`
}

// ItemSalesReportResponse represents the response for item sales report
type ItemSalesReportResponse struct {
	Period     string           `json:"period"`
	Date       string           `json:"date"`
	Items      []ItemSalesStats `json:"items"`
	TotalItems int              `json:"total_items"`
}

// getDailySalesReport retrieves sales report for a specific date with profit calculation
// Query params: date (format: YYYY-MM-DD, e.g., 2025-10-16)
func getDailySalesReport(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	// Get date parameter from query string
	date := r.URL.Query().Get("date")
	if date == "" {
		http.Error(w, "date parameter is required (format: YYYY-MM-DD)", http.StatusBadRequest)
		return
	}

	// Query to get all sales for the specified date
	salesQuery := `
		SELECT DISTINCT s.sales_id, s.sales_date, s.sales_total, s.sales_payment, s.sales_status,
		       s.customer_id, c.customer_nama, c.customer_kontak, c.customer_alamat
		FROM sales s
		LEFT JOIN customer c ON s.customer_id = c.customer_id
		WHERE DATE(s.sales_date) = ?
		ORDER BY s.sales_id DESC
	`

	rows, err := db.Query(salesQuery, date)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var transactions []SalesReportDetail

	// Collect all sales
	for rows.Next() {
		var trans SalesReportDetail
		err := rows.Scan(&trans.SalesID, &trans.SalesDate, &trans.SalesTotal, &trans.SalesPayment,
			&trans.SalesStatus, &trans.CustomerID, &trans.CustomerName, &trans.CustomerKontak, &trans.CustomerAlamat)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		trans.SaleItems = []SaleItemReport{}
		trans.TotalProfit = 0
		transactions = append(transactions, trans)
	}

	if len(transactions) == 0 {
		response := DailyReportSummary{
			Date:              date,
			TotalTransactions: 0,
			TotalSales:        0,
			TotalProfit:       0,
			Transactions:      []SalesReportDetail{},
		}
		respondWithJSON(w, response)
		return
	}

	// Query to get all sale items with profit calculation
	itemsQuery := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama, 
		       b.brand_id, br.brand_nama, si.sale_items_amount, si.sale_value,
		       b.barang_harga_asli,
		       ((si.sale_value - b.barang_harga_asli) * si.sale_items_amount) as item_profit
		FROM sale_items si
		JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		JOIN sales s ON si.sales_id = s.sales_id
		WHERE DATE(s.sales_date) = ?
		ORDER BY si.sales_id, si.sale_items_id
	`

	itemRows, err := db.Query(itemsQuery, date)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer itemRows.Close()

	// Create a map for quick lookup
	transMap := make(map[string]*SalesReportDetail)
	for i := range transactions {
		transMap[transactions[i].SalesID] = &transactions[i]
	}

	// Add items to their respective sales and calculate profit
	for itemRows.Next() {
		var item SaleItemReport
		var salesID string
		err := itemRows.Scan(&item.SaleItemsID, &salesID, &item.BarangID, &item.BarangNama,
			&item.BrandID, &item.BrandNama, &item.SaleItemsAmount, &item.SaleValue,
			&item.BarangHargaAsli, &item.ItemProfit)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if trans, exists := transMap[salesID]; exists {
			trans.SaleItems = append(trans.SaleItems, item)
			trans.TotalProfit += item.ItemProfit
		}
	}

	// Calculate summary
	totalSales := 0
	totalProfit := 0
	for i := range transactions {
		totalSales += transactions[i].SalesTotal
		totalProfit += transactions[i].TotalProfit
	}

	response := DailyReportSummary{
		Date:              date,
		TotalTransactions: len(transactions),
		TotalSales:        totalSales,
		TotalProfit:       totalProfit,
		Transactions:      transactions,
	}

	respondWithJSON(w, response)
}

// getMonthlySalesReport retrieves sales report for a specific month with profit calculation
// Query params: month (format: YYYY-MM, e.g., 2025-10)
func getMonthlySalesReport(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	// Get month parameter from query string
	month := r.URL.Query().Get("month")
	if month == "" {
		http.Error(w, "month parameter is required (format: YYYY-MM)", http.StatusBadRequest)
		return
	}

	// Query to get all sales for the specified month
	salesQuery := `
		SELECT DISTINCT s.sales_id, s.sales_date, s.sales_total, s.sales_payment, s.sales_status,
		       s.customer_id, c.customer_nama, c.customer_kontak, c.customer_alamat
		FROM sales s
		LEFT JOIN customer c ON s.customer_id = c.customer_id
		WHERE DATE_FORMAT(s.sales_date, '%Y-%m') = ?
		ORDER BY s.sales_date DESC, s.sales_id DESC
	`

	rows, err := db.Query(salesQuery, month)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var transactions []SalesReportDetail

	// Collect all sales
	for rows.Next() {
		var trans SalesReportDetail
		err := rows.Scan(&trans.SalesID, &trans.SalesDate, &trans.SalesTotal, &trans.SalesPayment,
			&trans.SalesStatus, &trans.CustomerID, &trans.CustomerName, &trans.CustomerKontak, &trans.CustomerAlamat)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		trans.SaleItems = []SaleItemReport{}
		trans.TotalProfit = 0
		transactions = append(transactions, trans)
	}

	if len(transactions) == 0 {
		response := MonthlyReportSummary{
			Month:             month,
			TotalTransactions: 0,
			TotalSales:        0,
			TotalProfit:       0,
			Transactions:      []SalesReportDetail{},
		}
		respondWithJSON(w, response)
		return
	}

	// Query to get all sale items with profit calculation
	itemsQuery := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama, 
		       b.brand_id, br.brand_nama, si.sale_items_amount, si.sale_value,
		       b.barang_harga_asli,
		       ((si.sale_value - b.barang_harga_asli) * si.sale_items_amount) as item_profit
		FROM sale_items si
		JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		JOIN sales s ON si.sales_id = s.sales_id
		WHERE DATE_FORMAT(s.sales_date, '%Y-%m') = ?
		ORDER BY si.sales_id, si.sale_items_id
	`

	itemRows, err := db.Query(itemsQuery, month)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer itemRows.Close()

	// Create a map for quick lookup
	transMap := make(map[string]*SalesReportDetail)
	for i := range transactions {
		transMap[transactions[i].SalesID] = &transactions[i]
	}

	// Add items to their respective sales and calculate profit
	for itemRows.Next() {
		var item SaleItemReport
		var salesID string
		err := itemRows.Scan(&item.SaleItemsID, &salesID, &item.BarangID, &item.BarangNama,
			&item.BrandID, &item.BrandNama, &item.SaleItemsAmount, &item.SaleValue,
			&item.BarangHargaAsli, &item.ItemProfit)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if trans, exists := transMap[salesID]; exists {
			trans.SaleItems = append(trans.SaleItems, item)
			trans.TotalProfit += item.ItemProfit
		}
	}

	// Calculate summary
	totalSales := 0
	totalProfit := 0
	for i := range transactions {
		totalSales += transactions[i].SalesTotal
		totalProfit += transactions[i].TotalProfit
	}

	response := MonthlyReportSummary{
		Month:             month,
		TotalTransactions: len(transactions),
		TotalSales:        totalSales,
		TotalProfit:       totalProfit,
		Transactions:      transactions,
	}

	respondWithJSON(w, response)
}

// getYearlySalesReport retrieves yearly sales report grouped by month
// Query params: year (format: YYYY, e.g., 2025)
// Optional param: detailed=true to get all transactions instead of just summary
func getYearlySalesReport(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	// Get year parameter from query string
	year := r.URL.Query().Get("year")
	if year == "" {
		http.Error(w, "year parameter is required (format: YYYY)", http.StatusBadRequest)
		return
	}

	// Check if detailed report is requested
	detailed := r.URL.Query().Get("detailed") == "true"

	if detailed {
		// Return detailed report with all transactions
		getDetailedYearlyReport(w, r, db, year)
		return
	}

	// Query to get yearly summary grouped by month
	query := `
		SELECT 
			DATE_FORMAT(s.sales_date, '%Y-%m') as month,
			COUNT(DISTINCT s.sales_id) as total_transactions,
			SUM(s.sales_total) as total_sales,
			SUM((si.sale_value - b.barang_harga_asli) * si.sale_items_amount) as total_profit
		FROM sales s
		JOIN sale_items si ON s.sales_id = si.sales_id
		JOIN barang b ON si.barang_id = b.barang_id
		WHERE YEAR(s.sales_date) = ?
		GROUP BY DATE_FORMAT(s.sales_date, '%Y-%m')
		ORDER BY month DESC
	`

	rows, err := db.Query(query, year)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var monthlySummaries []YearlyReportSummary
	yearTotalTransactions := 0
	yearTotalSales := 0
	yearTotalProfit := 0

	for rows.Next() {
		var summary YearlyReportSummary
		err := rows.Scan(&summary.Month, &summary.TotalTransactions, &summary.TotalSales, &summary.TotalProfit)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		monthlySummaries = append(monthlySummaries, summary)
		yearTotalTransactions += summary.TotalTransactions
		yearTotalSales += summary.TotalSales
		yearTotalProfit += summary.TotalProfit
	}

	response := map[string]interface{}{
		"year":               year,
		"total_transactions": yearTotalTransactions,
		"total_sales":        yearTotalSales,
		"total_profit":       yearTotalProfit,
		"monthly_summaries":  monthlySummaries,
	}

	respondWithJSON(w, response)
}

// getDetailedYearlyReport retrieves detailed yearly report with all transactions
func getDetailedYearlyReport(w http.ResponseWriter, r *http.Request, db *sql.DB, year string) {
	// Query to get all sales for the specified year
	salesQuery := `
		SELECT DISTINCT s.sales_id, s.sales_date, s.sales_total, s.sales_payment, s.sales_status,
		       s.customer_id, c.customer_nama, c.customer_kontak, c.customer_alamat
		FROM sales s
		LEFT JOIN customer c ON s.customer_id = c.customer_id
		WHERE YEAR(s.sales_date) = ?
		ORDER BY s.sales_date DESC, s.sales_id DESC
	`

	rows, err := db.Query(salesQuery, year)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var transactions []SalesReportDetail

	// Collect all sales
	for rows.Next() {
		var trans SalesReportDetail
		err := rows.Scan(&trans.SalesID, &trans.SalesDate, &trans.SalesTotal, &trans.SalesPayment,
			&trans.SalesStatus, &trans.CustomerID, &trans.CustomerName, &trans.CustomerKontak, &trans.CustomerAlamat)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		trans.SaleItems = []SaleItemReport{}
		trans.TotalProfit = 0
		transactions = append(transactions, trans)
	}

	if len(transactions) == 0 {
		response := YearlyDetailSummary{
			Year:              year,
			TotalTransactions: 0,
			TotalSales:        0,
			TotalProfit:       0,
			Transactions:      []SalesReportDetail{},
		}
		respondWithJSON(w, response)
		return
	}

	// Query to get all sale items with profit calculation
	itemsQuery := `
		SELECT si.sale_items_id, si.sales_id, si.barang_id, b.barang_nama, 
		       b.brand_id, br.brand_nama, si.sale_items_amount, si.sale_value,
		       b.barang_harga_asli,
		       ((si.sale_value - b.barang_harga_asli) * si.sale_items_amount) as item_profit
		FROM sale_items si
		JOIN barang b ON si.barang_id = b.barang_id
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		JOIN sales s ON si.sales_id = s.sales_id
		WHERE YEAR(s.sales_date) = ?
		ORDER BY si.sales_id, si.sale_items_id
	`

	itemRows, err := db.Query(itemsQuery, year)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer itemRows.Close()

	// Create a map for quick lookup
	transMap := make(map[string]*SalesReportDetail)
	for i := range transactions {
		transMap[transactions[i].SalesID] = &transactions[i]
	}

	// Add items to their respective sales and calculate profit
	for itemRows.Next() {
		var item SaleItemReport
		var salesID string
		err := itemRows.Scan(&item.SaleItemsID, &salesID, &item.BarangID, &item.BarangNama,
			&item.BrandID, &item.BrandNama, &item.SaleItemsAmount, &item.SaleValue,
			&item.BarangHargaAsli, &item.ItemProfit)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if trans, exists := transMap[salesID]; exists {
			trans.SaleItems = append(trans.SaleItems, item)
			trans.TotalProfit += item.ItemProfit
		}
	}

	// Calculate summary
	totalSales := 0
	totalProfit := 0
	for i := range transactions {
		totalSales += transactions[i].SalesTotal
		totalProfit += transactions[i].TotalProfit
	}

	response := YearlyDetailSummary{
		Year:              year,
		TotalTransactions: len(transactions),
		TotalSales:        totalSales,
		TotalProfit:       totalProfit,
		Transactions:      transactions,
	}

	respondWithJSON(w, response)
}

// getItemSalesReport retrieves sales statistics for items based on period (daily, monthly, yearly)
// Query params:
// - period: "daily", "monthly", or "yearly" (required)
// - date: date string in format YYYY-MM-DD (daily), YYYY-MM (monthly), or YYYY (yearly) (required)
// - limit: maximum number of items to return (optional, default: all items)
// - order: "top" for best sellers or "bottom" for worst sellers (optional, default: "top")
func getItemSalesReport(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer db.Close()

	// Get query parameters
	period := r.URL.Query().Get("period")
	date := r.URL.Query().Get("date")
	limitStr := r.URL.Query().Get("limit")
	order := r.URL.Query().Get("order")

	// Validate period
	if period == "" {
		http.Error(w, "period parameter is required (daily, monthly, or yearly)", http.StatusBadRequest)
		return
	}

	if period != "daily" && period != "monthly" && period != "yearly" {
		http.Error(w, "period must be 'daily', 'monthly', or 'yearly'", http.StatusBadRequest)
		return
	}

	// Validate date
	if date == "" {
		http.Error(w, "date parameter is required", http.StatusBadRequest)
		return
	}

	// Set default order
	if order == "" {
		order = "top"
	}

	if order != "top" && order != "bottom" {
		http.Error(w, "order must be 'top' or 'bottom'", http.StatusBadRequest)
		return
	}

	// Build query based on period
	var query string
	var args []interface{}

	baseQuery := `
		SELECT 
			b.barang_id,
			b.barang_nama,
			COALESCE(br.brand_nama, '') as brand_nama,
			b.barang_harga_jual,
			COUNT(DISTINCT s.sales_id) as transaction_count,
			COALESCE(SUM(si.sale_items_amount), 0) as total_quantity_sold,
			COALESCE(SUM(si.sale_items_amount * si.sale_value), 0) as total_revenue,
			COALESCE(AVG(si.sale_value), 0) as avg_sale_price
		FROM barang b
		LEFT JOIN brand br ON b.brand_id = br.brand_id
		LEFT JOIN sale_items si ON b.barang_id = si.barang_id
		LEFT JOIN sales s ON si.sales_id = s.sales_id AND s.sales_status = 1
	`

	switch period {
	case "daily":
		query = baseQuery + `
		WHERE s.sales_date IS NULL OR DATE(s.sales_date) = ?
		GROUP BY b.barang_id, b.barang_nama, br.brand_nama, b.barang_harga_jual
		`
		args = append(args, date)

	case "monthly":
		query = baseQuery + `
		WHERE s.sales_date IS NULL OR DATE_FORMAT(s.sales_date, '%Y-%m') = ?
		GROUP BY b.barang_id, b.barang_nama, br.brand_nama, b.barang_harga_jual
		`
		args = append(args, date)

	case "yearly":
		query = baseQuery + `
		WHERE s.sales_date IS NULL OR YEAR(s.sales_date) = ?
		GROUP BY b.barang_id, b.barang_nama, br.brand_nama, b.barang_harga_jual
		`
		args = append(args, date)
	}

	// Add ordering
	if order == "top" {
		query += `ORDER BY total_quantity_sold DESC, total_revenue DESC`
	} else {
		query += `ORDER BY total_quantity_sold ASC, total_revenue ASC`
	}

	// Add limit if specified
	if limitStr != "" {
		limit, err := strconv.Atoi(limitStr)
		if err != nil || limit <= 0 {
			http.Error(w, "limit must be a positive integer", http.StatusBadRequest)
			return
		}
		query += fmt.Sprintf(" LIMIT %d", limit)
	}

	// Execute query
	rows, err := db.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Collect results
	var items []ItemSalesStats
	for rows.Next() {
		var item ItemSalesStats
		err := rows.Scan(
			&item.BarangID,
			&item.BarangNama,
			&item.BrandNama,
			&item.BarangHargaJual,
			&item.TransactionCount,
			&item.TotalQuantitySold,
			&item.TotalRevenue,
			&item.AvgSalePrice,
		)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		items = append(items, item)
	}

	// Handle case when no items found
	if items == nil {
		items = []ItemSalesStats{}
	}

	// Prepare response
	response := ItemSalesReportResponse{
		Period:     period,
		Date:       date,
		Items:      items,
		TotalItems: len(items),
	}

	respondWithJSON(w, response)
}
