import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/services/service.dart';
import 'package:proyek_gudang/utils/app_constants.dart';

class DataController extends GetxController{
  DataService service = DataService();
  bool _isLoading = false;
  bool get isLoading=>_isLoading;
  
  // Brand data
  List<dynamic> _myData=[];
  List<dynamic> get myData=>_myData;
  Map<String, dynamic> _singleData={};
  Map<String, dynamic> get singleData=> _singleData;
  
  // Gudang data
  List<dynamic> _gudangData=[];
  List<dynamic> get gudangData=>_gudangData;
  Map<String, dynamic> _singleGudangData={};
  Map<String, dynamic> get singleGudangData=> _singleGudangData;
  
  // Barang data
  List<dynamic> _barangData=[];
  List<dynamic> get barangData=>_barangData;
  Map<String, dynamic> _singleBarangData={};
  Map<String, dynamic> get singleBarangData=> _singleBarangData;
  
  // Customer data
  List<dynamic> _customerData=[];
  List<dynamic> get customerData=>_customerData;
  Map<String, dynamic> _singleCustomerData={};
  Map<String, dynamic> get singleCustomerData=> _singleCustomerData;
  
  // Barang logs data
  List<dynamic> _barangLogs=[];
  List<dynamic> get barangLogs=>_barangLogs;
  
  // Orders data (DEPRECATED - kept for backward compatibility)
  List<dynamic> _ordersData=[];
  List<dynamic> get ordersData=>_ordersData;

  // Orders Masuk data (incoming orders)
  List<dynamic> _ordersMasukData=[];
  List<dynamic> get ordersMasukData=>_ordersMasukData;

  // Orders Keluar data (outgoing orders)
  List<dynamic> _ordersKeluarData=[];
  List<dynamic> get ordersKeluarData=>_ordersKeluarData;

  Future<void> getData() async {
    _isLoading = true;
    Response response = await service.getData(AppConstants.GET_BRANDS);
    
    // Debug information
    if(kDebugMode){
      print("Brands API: ${response.statusCode} - ${response.statusText}");
    }
    
    if(response.statusCode==200){
      _myData = response.body;
      print("We got the brands data");
    } else {
      print("We didn't get the brands data");
      print("Status Code: ${response.statusCode}");
      print("Status Text: ${response.statusText}");
      print("Response Body: ${response.body}");
    }
    _isLoading = false;
    update();
  }

  Future<void> getSingleData(String id) async {
    _isLoading = true;
    Response response = await service.getData('${AppConstants.GET_BRAND}/$id');
    if(response.statusCode==200){
      _singleData = response.body;
      if(kDebugMode){
        print("We got the single brand "+jsonEncode(response.body));
      }
    } else {
      print("We didn't get the single brand");
      print(response.statusCode);
      print(response.body);
    }
    _isLoading = false;
    update();
  }

  Future<void> postData(String nama, String kontak, String tlp) async {
    _isLoading = true;
    Response response = await service.postData(AppConstants.POST_BRAND, {
      "brand_nama": nama,
      "brand_kontak": kontak,
      "brand_tlp": tlp
    });
    if(response.statusCode==200){
      print("Brand post success");
    }
    else{
      print("Brand post fail");
    }
    update();
  }

  Future<bool> updateData(String nama, String kontak, String tlp, String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_BRAND}/$id', {
        "brand_nama": nama,
        "brand_kontak": kontak,
        "brand_tlp": tlp
      });
      
      if(response.statusCode==200){
        print("Brand update success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Brand update fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Brand update error: $e");
      return false;
    }
  }

  Future<bool> deleteData(String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_BRAND}/$id');
      
      if(response.statusCode==200){
        print("Data delete success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Data delete fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Data delete error: $e");
      return false;
    }
  }

  // Gudang methods
  Future<void> getGudangData() async {
    _isLoading = true;
    Response response = await service.getData(AppConstants.GET_GUDANGS);
    print("Gudang API Response Status: ${response.statusCode}");
    print("Gudang API Response Body: ${response.body}");
    print("Gudang API Response Type: ${response.body.runtimeType}");
    
    if(response.statusCode==200){
      _gudangData = response.body;
      print("We got the gudang data - Count: ${_gudangData.length}");
    } else {
      print("We didn't get the gudang data");
      print("Status Code: ${response.statusCode}");
      print("Status Text: ${response.statusText}");
      print("Response Body: ${response.body}");
    }
    _isLoading = false;
    update();
  }

  Future<List<dynamic>> getGudangLantaiData() async {
    Response response = await service.getData(AppConstants.GET_GUDANG_LANTAI);
    if(response.statusCode==200){
      if(kDebugMode){
        print("We got the gudang lantai data - Count: ${response.body.length}");
      }
      return response.body as List<dynamic>;
    } else {
      print("We didn't get the gudang lantai data");
      print("Status Code: ${response.statusCode}");
      return [];
    }
  }

  Future<void> getSingleGudang(String id) async {
    _isLoading = true;
    Response response = await service.getData('${AppConstants.GET_GUDANG}/$id');
    if(response.statusCode==200){
      _singleGudangData = response.body;
      if(kDebugMode){
        print("We got the single gudang "+jsonEncode(response.body));
      }
    } else {
      print("We didn't get the single gudang");
      print(response.statusCode);
      print(response.body);
    }
    _isLoading = false;
    update();
  }

  Future<void> postGudang(String nama, String alamat, int jumlahLantai) async {
    _isLoading = true;
    Response response = await service.postData(AppConstants.POST_GUDANG, {
      "gudang_nama": nama,
      "gudang_alamat": alamat,
      "jumlah_lantai": jumlahLantai
    });
    if(response.statusCode==200){
      print("Gudang post success");
    }
    else{
      print("Gudang post fail");
    }
    update();
  }

  Future<bool> updateGudang(String nama, String alamat, int jumlahLantai, String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_GUDANG}/$id', {
        "gudang_nama": nama,
        "gudang_alamat": alamat,
        "jumlah_lantai": jumlahLantai
      });
      
      if(response.statusCode==200){
        print("Gudang update success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Gudang update fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Gudang update error: $e");
      return false;
    }
  }

  Future<bool> deleteGudang(String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_GUDANG}/$id');
      
      if(response.statusCode==200){
        print("Gudang delete success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Gudang delete fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Gudang delete error: $e");
      return false;
    }
  }

  // Barang methods
  Future<void> getBarangData() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_BARANGS);
      
      if(kDebugMode){
        print("Barang API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        // Check if response.body is a List or needs conversion
        if (response.body is List) {
          _barangData = response.body;
        } else if (response.body is Map && response.body['data'] != null) {
          _barangData = response.body['data'];
        } else {
          print("Unexpected response format: ${response.body}");
          _barangData = [];
        }
        
        // Sort by barang_id to ensure consistent ordering
        _barangData.sort((a, b) {
          int idA = int.tryParse(a['barang_id']?.toString() ?? '0') ?? 0;
          int idB = int.tryParse(b['barang_id']?.toString() ?? '0') ?? 0;
          return idA.compareTo(idB);
        });
        
        print("Successfully loaded ${_barangData.length} barang items (sorted by ID)");
      } else {
        print("Failed to load barang data - Status: ${response.statusCode}");
        _barangData = [];
      }
    } catch (e) {
      print("Exception during barang API call: $e");
      _barangData = [];
    }
    
    _isLoading = false;
    update();
  }

  Future<void> getSingleBarang(String id) async {
    _isLoading = true;
    Response response = await service.getData('${AppConstants.GET_BARANG}/$id');
    if(response.statusCode==200){
      _singleBarangData = response.body;
      if(kDebugMode){
        print("We got the single barang "+jsonEncode(response.body));
      }
    } else {
      print("We didn't get the single barang");
      print(response.statusCode);
      print(response.body);
    }
    _isLoading = false;
    update();
  }

  Future<Map<String, dynamic>?> postBarang(Map<String, dynamic> barangData) async {
    _isLoading = true;
    
    try {
      Response response = await service.postData(AppConstants.POST_BARANG, barangData);
      if(response.statusCode==200){
        print("Barang post success");
        _isLoading = false;
        update();
        return response.body;
      }
      else{
        print("Barang post fail");
        _isLoading = false;
        update();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Barang post error: $e");
      return null;
    }
  }

  Future<bool> updateBarang(Map<String, dynamic> barangData, String id) async {
    _isLoading = true;
    
    print("Updating barang with ID: $id");
    print("Sending data: $barangData");
    
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_BARANG}/$id', barangData);
      
      if(response.statusCode==200){
        print("Barang update success");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Barang update fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Barang update error: $e");
      return false;
    }
  }

  Future<bool> deleteBarang(String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_BARANG}/$id');
      
      if(response.statusCode==200){
        print("Barang delete success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Barang delete fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Barang delete error: $e");
      return false;
    }
  }

  Future<bool> postBarangStock(Map<String, dynamic> stockData) async {
    _isLoading = true;
    
    try {
      Response response = await service.postData(AppConstants.POST_BARANG_STOCK, stockData);
      
      if(response.statusCode==200){
        print("Barang stock post success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Barang stock post fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Barang stock post error: $e");
      return false;
    }
  }

  Future<bool> updateBarangStock(Map<String, dynamic> stockData, String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_BARANG_STOCK}/$id', stockData);
      
      if(response.statusCode==200){
        print("Barang stock update success");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Barang stock update fail - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Barang stock update error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getCurrentStockInfo(String id) async {
    try {
      Response response = await service.getData('${AppConstants.GET_CURRENT_STOCK}/$id');
      
      if(response.statusCode==200){
        print("Current stock info retrieved successfully");
        print("Stock response: ${response.body}");
        return response.body;
      }
      else{
        print("Failed to get current stock - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return {};
      }
    } catch (e) {
      print("Current stock error: $e");
      return {};
    }
  }

  // Customer CRUD operations
  Future<void> getCustomerData() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_CUSTOMERS);
      
      if(kDebugMode){
        print("Customer API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        // Check if response.body is a List or needs conversion
        if (response.body is List) {
          _customerData = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _customerData = response.body['data'];
        } else {
          _customerData = [];
        }
        
        // Sort by customer_id
        _customerData.sort((a, b) {
          String idA = a['customer_id'] ?? '';
          String idB = b['customer_id'] ?? '';
          return idA.compareTo(idB);
        });
        
        print("Successfully loaded ${_customerData.length} customer items (sorted by ID)");
      } else {
        _customerData = [];
        print("Failed to load customer data - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _customerData = [];
      print("Customer data error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> getSingleCustomerData(String id) async {
    try {
      Response response = await service.getData('${AppConstants.GET_CUSTOMER}/$id');
      
      if(response.statusCode==200){
        _singleCustomerData = response.body;
        update();
        print("Single customer data loaded");
      }
      else{
        print("Failed to load single customer data");
      }
    } catch (e) {
      print("Single customer data error: $e");
    }
  }

  Future<Map<String, dynamic>?> postCustomer(Map<String, dynamic> customerData) async {
    _isLoading = true;
    
    try {
      Response response = await service.postData(AppConstants.POST_CUSTOMER, customerData);
      
      if(response.statusCode==200){
        print("Customer created successfully");
        return response.body;
      }
      else{
        print("Failed to create customer - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Create customer error: $e");
      return null;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> updateCustomer(Map<String, dynamic> customerData, String id) async {
    _isLoading = true;
    
    if(kDebugMode){
      print("Updating customer with ID: $id");
      print("Sending data: $customerData");
    }
    
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_CUSTOMER}/$id', customerData);
      
      if(response.statusCode==200){
        print("Customer updated successfully");
        return true;
      }
      else{
        print("Failed to update customer - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update customer error: $e");
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> deleteCustomer(String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_CUSTOMER}/$id');
      
      if(response.statusCode==200){
        print("Customer deleted successfully");
        // Refresh the customer list without calling update() as getCustomerData() already does it
        await getCustomerData();
        return true;
      }
      else{
        print("Failed to delete customer - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      print("Delete customer error: $e");
      _isLoading = false;
      update();
      return false;
    }
  }

  // Barang logs operations
  Future<void> getBarangLogs() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_BARANG_LOGS);
      
      if(kDebugMode){
        print("Barang Logs API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        // Check if response.body is a List or needs conversion
        if (response.body is List) {
          _barangLogs = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _barangLogs = response.body['data'];
        } else {
          _barangLogs = [];
        }
        
        // Sort by logs_date descending (newest first)
        _barangLogs.sort((a, b) {
          String dateA = a['logs_date'] ?? '';
          String dateB = b['logs_date'] ?? '';
          return dateB.compareTo(dateA);
        });
        
        if(kDebugMode){
          print("Successfully loaded ${_barangLogs.length} barang logs (sorted by date)");
        }
      } else {
        _barangLogs = [];
        print("Failed to load barang logs - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _barangLogs = [];
      print("Barang logs error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  // DEPRECATED: This method is no longer used with the new orders_masuk/orders_keluar structure
  // Status updates now happen at the individual order level (orders_status) via
  // updateOrdersMasukStatus() or updateOrdersKeluarStatus()
  // Future<bool> updateLogsDone(String logsId, int logsDone) async {
  //   // This method is obsolete - logs_done field removed from barang_logs table
  //   return false;
  // }

  // Update barang logs
  Future<bool> updateBarangLogs(String logsId, Map<String, dynamic> logData) async {
    try {
      Response response = await service.updateData('/updatebaranglogs/$logsId', logData);
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Barang logs updated successfully");
        }
        return true;
      } else {
        print("Failed to update barang logs - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update barang logs error: $e");
      return false;
    }
  }

  // Delete barang logs (with cascade delete of orders and stock restoration)
  Future<bool> deleteBarangLogs(String logsId) async {
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_BARANG_LOGS}/$logsId');
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Barang logs deleted successfully with stock restored");
        }
        return true;
      } else {
        print("Failed to delete barang logs - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Delete barang logs error: $e");
      return false;
    }
  }

  // Create barang logs
  Future<bool> createBarangLogs(Map<String, dynamic> logData) async {
    try {
      Response response = await service.postData('/createbaranglogs', logData);
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Barang logs created successfully");
        }
        return true;
      } else {
        print("Failed to create barang logs - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create barang logs error: $e");
      return false;
    }
  }

  // DEPRECATED methods removed - use createBatchOrderMasuk() or createBatchOrderKeluar() instead
  // - createCombinedOrder() → REMOVED (old unified orders table)
  // - createBatchOrder() → REMOVED (old unified orders table)

  // Create batch order masuk (for Pesan Barang page)
  Future<bool> createBatchOrderMasuk(Map<String, dynamic> batchData) async {
    try {
      print('=== API Request Debug ===');
      print('Endpoint: ${AppConstants.CREATE_BATCH_ORDER_MASUK}');
      print('Request body: ${jsonEncode(batchData)}');
      
      Response response = await service.postData(AppConstants.CREATE_BATCH_ORDER_MASUK, batchData);
      
      print('=== API Response Debug ===');
      print('Status code: ${response.statusCode}');
      print('Status text: ${response.statusText}');
      print('Response body type: ${response.body.runtimeType}');
      print('Response body: ${response.body}');
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Batch order masuk created successfully");
          print("Response: ${response.body}");
        }
        return true;
      } else {
        print("Failed to create batch order masuk - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        
        // Try to parse error details if available
        if (response.body is Map && response.body.containsKey('error')) {
          print("Error details: ${response.body['error']}");
          if (response.body.containsKey('details')) {
            print("Additional details: ${response.body['details']}");
          }
        }
        return false;
      }
    } catch (e, stackTrace) {
      print("Create batch order masuk error: $e");
      print("Stack trace: $stackTrace");
      return false;
    }
  }

  // Create batch order keluar (for Barang Keluar page)
  Future<bool> createBatchOrderKeluar(Map<String, dynamic> batchData) async {
    try {
      Response response = await service.postData(AppConstants.CREATE_BATCH_ORDER_KELUAR, batchData);
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Batch order keluar created successfully");
          print("Response: ${response.body}");
        }
        return true;
      } else {
        print("Failed to create batch order keluar - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create batch order keluar error: $e");
      return false;
    }
  }

  // Get orders masuk (incoming orders)
  Future<void> getOrdersMasuk() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_ORDERS_MASUK);
      
      if(kDebugMode){
        print("Orders Masuk API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        // Check if response.body is a List or needs conversion
        if (response.body is List) {
          _ordersMasukData = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _ordersMasukData = response.body['data'];
        } else {
          _ordersMasukData = [];
        }
        
        print("Successfully loaded ${_ordersMasukData.length} orders masuk");
      } else {
        print("Failed to load orders masuk - Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
        
        // Fallback: Try using barang logs endpoint and filter manually
        if(kDebugMode){
          print("Attempting fallback to barang logs endpoint...");
        }
        
        try {
          Response logsResponse = await service.getData(AppConstants.GET_BARANG_LOGS);
          if(logsResponse.statusCode == 200) {
            List<dynamic> allLogs = [];
            if (logsResponse.body is List) {
              allLogs = logsResponse.body;
            } else if (logsResponse.body is Map && logsResponse.body.containsKey('data')) {
              allLogs = logsResponse.body['data'];
            }
            
            // Filter for incoming orders (logs_type = 1 or logs_desc contains 'masuk' or 'pesan')
            // This is a workaround since the orders/masuk endpoint is not working
            _ordersMasukData = allLogs.where((log) {
              // Check if it's an incoming order based on available fields
              // You may need to adjust this logic based on your actual data structure
              final desc = (log['logs_desc'] ?? '').toString().toLowerCase();
              final hasOrderFields = log.containsKey('orders_pay_type') || 
                                    log.containsKey('orders_deadline');
              
              // Include if it has order-specific fields and doesn't look like an outgoing order
              return hasOrderFields && !desc.contains('keluar') && !desc.contains('jual');
            }).toList();
            
            print("Fallback successful: Loaded ${_ordersMasukData.length} orders from barang logs");
          } else {
            _ordersMasukData = [];
            print("Fallback also failed - Status code: ${logsResponse.statusCode}");
          }
        } catch (fallbackError) {
          _ordersMasukData = [];
          print("Fallback error: $fallbackError");
        }
      }
    } catch (e) {
      _ordersMasukData = [];
      print("Orders masuk error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Get orders keluar (outgoing orders)
  Future<void> getOrdersKeluar() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_ORDERS_KELUAR);
      
      if(kDebugMode){
        print("Orders Keluar API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        // Check if response.body is a List or needs conversion
        if (response.body is List) {
          _ordersKeluarData = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _ordersKeluarData = response.body['data'];
        } else {
          _ordersKeluarData = [];
        }
        
        print("Successfully loaded ${_ordersKeluarData.length} orders keluar");
      } else {
        _ordersKeluarData = [];
        print("Failed to load orders keluar - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _ordersKeluarData = [];
      print("Orders keluar error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  // Update orders masuk status
  Future<bool> updateOrdersMasukStatus(String ordersId, int ordersStatus) async {
    try {
      Response response = await service.updateData(
        '/orders/masuk/$ordersId/status',
        {'orders_status': ordersStatus}
      );
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Orders masuk status updated successfully");
        }
        return true;
      } else {
        print("Failed to update orders masuk status - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update orders masuk status error: $e");
      return false;
    }
  }

  // Update orders masuk (full update)
  Future<bool> updateOrdersMasuk(String ordersId, Map<String, dynamic> updateData) async {
    try {
      Response response = await service.updateData(
        '/orders/masuk/$ordersId',
        updateData
      );
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Orders masuk updated successfully");
        }
        return true;
      } else {
        print("Failed to update orders masuk - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update orders masuk error: $e");
      return false;
    }
  }

  // Update orders keluar status
  Future<bool> updateOrdersKeluarStatus(String ordersId, int ordersStatus) async {
    try {
      Response response = await service.updateData(
        '/orders/keluar/$ordersId/status',
        {'orders_status': ordersStatus}
      );
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Orders keluar status updated successfully");
        }
        return true;
      } else {
        print("Failed to update orders keluar status - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update orders keluar status error: $e");
      return false;
    }
  }

  // DEPRECATED methods removed - orders now split into orders_masuk and orders_keluar
  // - getOrders() → REMOVED (use getOrdersMasuk() or getOrdersKeluar())
  // - updateOrders() → REMOVED (use updateOrdersMasukStatus() or updateOrdersKeluarStatus())

  // Sales data
  List<dynamic> _salesData=[];
  List<dynamic> get salesData=>_salesData;
  Map<String, dynamic> _singleSalesData={};
  Map<String, dynamic> get singleSalesData=> _singleSalesData;
  
  // Sale Items data
  List<dynamic> _saleItemsData=[];
  List<dynamic> get saleItemsData=>_saleItemsData;
  
  // Monthly report data
  Map<String, dynamic> _monthlyReportData={};
  Map<String, dynamic> get monthlyReportData=> _monthlyReportData;
  
  // Daily report data
  Map<String, dynamic> _dailyReportData={};
  Map<String, dynamic> get dailyReportData=> _dailyReportData;
  
  // Yearly report data
  Map<String, dynamic> _yearlyReportData={};
  Map<String, dynamic> get yearlyReportData=> _yearlyReportData;
  
  // Item sales report data
  Map<String, dynamic> _itemSalesReportData={};
  Map<String, dynamic> get itemSalesReportData=> _itemSalesReportData;
  
  // Inventory summary report data
  Map<String, dynamic> _inventorySummaryData={};
  Map<String, dynamic> get inventorySummaryData=> _inventorySummaryData;

  // Sales operations
  Future<void> getSalesData() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_SALES);
      
      if(kDebugMode){
        print("Sales API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        if (response.body is List) {
          _salesData = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _salesData = response.body['data'];
        } else {
          _salesData = [];
        }
        
        // Sort by sales_date descending (newest first)
        _salesData.sort((a, b) {
          String dateA = a['sales_date'] ?? '';
          String dateB = b['sales_date'] ?? '';
          return dateB.compareTo(dateA);
        });
        
        print("Successfully loaded ${_salesData.length} sales records");
      } else {
        _salesData = [];
        print("Failed to load sales - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _salesData = [];
      print("Sales error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> getSingleSalesData(String id) async {
    _isLoading = true;
    
    try {
      Response response = await service.getData('${AppConstants.GET_SALE}/$id');
      
      if(response.statusCode==200){
        _singleSalesData = response.body;
        update();
        if(kDebugMode){
          print("Single sales data loaded");
        }
      }
      else{
        print("Failed to load single sales data");
      }
    } catch (e) {
      print("Single sales data error: $e");
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> createCombinedSales(Map<String, dynamic> salesData) async {
    try {
      Response response = await service.postData(AppConstants.CREATE_COMBINED_SALES, salesData);
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Combined sales created successfully");
          print("Response: ${response.body}");
        }
        return true;
      } else {
        print("Failed to create combined sales - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create combined sales error: $e");
      return false;
    }
  }

  Future<int> getStockForBarangGudang(String barangId, String gudangId) async {
    try {
      Response response = await service.getData('${AppConstants.GET_STOCK}/$barangId/$gudangId');
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Stock retrieved successfully for barang: $barangId, gudang: $gudangId");
          print("Stock response: ${response.body}");
        }
        
        final data = response.body;
        if (data is Map && data.containsKey('stock_barang')) {
          return data['stock_barang'] ?? 0;
        }
        return 0;
      } else {
        print("Failed to get stock - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return 0;
      }
    } catch (e) {
      print("Get stock error: $e");
      return 0;
    }
  }

  Future<List<dynamic>> getFloorsByGudang(String gudangId) async {
    try {
      Response response = await service.getData('${AppConstants.GET_FLOORS}/$gudangId');
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Floors retrieved successfully for gudang: $gudangId");
        }
        return response.body ?? [];
      } else {
        print("Failed to get floors - Status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Get floors error: $e");
      return [];
    }
  }

  Future<int> getStockForBarangGudangLantai(String barangId, String gudangId, String lantaiId) async {
    try {
      Response response = await service.getData('${AppConstants.GET_FLOOR_STOCK}/$barangId/$gudangId/$lantaiId');
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Stock retrieved successfully for barang: $barangId, gudang: $gudangId, lantai: $lantaiId");
          print("Stock response: ${response.body}");
        }
        
        final data = response.body;
        if (data is Map && data.containsKey('stock_barang')) {
          return data['stock_barang'] ?? 0;
        }
        return 0;
      } else {
        print("Failed to get floor stock - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return 0;
      }
    } catch (e) {
      print("Get floor stock error: $e");
      return 0;
    }
  }

  Future<bool> createBatchSales(Map<String, dynamic> batchData) async {
    try {
      Response response = await service.postData(AppConstants.CREATE_BATCH_SALES, batchData);
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Batch sales created successfully");
          print("Response: ${response.body}");
        }
        return true;
      } else {
        print("Failed to create batch sales - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create batch sales error: $e");
      return false;
    }
  }

  Future<bool> updateSales(String salesId, Map<String, dynamic> salesData) async {
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_SALES}/$salesId', salesData);
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Sales updated successfully");
        }
        return true;
      } else {
        print("Failed to update sales - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update sales error: $e");
      return false;
    }
  }

  Future<bool> deleteSales(String salesId) async {
    _isLoading = true;
    
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_SALES}/$salesId');
      
      if(response.statusCode==200){
        print("Sales deleted successfully");
        _isLoading = false;
        update();
        return true;
      }
      else{
        print("Sales delete failed - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      update();
      print("Sales delete error: $e");
      return false;
    }
  }

  // Sale Items operations
  Future<void> getSaleItems() async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(AppConstants.GET_SALE_ITEMS);
      
      if(kDebugMode){
        print("Sale Items API: ${response.statusCode} - ${response.statusText}");
      }
      
      if(response.statusCode==200){
        if (response.body is List) {
          _saleItemsData = response.body;
        } else if (response.body is Map && response.body.containsKey('data')) {
          _saleItemsData = response.body['data'];
        } else {
          _saleItemsData = [];
        }
        
        print("Successfully loaded ${_saleItemsData.length} sale items");
      } else {
        _saleItemsData = [];
        print("Failed to load sale items - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _saleItemsData = [];
      print("Sale items error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<bool> createSaleItem(Map<String, dynamic> itemData) async {
    try {
      Response response = await service.postData(AppConstants.CREATE_SALE_ITEM, itemData);
      
      if(response.statusCode == 200 || response.statusCode == 201) {
        if(kDebugMode) {
          print("Sale item created successfully");
        }
        return true;
      } else {
        print("Failed to create sale item - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Create sale item error: $e");
      return false;
    }
  }

  Future<bool> updateSaleItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      Response response = await service.updateData('${AppConstants.UPDATE_SALE_ITEM}/$itemId', itemData);
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Sale item updated successfully");
        }
        return true;
      } else {
        print("Failed to update sale item - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Update sale item error: $e");
      return false;
    }
  }

  Future<bool> deleteSaleItem(String itemId) async {
    try {
      Response response = await service.deleteData('${AppConstants.DELETE_SALE_ITEM}/$itemId');
      
      if(response.statusCode == 200) {
        if(kDebugMode) {
          print("Sale item deleted successfully");
        }
        return true;
      } else {
        print("Failed to delete sale item - Status code: ${response.statusCode}");
        print("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Delete sale item error: $e");
      return false;
    }
  }

  // Monthly profit report
  Future<void> getMonthlySalesReport(String month) async {
    _isLoading = true;
    
    try {
      Response response = await service.getData('${AppConstants.GET_MONTHLY_REPORT}?month=$month');
      
      if(kDebugMode){
        print("Monthly Report API: ${response.statusCode} - ${response.statusText}");
        print("Response body: ${response.body}");
      }
      
      if(response.statusCode==200){
        if (response.body is Map) {
          _monthlyReportData = response.body as Map<String, dynamic>;
        } else {
          _monthlyReportData = {};
        }
        
        print("Successfully loaded monthly report for $month");
      } else {
        _monthlyReportData = {};
        print("Failed to load monthly report - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _monthlyReportData = {};
      print("Monthly report error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }
  
  // Daily profit report
  Future<void> getDailySalesReport(String date) async {
    _isLoading = true;
    
    try {
      Response response = await service.getData('${AppConstants.GET_DAILY_REPORT}?date=$date');
      
      if(kDebugMode){
        print("Daily Report API: ${response.statusCode} - ${response.statusText}");
        print("Response body: ${response.body}");
      }
      
      if(response.statusCode==200){
        if (response.body is Map) {
          _dailyReportData = response.body as Map<String, dynamic>;
        } else {
          _dailyReportData = {};
        }
        
        print("Successfully loaded daily report for $date");
      } else {
        _dailyReportData = {};
        print("Failed to load daily report - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _dailyReportData = {};
      print("Daily report error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }
  
  // Yearly profit report
  Future<void> getYearlySalesReport(String year) async {
    _isLoading = true;
    
    try {
      Response response = await service.getData('${AppConstants.GET_YEARLY_REPORT}?year=$year&detailed=true');
      
      if(kDebugMode){
        print("Yearly Report API: ${response.statusCode} - ${response.statusText}");
        print("Response body: ${response.body}");
      }
      
      if(response.statusCode==200){
        if (response.body is Map) {
          _yearlyReportData = response.body as Map<String, dynamic>;
        } else {
          _yearlyReportData = {};
        }
        
        print("Successfully loaded yearly report for $year");
      } else {
        _yearlyReportData = {};
        print("Failed to load yearly report - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _yearlyReportData = {};
      print("Yearly report error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }
  
  // Item sales statistics report
  Future<void> getItemSalesReport(String period, String date, String order) async {
    _isLoading = true;
    
    try {
      Response response = await service.getData(
        '${AppConstants.GET_ITEM_SALES_REPORT}?period=$period&date=$date&order=$order'
      );
      
      if(kDebugMode){
        print("Item Sales Report API: ${response.statusCode} - ${response.statusText}");
        print("Response body: ${response.body}");
      }
      
      if(response.statusCode==200){
        if (response.body is Map) {
          _itemSalesReportData = response.body as Map<String, dynamic>;
        } else {
          _itemSalesReportData = {};
        }
        
        print("Successfully loaded item sales report for $period - $date");
      } else {
        _itemSalesReportData = {};
        print("Failed to load item sales report - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _itemSalesReportData = {};
      print("Item sales report error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }
  
  // Inventory summary report
  Future<void> getInventorySummary({
    String filter = 'all',
    String? brand,
    int lowStockThreshold = 10,
    int inactiveDays = 90,
  }) async {
    _isLoading = true;
    
    try {
      String queryParams = 'filter=$filter&low_stock_threshold=$lowStockThreshold&inactive_days=$inactiveDays';
      if (brand != null && brand.isNotEmpty && brand != 'Semua Brand') {
        queryParams += '&brand=$brand';
      }
      
      Response response = await service.getData(
        '${AppConstants.GET_INVENTORY_SUMMARY}?$queryParams'
      );
      
      if(kDebugMode){
        print("Inventory Summary API: ${response.statusCode} - ${response.statusText}");
        print("Response body: ${response.body}");
      }
      
      if(response.statusCode==200){
        if (response.body is Map) {
          _inventorySummaryData = response.body as Map<String, dynamic>;
        } else {
          _inventorySummaryData = {};
        }
        
        print("Successfully loaded inventory summary - Filter: $filter");
      } else {
        _inventorySummaryData = {};
        print("Failed to load inventory summary - Status code: ${response.statusCode}");
      }
    } catch (e) {
      _inventorySummaryData = {};
      print("Inventory summary error: $e");
    } finally {
      _isLoading = false;
      update();
    }
  }

  // ==================== USER MANAGEMENT ====================
  
  // User data
  List<dynamic> _userData=[];
  List<dynamic> get userData=>_userData;
  Map<String, dynamic> _singleUserData={};
  Map<String, dynamic> get singleUserData=> _singleUserData;

  Future<void> getUserData() async {
    _isLoading = true;
    Response response = await service.getData(AppConstants.GET_USERS);
    
    if(kDebugMode){
      print("Users API: ${response.statusCode} - ${response.statusText}");
    }
    
    if(response.statusCode==200){
      _userData = response.body;
      print("We got the users data");
    } else {
      print("We didn't get the users data");
      print("Status Code: ${response.statusCode}");
    }
    _isLoading = false;
    update();
  }

  Future<void> getSingleUserData(String id) async {
    _isLoading = true;
    Response response = await service.getData('${AppConstants.GET_USER}/$id');
    if(response.statusCode==200){
      _singleUserData = response.body;
      if(kDebugMode){
        print("We got the single user");
      }
    } else {
      print("We didn't get the single user");
      print(response.statusCode);
    }
    _isLoading = false;
    update();
  }

  Future<bool> createUser(String nama, String tlp, String password, int level, int status) async {
    _isLoading = true;
    
    // Get current date in YYYY-MM-DD format
    final now = DateTime.now();
    final daftar = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    Response response = await service.postData(AppConstants.POST_USER, {
      "users_nama": nama,
      "users_tlp": tlp,
      "users_pass": password,
      "users_level": level,
      "users_daftar": daftar,
      "users_status": status,
    });
    
    _isLoading = false;
    
    if(response.statusCode==200){
      print("User created successfully");
      await getUserData();
      update();
      return true;
    } else {
      print("User creation failed");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      update();
      return false;
    }
  }

  Future<bool> updateUser(String id, String nama, String tlp, int level, int status) async {
    _isLoading = true;
    Response response = await service.updateData('${AppConstants.UPDATE_USER}/$id', {
      "users_nama": nama,
      "users_tlp": tlp,
      "users_level": level,
      "users_status": status,
    });
    
    _isLoading = false;
    
    if(response.statusCode==200){
      print("User updated successfully");
      await getUserData();
      update();
      return true;
    } else {
      print("User update failed");
      print("Status Code: ${response.statusCode}");
      update();
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    Response response = await service.deleteData('${AppConstants.DELETE_USER}/$id');
    
    _isLoading = false;
    
    if(response.statusCode==200){
      print("User deleted successfully");
      await getUserData();
      update();
      return true;
    } else {
      print("User deletion failed");
      print("Status Code: ${response.statusCode}");
      update();
      return false;
    }
  }
}
