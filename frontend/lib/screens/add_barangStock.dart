import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../widgets/button_widget.dart';
import '../utils/app_colors.dart';
import '../routes/routes.dart';

class AddBarangStock extends StatefulWidget {
  const AddBarangStock({super.key});

  @override
  State<AddBarangStock> createState() => _AddBarangStockState();
}

class _AddBarangStockState extends State<AddBarangStock> {
  final DataController dataController = Get.find<DataController>();
  
  // Data from previous page
  String? barangId;
  String? barangNama;
  String? brandNama;
  
  // Stock management
  List<Map<String, dynamic>> gudangStocks = [];
  List<Map<String, dynamic>> availableGudangs = [];
  
  @override
  void initState() {
    super.initState();
    _getArguments();
    _loadGudangData();
  }
  
  void _getArguments() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      barangId = arguments['barang_id'];
      barangNama = arguments['barang_nama'];
      brandNama = arguments['brand_nama'];
    }
  }
  
  void _loadGudangData() {
    dataController.getGudangData().then((_) {
      setState(() {
        availableGudangs = List<Map<String, dynamic>>.from(dataController.gudangData);
      });
    });
  }
  
  // Add gudang to stock list
  void _addGudangStock(Map<String, dynamic> gudang) {
    if (!gudangStocks.any((element) => element['gudang_nama'] == gudang['gudang_nama'])) {
      setState(() {
        gudangStocks.add({
          'gudang_nama': gudang['gudang_nama'],
          'stock_barang': 0,
        });
      });
    }
  }
  
  // Remove gudang from stock list
  void _removeGudangStock(int index) {
    setState(() {
      gudangStocks.removeAt(index);
    });
  }
  
  // Update stock for specific gudang
  void _updateGudangStock(int index, int newStock) {
    setState(() {
      gudangStocks[index]['stock_barang'] = newStock;
    });
  }
  
  // Calculate total stock from all warehouses
  int _calculateTotalStock() {
    int total = 0;
    for (var gudangStock in gudangStocks) {
      total += gudangStock['stock_barang'] as int;
    }
    return total;
  }
  
  // Submit stock data
  void _submitStock() {
    if (barangId == null) {
      Get.snackbar("Error", "Barang ID tidak valid", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (gudangStocks.isEmpty) {
      Get.snackbar(
        "Error", 
        "Tambahkan minimal satu gudang",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Check if any stock is 0 (optional warning)
    bool hasZeroStock = gudangStocks.any((stock) => stock['stock_barang'] == 0);
    if (hasZeroStock) {
      Get.dialog(
        AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Beberapa gudang memiliki stok 0. Apakah Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _performSubmit();
              },
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
    } else {
      _performSubmit();
    }
  }
  
  void _performSubmit() {
    // Prepare data for createBarangStock API
    Map<String, dynamic> stockData = {
      'barang_id': barangId,
      'barang_nama': barangNama, // Optional for display
      'stock_gudang': gudangStocks,
    };
    
    // Call API (you'll need to implement this in DataController)
    dataController.postBarangStock(stockData).then((success) {
      if (success) {
        Get.dialog(
          AlertDialog(
            title: const Text('Sukses'),
            content: Text('Stok untuk $barangNama berhasil ditambahkan'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offAllNamed(RoutesClass.allBarang); // Navigate to barang list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          "Error",
          "Gagal menambahkan stok",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }).catchError((error) {
      Get.snackbar(
        "Error",
        "Gagal menambahkan stok: $error",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Tambah Stok Barang",
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
                child: GetBuilder<DataController>(
                  builder: (controller) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Barang Info Section
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Informasi Barang",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        "Nama Barang: ",
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Expanded(
                                        child: Text(
                                          barangNama ?? "Loading...",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text(
                                        "Brand: ",
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      Expanded(
                                        child: Text(
                                          brandNama ?? "Loading...",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Gudang Stock Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Stok per Gudang",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Add Gudang Button
                                PopupMenuButton<Map<String, dynamic>>(
                                  icon: Icon(Icons.add_circle, color: AppColors.secondaryColor),
                                  itemBuilder: (context) {
                                    return availableGudangs
                                        .where((gudang) => !gudangStocks.any((stock) => stock['gudang_nama'] == gudang['gudang_nama']))
                                        .map<PopupMenuItem<Map<String, dynamic>>>((gudang) {
                                      return PopupMenuItem<Map<String, dynamic>>(
                                        value: gudang,
                                        child: Text(gudang['gudang_nama']),
                                      );
                                    }).toList();
                                  },
                                  onSelected: _addGudangStock,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // Gudang Stock List
                            if (gudangStocks.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Belum ada gudang dipilih",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Klik tombol + untuk menambah gudang",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...gudangStocks.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> gudangStock = entry.value;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          gudangStock['gudang_nama'],
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                if (gudangStock['stock_barang'] > 0) {
                                                  _updateGudangStock(index, gudangStock['stock_barang'] - 1);
                                                }
                                              },
                                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                            Container(
                                              width: 40,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${gudangStock['stock_barang']}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                _updateGudangStock(index, gudangStock['stock_barang'] + 1);
                                              },
                                              icon: const Icon(Icons.add_circle, color: Colors.green),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeGudangStock(index),
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            
                            // Total Stock Summary
                            if (gudangStocks.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Stok:",
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${_calculateTotalStock()}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 30),
                            
                            // Submit Button
                            controller.isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : GestureDetector(
                                    onTap: _submitStock,
                                    child: ButtonWidget(
                                      backgroundcolor: AppColors.mainColor,
                                      text: "Simpan Stok",
                                      textColor: Colors.white,
                                    ),
                                  ),
                            
                            const SizedBox(height: 20),
                            
                            // Skip Button (optional)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('Konfirmasi'),
                                      content: const Text('Apakah Anda yakin ingin melewati penambahan stok? Anda dapat menambahkan stok nanti.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Get.back();
                                            Get.offAllNamed(RoutesClass.allBarang);
                                          },
                                          child: const Text('Lewati'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(
                                  "Lewati (Tambah Stok Nanti)",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
