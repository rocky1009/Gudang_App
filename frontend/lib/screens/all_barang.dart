import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../routes/routes.dart';

class AllBarang extends StatefulWidget {
  const AllBarang({super.key});

  @override
  State<AllBarang> createState() => _AllBarangState();
}

class _AllBarangState extends State<AllBarang> {
  final DataController dataController = Get.find<DataController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBrand;
  List<String> _availableBrands = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadData() {
    dataController.getBarangData().then((_) {
      _updateAvailableBrands();
    });
  }
  
  void _updateAvailableBrands() {
    Set<String> brands = {};
    for (var barang in dataController.barangData) {
      String brandName = barang['brand_nama'] ?? 'No brand';
      if (brandName.isNotEmpty && brandName != 'No brand') {
        brands.add(brandName);
      }
    }
    setState(() {
      _availableBrands = brands.toList()..sort();
    });
  }
  
  List<dynamic> _getFilteredData() {
    List<dynamic> filteredData = dataController.barangData;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredData = filteredData.where((barang) {
        String barangNama = (barang['barang_nama'] ?? '').toString().toLowerCase();
        return barangNama.contains(_searchQuery);
      }).toList();
    }
    
    // Filter by selected brand
    if (_selectedBrand != null && _selectedBrand!.isNotEmpty) {
      filteredData = filteredData.where((barang) {
        String brandNama = barang['brand_nama'] ?? 'No brand';
        return brandNama == _selectedBrand;
      }).toList();
    }
    
    return filteredData;
  }
  
  void _refreshData() {
    _loadData();
  }
  
  // Calculate status based on stock_total using your formula
  int _calculateStatus(int stockTotal) {
    if (stockTotal == 0) {
      return 0; // Habis
    } else if (stockTotal > 0 && stockTotal <= 10) {
      return 1; // Stok Rendah
    } else {
      return 2; // Tersedia
    }
  }
  
  String _getStatusText(int stockTotal) {
    int status = _calculateStatus(stockTotal);
    switch (status) {
      case 0:
        return 'Habis';
      case 1:
        return 'Barang Sisa $stockTotal';
      case 2:
        return 'Barang Sisa $stockTotal';
      default:
        return 'Unknown';
    }
  }
  
  Color _getStatusColor(int stockTotal) {
    int status = _calculateStatus(stockTotal);
    switch (status) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange; // Using orange for yellow since yellow text is hard to read
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  int _calculateTotalStock(Map<String, dynamic> barang) {
    // Backend already provides stock_total, so use that directly
    return barang['stock_total'] as int? ?? 0;
  }
  
  void _deleteBarang(String id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus barang "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              dataController.deleteBarang(id).then((success) {
                if (success) {
                  Get.snackbar(
                    "Sukses",
                    "Barang berhasil dihapus",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                  _refreshData();
                } else {
                  Get.snackbar(
                    "Error",
                    "Gagal menghapus barang",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              });
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "List Barang",
            ),
            // Search and Filter Section
            Container(
              color: AppColors.mainColor,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari nama barang...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Row
                  Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Filter Brand:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBrand,
                              hint: const Text('Semua Brand'),
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedBrand = newValue;
                                });
                              },
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Semua Brand'),
                                ),
                                ..._availableBrands.map((String brand) {
                                  return DropdownMenuItem<String>(
                                    value: brand,
                                    child: Text(brand),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedBrand != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBrand = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.clear,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
                    if (controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (controller.barangData.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Belum ada barang",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Tambahkan barang pertama Anda",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Get.toNamed(RoutesClass.addBarang),
                              icon: const Icon(Icons.add),
                              label: const Text("Tambah Barang"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final filteredData = _getFilteredData();
                    
                    if (filteredData.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Tidak ada barang ditemukan",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Coba ubah kata kunci atau filter",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshData();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final barang = filteredData[index];
                          final totalStock = _calculateTotalStock(barang);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row with name and actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              barang['barang_nama'] ?? 'Unnamed',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              barang['brand_nama'] ?? 'No brand', // Show brand instead of description
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(totalStock),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getStatusText(totalStock),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // More actions
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'view':
                                                  Get.toNamed(
                                                    RoutesClass.viewBarang,
                                                    arguments: barang,
                                                  );
                                                  break;
                                                case 'edit_data':
                                                  Get.toNamed(
                                                    RoutesClass.getEditBarangRoute(barang['barang_id'] ?? ''),
                                                    arguments: barang,
                                                  );
                                                  break;
                                                case 'edit_stock':
                                                  Get.toNamed(
                                                    RoutesClass.getEditBarangStockRoute(barang['barang_id'] ?? ''),
                                                    arguments: barang,
                                                  );
                                                  break;
                                                case 'delete':
                                                  _deleteBarang(
                                                    barang['barang_id'] ?? '',
                                                    barang['barang_nama'] ?? 'Unnamed',
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.visibility),
                                                    SizedBox(width: 8),
                                                    Text('Lihat Detail'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit_data',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit),
                                                    SizedBox(width: 8),
                                                    Text('Edit Data'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'edit_stock',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.inventory),
                                                    SizedBox(width: 8),
                                                    Text('Edit Stok'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                  // Stock, Price, and Discount info
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Stok',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '$totalStock',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Jual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Rp ${AppConstants.formatCurrency(barang['barang_harga_jual'] ?? 0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diskon',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getDiscountColor(barang['barang_diskon']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getDiscountText(barang['barang_diskon']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),                                  // Per-warehouse stock breakdown
                                  if (barang['stock_gudang'] != null && 
                                      barang['stock_gudang'] is List &&
                                      (barang['stock_gudang'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Stok per Gudang',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...((barang['stock_gudang'] as List).map((stock) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              stock['gudang_nama'] ?? 'Unknown Gudang',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              '${stock['stock_barang'] ?? 0}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList()),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(RoutesClass.addBarang),
        backgroundColor: AppColors.mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  String _getDiscountText(dynamic discount) {
    if (discount == null || discount == '-' || discount.toString().isEmpty) {
      return '-';
    }
    return discount.toString();
  }
  
  Color _getDiscountColor(dynamic discount) {
    if (discount == null || discount == '-' || discount.toString().isEmpty) {
      return Colors.grey; // No discount
    }
    return Colors.orange; // Has discount
  }
}
