import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../widgets/button_widget.dart';
import '../utils/app_colors.dart';
import '../routes/routes.dart';

class EditBarangStock extends StatefulWidget {
  final String id;
  const EditBarangStock({super.key, required this.id});

  @override
  State<EditBarangStock> createState() => _EditBarangStockState();
}

class _EditBarangStockState extends State<EditBarangStock> {
  final DataController dataController = Get.find<DataController>();
  
  Map<String, dynamic>? barangData;
  List<Map<String, dynamic>> floorStocks = []; // Changed from gudangStocks
  Map<String, int> originalStocks = {}; // Track original stock values by lantai_id
  Set<String> modifiedFloors = {}; // Track which floors have been modified
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() async {
    try {
      // Load current stock information using the new endpoint
      Map<String, dynamic> stockInfo = await dataController.getCurrentStockInfo(widget.id);
      
      if (stockInfo.isNotEmpty) {
        setState(() {
          barangData = stockInfo;
          _initializeFloorStocks();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        Get.snackbar(
          "Error",
          "Failed to load stock information",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error loading stock data: $e");
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        "Error",
        "Error loading stock data: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _initializeFloorStocks() {
    floorStocks.clear();
    originalStocks.clear();
    modifiedFloors.clear();
    
    print("=== INITIALIZE FLOOR STOCK DEBUG ===");
    print("barangData: $barangData");
    
    if (barangData != null && barangData!['current_stocks'] != null) {
      var currentStocks = barangData!['current_stocks'] as List;
      
      for (var stock in currentStocks) {
        print("Floor: ${stock['lantai_nama']} (${stock['gudang_nama']}) - Stock: ${stock['stock_barang']}");
        
        String lantaiId = stock['lantai_id'];
        int stockBarang = stock['stock_barang'] ?? 0;
        
        floorStocks.add({
          'gudang_id': stock['gudang_id'],
          'lantai_id': lantaiId,
          'lantai_no': stock['lantai_no'],
          'lantai_nama': stock['lantai_nama'],
          'gudang_nama': stock['gudang_nama'],
          'stok': stockBarang,
        });
        
        // Store original stock value
        originalStocks[lantaiId] = stockBarang;
      }
    }
    
    print("Final floorStocks: $floorStocks");
    print("Original stocks: $originalStocks");
    print("===============================");
  }
  
  // Group floors by warehouse
  Map<String, List<Map<String, dynamic>>> _groupFloorsByGudang() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var floor in floorStocks) {
      String gudangNama = floor['gudang_nama'] ?? 'Unknown';
      if (!grouped.containsKey(gudangNama)) {
        grouped[gudangNama] = [];
      }
      grouped[gudangNama]!.add(floor);
    }
    
    // Sort floors within each warehouse by lantai_no
    grouped.forEach((key, floors) {
      floors.sort((a, b) => (a['lantai_no'] as int).compareTo(b['lantai_no'] as int));
    });
    
    return grouped;
  }
  
  List<String> _getSortedGudangNames(Map<String, List<Map<String, dynamic>>> grouped) {
    // Get all gudang names with their gudang_id for proper sorting
    List<MapEntry<String, String>> gudangWithIds = [];
    
    grouped.forEach((gudangNama, floors) {
      if (floors.isNotEmpty) {
        String gudangId = floors[0]['gudang_id'] ?? '';
        gudangWithIds.add(MapEntry(gudangNama, gudangId));
      }
    });
    
    // Sort by gudang_id in ascending order (GU_0001, GU_0002, GU_0003)
    gudangWithIds.sort((a, b) => a.value.compareTo(b.value));
    
    return gudangWithIds.map((e) => e.key).toList();
  }
  
  int _getFloorIndex(String lantaiId) {
    return floorStocks.indexWhere((floor) => floor['lantai_id'] == lantaiId);
  }
  
  void _incrementStock(int index) {
    setState(() {
      floorStocks[index]['stok'] = (floorStocks[index]['stok'] as int) + 1;
      // Mark this floor as modified
      modifiedFloors.add(floorStocks[index]['lantai_id']);
    });
  }
  
  void _decrementStock(int index) {
    setState(() {
      int currentStock = floorStocks[index]['stok'] as int;
      if (currentStock > 0) {
        floorStocks[index]['stok'] = currentStock - 1;
        // Mark this floor as modified
        modifiedFloors.add(floorStocks[index]['lantai_id']);
      }
    });
  }
  
  void _updateStock() async {
    // Check if any floors were actually modified
    if (modifiedFloors.isEmpty) {
      Get.snackbar(
        "Info",
        "Tidak ada perubahan stok yang dilakukan",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      // Only send stock data for modified floors
      List<Map<String, dynamic>> stockLantai = floorStocks
          .where((floorStock) {
            String lantaiId = floorStock['lantai_id'];
            // Only include floors that were modified AND have stock > 0
            // OR if the original stock was > 0 (to allow reducing to 0)
            return modifiedFloors.contains(lantaiId) && 
                   (floorStock['stok'] > 0 || (originalStocks[lantaiId] ?? 0) > 0);
          })
          .map((floorStock) {
            return {
              'lantai_id': floorStock['lantai_id'],
              'stock_barang': floorStock['stok'],
            };
          })
          .toList();
      
      if (stockLantai.isEmpty) {
        Get.snackbar(
          "Info",
          "Tidak ada data stok yang valid untuk diupdate",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      
      print("=== UPDATE STOCK DEBUG ===");
      print("Modified floors: $modifiedFloors");
      print("Sending stock data: $stockLantai");
      print("========================");
      
      Map<String, dynamic> stockData = {
        'stock_lantai': stockLantai,
      };
      
      bool success = await dataController.updateBarangStock(stockData, widget.id);
      
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: Text('Stok barang berhasil diupdate untuk ${stockLantai.length} lantai'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offNamed(RoutesClass.allBarang); // Navigate to barang list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          "Error", 
          "Gagal mengupdate stok barang", 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error", 
        "Terjadi kesalahan: $e", 
        backgroundColor: Colors.red, 
        colorText: Colors.white
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Edit Stock Barang",
            ),
            Expanded(
              child: Container(
                width: double.maxFinite,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Barang Info
                            if (barangData != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barangData!['barang_nama'] ?? barangData!['nama'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Note: brand info and price not available in current stock endpoint
                                    // Could be added to backend if needed
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Stock per Floor
                            const Text(
                              "Stok per Lantai",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final groupedFloors = _groupFloorsByGudang();
                                  final gudangNames = _getSortedGudangNames(groupedFloors);
                                  
                                  return ListView.builder(
                                    itemCount: gudangNames.length,
                                    itemBuilder: (context, gudangIndex) {
                                      final gudangNama = gudangNames[gudangIndex];
                                      final floors = groupedFloors[gudangNama]!;
                                      
                                      // Calculate total stock for this warehouse
                                      int totalStock = floors.fold(0, (sum, floor) => sum + (floor['stok'] as int));
                                      
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: AppColors.mainColor.withOpacity(0.3), width: 2),
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Warehouse Header
                                            Container(
                                              padding: const EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: AppColors.mainColor.withOpacity(0.1),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warehouse,
                                                        color: AppColors.mainColor,
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            gudangNama,
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${floors.length} Lantai',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.mainColor,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      'Total: $totalStock',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Floors List
                                            Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                children: floors.asMap().entries.map((entry) {
                                                  final floorStock = entry.value;
                                                  final floorIndex = _getFloorIndex(floorStock['lantai_id']);
                                                  final isLast = entry.key == floors.length - 1;
                                                  
                                                  return Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          // Floor Info
                                                          Expanded(
                                                            flex: 2,
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  width: 36,
                                                                  height: 36,
                                                                  decoration: BoxDecoration(
                                                                    color: AppColors.mainColor.withOpacity(0.1),
                                                                    borderRadius: BorderRadius.circular(8),
                                                                  ),
                                                                  child: Center(
                                                                    child: Text(
                                                                      'Lt.${floorStock['lantai_no']}',
                                                                      style: TextStyle(
                                                                        fontSize: 12,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: AppColors.mainColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                Expanded(
                                                                  child: Text(
                                                                    floorStock['lantai_nama'] ?? 'Unknown',
                                                                    style: const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight: FontWeight.w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          
                                                          // Stock Controls
                                                          Row(
                                                            children: [
                                                              // Minus Button
                                                              GestureDetector(
                                                                onTap: () => _decrementStock(floorIndex),
                                                                child: Container(
                                                                  width: 32,
                                                                  height: 32,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.red.shade100,
                                                                    borderRadius: BorderRadius.circular(6),
                                                                    border: Border.all(color: Colors.red.shade300),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons.remove,
                                                                    color: Colors.red,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                              ),
                                                              
                                                              // Stock Count
                                                              Container(
                                                                width: 50,
                                                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                                                child: Text(
                                                                  floorStock['stok'].toString(),
                                                                  textAlign: TextAlign.center,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ),
                                                              
                                                              // Plus Button
                                                              GestureDetector(
                                                                onTap: () => _incrementStock(floorIndex),
                                                                child: Container(
                                                                  width: 32,
                                                                  height: 32,
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.green.shade100,
                                                                    borderRadius: BorderRadius.circular(6),
                                                                    border: Border.all(color: Colors.green.shade300),
                                                                  ),
                                                                  child: const Icon(
                                                                    Icons.add,
                                                                    color: Colors.green,
                                                                    size: 18,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      if (!isLast) ...[
                                                        const SizedBox(height: 12),
                                                        Divider(color: Colors.grey.shade200, height: 1),
                                                        const SizedBox(height: 12),
                                                      ],
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Submit Button
                            GestureDetector(
                              onTap: _updateStock,
                              child: ButtonWidget(
                                backgroundcolor: AppColors.mainColor,
                                text: "Update Stok",
                                textColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
