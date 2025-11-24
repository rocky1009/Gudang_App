import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ViewDiscount extends StatefulWidget {
  const ViewDiscount({super.key});

  @override
  State<ViewDiscount> createState() => _ViewDiscountState();
}

class _ViewDiscountState extends State<ViewDiscount> {
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
      _availableBrands = ['Semua Brand', ...brands.toList()..sort()];
    });
  }

  List<dynamic> _getFilteredDiscounts() {
    List<dynamic> discounts = dataController.barangData
        .where((barang) => 
            barang['barang_diskon'] != null && 
            barang['barang_diskon'] != '-' && 
            barang['barang_diskon'].toString().isNotEmpty)
        .toList();

    // Filter by brand if selected
    if (_selectedBrand != null && _selectedBrand != 'Semua Brand') {
      discounts = discounts.where((barang) {
        return barang['brand_nama'] == _selectedBrand;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      discounts = discounts.where((barang) {
        final barangNama = barang['barang_nama']?.toString().toLowerCase() ?? '';
        final brandNama = barang['brand_nama']?.toString().toLowerCase() ?? '';
        return barangNama.contains(_searchQuery) || brandNama.contains(_searchQuery);
      }).toList();
    }

    return discounts;
  }

  void _showBrandFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Brand',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._availableBrands.map((brand) {
                return ListTile(
                  leading: Icon(
                    _selectedBrand == brand ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: AppColors.mainColor,
                  ),
                  title: Text(brand),
                  onTap: () {
                    setState(() {
                      _selectedBrand = brand;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEdit(Map<String, dynamic> barang) async {
    print('ViewDiscount: Navigating to edit for barang: ${barang['barang_nama']}');
    final result = await Get.toNamed(
      RoutesClass.getEditDiscountRoute(),
      arguments: barang,
    );
    
    print('ViewDiscount: Returned from edit with result: $result');
    // If the edit was successful, refresh the data
    if (result == true) {
      print('ViewDiscount: Refreshing data after successful edit');
      _loadData();
    }
  }

  void _deleteDiscount(Map<String, dynamic> barang) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Diskon'),
          content: Text('Apakah Anda yakin ingin menghapus diskon untuk ${barang['barang_nama']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Update barang with null discount values
                final updateData = {
                  'barang_nama': barang['barang_nama'],
                  'brand_nama': barang['brand_nama'],
                  'barang_harga_asli': barang['barang_harga_asli'],
                  'barang_harga_jual': barang['barang_harga_jual'],
                  'barang_diskon': '',
                  'barang_deadline_diskon': '',
                  'barang_status': barang['barang_status'],
                };

                final success = await dataController.updateBarang(updateData, barang['barang_id']);
                
                if (success) {
                  Get.snackbar(
                    'Sukses',
                    'Diskon berhasil dihapus',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                  _loadData();
                } else {
                  Get.snackbar(
                    'Error',
                    'Gagal menghapus diskon',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  bool _isDiscountExpired(String? deadline) {
    if (deadline == null || deadline == '-' || deadline.isEmpty) {
      return false;
    }
    
    try {
      final deadlineDate = DateTime.parse(deadline);
      return deadlineDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _formatDeadline(String? deadline) {
    if (deadline == null || deadline == '-' || deadline.isEmpty) {
      return '-';
    }
    
    try {
      final deadlineDate = DateTime.parse(deadline);
      return '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    } catch (e) {
      return deadline;
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
              title: "Kelola Diskon",
            ),
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.mainColor,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Cari barang atau brand...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showBrandFilter,
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 16),
                          label: Text(
                            _selectedBrand ?? 'Filter Brand',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedBrand == null 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                        ),
                      ),
                      if (_selectedBrand != null && _selectedBrand != 'Semua Brand') ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedBrand = null;
                            });
                          },
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
                          label: const Text(
                            'Hapus Filter',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      return Center(
                        child: SpinKitCircle(
                          color: AppColors.mainColor,
                          size: 50.0,
                        ),
                      );
                    }
                    
                    final filteredDiscounts = _getFilteredDiscounts();
                    
                    if (filteredDiscounts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedBrand != null && _selectedBrand != 'Semua Brand'
                                  ? "Tidak ada diskon ditemukan"
                                  : "Belum ada diskon",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedBrand != null && _selectedBrand != 'Semua Brand'
                                  ? "Coba kata kunci yang berbeda"
                                  : "Diskon akan muncul di sini",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Results header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Menampilkan ${filteredDiscounts.length} diskon',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _loadData,
                                icon: Icon(Icons.refresh, color: AppColors.mainColor),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ),
                        // Discount list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDiscounts.length,
                            itemBuilder: (context, index) {
                              final barang = filteredDiscounts[index];
                              final barangNama = barang['barang_nama'] ?? 'Unknown Barang';
                              final brandNama = barang['brand_nama'] ?? 'Unknown Brand';
                              final discount = barang['barang_diskon'] ?? '-';
                              final deadline = barang['barang_deadline_diskon'];
                              final isExpired = _isDiscountExpired(deadline);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with brand and status
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  brandNama,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  barangNama,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isExpired ? Colors.red : Colors.green,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isExpired ? 'Expired' : 'Active',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Discount and deadline info
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
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
                                                  Text(
                                                    discount.toString(),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.mainColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Masa Berlaku',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDeadline(deadline),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      color: isExpired ? Colors.red : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Action buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _navigateToEdit(barang),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.mainColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _deleteDiscount(barang),
                                              icon: const Icon(Icons.delete, size: 16),
                                              label: const Text('Hapus'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.toNamed(RoutesClass.getAddDiscountRoute());
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppColors.mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
