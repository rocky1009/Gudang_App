class AppConstants {
  // Make sure this is your Railway URL, NOT localhost
  static const String BASE_URL = "https://proyekgudangbackend2-production.up.railway.app";
  
  // Brand endpoints
  static const String GET_BRANDS = "/getbrands";
  static const String GET_BRAND = "/getbrand";
  static const String POST_BRAND = "/createbrand";
  static const String UPDATE_BRAND = "/updatebrand";
  static const String DELETE_BRAND = "/deletebrand";
  
  // Gudang endpoints
  static const String GET_GUDANGS = "/getgudangs";
  static const String GET_GUDANG = "/getgudang";
  static const String GET_GUDANG_LANTAI = "/getgudanglantai";
  static const String POST_GUDANG = "/creategudang";
  static const String UPDATE_GUDANG = "/updategudang";
  static const String DELETE_GUDANG = "/deletegudang";
  
  // Barang endpoints
  static const String GET_BARANGS = "/getbarangs";
  static const String GET_BARANG = "/getbarang";
  static const String GET_CURRENT_STOCK = "/getcurrentstock";
  static const String POST_BARANG = "/createbarang";
  static const String POST_BARANG_STOCK = "/createbarangstock";
  static const String UPDATE_BARANG = "/updatebarang";
  static const String UPDATE_BARANG_STOCK = "/updatebarangstock";
  static const String DELETE_BARANG = "/deletebarang";
  
  // Customer endpoints
  static const String GET_CUSTOMERS = "/getcustomers";
  static const String GET_CUSTOMER = "/getcustomer";
  static const String POST_CUSTOMER = "/createcustomer";
  static const String UPDATE_CUSTOMER = "/updatecustomer";
  static const String DELETE_CUSTOMER = "/deletecustomer";
  
  // Logs endpoints
  static const String GET_BARANG_LOGS = "/getbaranglogs";
  static const String UPDATE_BARANG_LOGS = "/updatebaranglogs";
  static const String DELETE_BARANG_LOGS = "/deletebaranglogs";
  
  // Orders Masuk endpoints (incoming orders - Pesan Barang)
  static const String CREATE_BATCH_ORDER_MASUK = "/orders/masuk/batch";
  static const String GET_ORDERS_MASUK = "/orders/masuk";
  static const String UPDATE_ORDERS_MASUK_STATUS = "/orders/masuk";
  
  // Orders Keluar endpoints (outgoing orders - Barang Keluar)
  static const String CREATE_BATCH_ORDER_KELUAR = "/orders/keluar/batch";
  static const String GET_ORDERS_KELUAR = "/orders/keluar";
  static const String UPDATE_ORDERS_KELUAR_STATUS = "/orders/keluar";
  
  // Sales endpoints
  static const String GET_SALES = "/getsales";
  static const String GET_SALE = "/getsale";
  static const String GET_STOCK = "/getstock";
  static const String GET_FLOORS = "/getfloors";
  static const String GET_FLOOR_STOCK = "/getfloorstock";
  static const String CREATE_SALES = "/createsales";
  static const String CREATE_COMBINED_SALES = "/createcombinedsales";
  static const String CREATE_BATCH_SALES = "/createbatchsales";
  static const String UPDATE_SALES = "/updatesales";
  static const String DELETE_SALES = "/deletesales";
  
  // Sale Items endpoints
  static const String GET_SALE_ITEMS = "/getsaleitems";
  static const String GET_SALE_ITEM = "/getsaleitem";
  static const String CREATE_SALE_ITEM = "/createsaleitem";
  static const String UPDATE_SALE_ITEM = "/updatesaleitem";
  static const String DELETE_SALE_ITEM = "/deletesaleitem";
  
  // Report endpoints
  static const String GET_DAILY_REPORT = "/getdailyreport";
  static const String GET_MONTHLY_REPORT = "/getmonthlyreport";
  static const String GET_YEARLY_REPORT = "/getyearlyreport";
  static const String GET_ITEM_SALES_REPORT = "/getitemsalesreport";
  static const String GET_INVENTORY_SUMMARY = "/getinventorysummary";
  
  // Authentication endpoints
  static const String LOGIN = "/login";
  static const String REGISTER = "/register";
  static const String CHANGE_PASSWORD = "/changepassword";
  static const String GET_USERS = "/users";
  static const String GET_USER = "/user";
  static const String POST_USER = "/user";
  static const String UPDATE_USER = "/user";
  static const String APPROVE_USER = "/user";
  static const String DELETE_USER = "/user";
  static const String GET_LOGIN_HISTORY = "/loginhistory";
  
  // Number formatting utility
  static String formatCurrency(dynamic number) {
    if (number == null) return "0";
    
    String numStr = number.toString();
    // Remove any existing formatting
    numStr = numStr.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numStr.isEmpty) return "0";
    
    // Add dots every 3 digits from right to left
    String result = '';
    int count = 0;
    
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.' + result;
        count = 0;
      }
      result = numStr[i] + result;
      count++;
    }
    
    return result;
  }
  
  // Parse formatted currency back to integer
  static int parseCurrency(String formattedNumber) {
    if (formattedNumber.isEmpty) return 0;
    String cleaned = formattedNumber.replaceAll('.', '');
    return int.tryParse(cleaned) ?? 0;
  }
}