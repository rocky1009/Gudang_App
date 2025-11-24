package router

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"src/database"

	_ "github.com/go-sql-driver/mysql"
	"github.com/gorilla/mux"
)

type Customer struct {
	ID     string `json:"customer_id"`
	Nama   string `json:"customer_nama"`
	Kontak string `json:"customer_kontak"`
	Alamat string `json:"customer_alamat"`
}

type CustomerRequest struct {
	Nama   string `json:"customer_nama"`
	Kontak string `json:"customer_kontak"`
	Alamat string `json:"customer_alamat"`
}

func createCustomer(w http.ResponseWriter, r *http.Request) {
	var customer CustomerRequest
	if err := json.NewDecoder(r.Body).Decode(&customer); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if customer.Nama == "" {
		respondWithError(w, http.StatusBadRequest, "customer_nama is required")
		return
	}
	if customer.Kontak == "" {
		respondWithError(w, http.StatusBadRequest, "customer_kontak is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get last customer_id
	var lastID string
	err = db.QueryRow("SELECT customer_id FROM customer ORDER BY customer_id DESC LIMIT 1").Scan(&lastID)
	if err != nil && err != sql.ErrNoRows {
		respondWithError(w, http.StatusInternalServerError, "Error fetching last customer_id")
		return
	}
	nextNum := 1
	if lastID != "" {
		numPart := lastID[3:] // "CU_0000002" -> "0000002"
		n, _ := strconv.Atoi(numPart)
		nextNum = n + 1
	}
	newID := fmt.Sprintf("CU_%07d", nextNum) // "CU_0000003"

	stmt, err := db.Prepare("INSERT INTO customer (customer_id, customer_nama, customer_kontak, customer_alamat) VALUES (?, ?, ?, ?)")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(newID, customer.Nama, customer.Kontak, customer.Alamat)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Insert error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"customer_id":     newID,
		"customer_nama":   customer.Nama,
		"customer_kontak": customer.Kontak,
		"customer_alamat": customer.Alamat,
		"status":          "Created",
		"message":         "Customer created successfully",
	})
}

func getCustomers(w http.ResponseWriter, r *http.Request) {
	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// Get query parameters for search
	searchName := r.URL.Query().Get("search")

	var query string
	var args []interface{}

	if searchName != "" {
		query = "SELECT customer_id, customer_nama, customer_kontak, customer_alamat FROM customer WHERE customer_nama LIKE ? ORDER BY customer_id"
		args = append(args, "%"+searchName+"%")
	} else {
		query = "SELECT customer_id, customer_nama, customer_kontak, customer_alamat FROM customer ORDER BY customer_id"
	}

	rows, err := db.Query(query, args...)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}
	defer rows.Close()

	var customers []Customer
	for rows.Next() {
		var c Customer
		if err := rows.Scan(&c.ID, &c.Nama, &c.Kontak, &c.Alamat); err != nil {
			respondWithError(w, http.StatusInternalServerError, "Scan error: "+err.Error())
			return
		}
		customers = append(customers, c)
	}

	respondWithJSON(w, customers)
}

func getCustomer(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	var c Customer
	err = db.QueryRow("SELECT customer_id, customer_nama, customer_kontak, customer_alamat FROM customer WHERE customer_id = ?", id).Scan(&c.ID, &c.Nama, &c.Kontak, &c.Alamat)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Customer not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Query error: "+err.Error())
		return
	}

	respondWithJSON(w, c)
}

func updateCustomer(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	var customer CustomerRequest
	if err := json.NewDecoder(r.Body).Decode(&customer); err != nil {
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	// Validate required fields
	if customer.Nama == "" {
		respondWithError(w, http.StatusBadRequest, "customer_nama is required")
		return
	}
	if customer.Kontak == "" {
		respondWithError(w, http.StatusBadRequest, "customer_kontak is required")
		return
	}

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	// First check if customer exists
	var existingCustomerID string
	err = db.QueryRow("SELECT customer_id FROM customer WHERE customer_id = ?", id).Scan(&existingCustomerID)
	if err == sql.ErrNoRows {
		respondWithError(w, http.StatusNotFound, "Customer with ID "+id+" not found")
		return
	} else if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Error checking customer existence: "+err.Error())
		return
	}

	stmt, err := db.Prepare("UPDATE customer SET customer_nama = ?, customer_kontak = ?, customer_alamat = ? WHERE customer_id = ?")
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Prepare statement error")
		return
	}
	defer stmt.Close()

	_, err = stmt.Exec(customer.Nama, customer.Kontak, customer.Alamat, id)
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Update error: "+err.Error())
		return
	}

	respondWithJSON(w, map[string]interface{}{
		"customer_id":     id,
		"customer_nama":   customer.Nama,
		"customer_kontak": customer.Kontak,
		"customer_alamat": customer.Alamat,
		"status":          "Updated",
		"message":         "Customer information updated successfully",
	})
}

func deleteCustomer(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	id := params["id"]

	db, err := database.GetDBConnection()
	if err != nil {
		respondWithError(w, http.StatusInternalServerError, "Database connection error")
		return
	}
	defer db.Close()

	stmt, err := db.Prepare("DELETE FROM customer WHERE customer_id = ?")
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
		respondWithError(w, http.StatusNotFound, "Customer not found")
		return
	}

	respondWithJSON(w, map[string]string{
		"customer_id": id,
		"status":      "Deleted",
		"message":     "Customer deleted successfully",
	})
}

// SetupCustomerRoutes sets up all customer-related routes
func SetupCustomerRoutes(router *mux.Router) {
	router.HandleFunc("/createcustomer", createCustomer).Methods("POST")
	router.HandleFunc("/getcustomers", getCustomers).Methods("GET")
	router.HandleFunc("/getcustomer/{id}", getCustomer).Methods("GET")
	router.HandleFunc("/updatecustomer/{id}", updateCustomer).Methods("PUT")
	router.HandleFunc("/deletecustomer/{id}", deleteCustomer).Methods("DELETE")
}
