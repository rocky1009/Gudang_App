import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../routes/routes.dart';

class ViewBarang extends StatelessWidget {
  final String id;
  const ViewBarang({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final barang = Get.arguments as Map<String, dynamic>?;
    
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Detail Barang",
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: barang == null
                      ? const Center(
                          child: Text(
                            "Data barang tidak ditemukan",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nama barang
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Nama Barang",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        barang['barang_nama'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Deskripsi
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Brand",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        barang['brand_nama'] ?? 'N/A', // Show brand instead of description
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Info grid - First row (Harga and Total Stok)
                              Row(
                                children: [
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Harga",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
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
                                    ),
                                  ),
                                  Expanded(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            const Text(
                                              "Total Stok",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${barang['stock_total'] ?? 0}', // Use stock_total from backend
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Second row - Discount
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Diskon",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getDiscountColor(barang['barang_diskon']),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getDiscountText(barang['barang_diskon']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Status
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Status",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(barang['stock_total'] ?? 0),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _getStatusText(barang['stock_total'] ?? 0),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.toNamed(
                                          RoutesClass.getEditBarangRoute(barang['barang_id'] ?? id),
                                          arguments: barang,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        decoration: BoxDecoration(
                                          color: AppColors.mainColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.edit, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              "Edit Data",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.toNamed(
                                          RoutesClass.getEditBarangStockRoute(barang['barang_id'] ?? id),
                                          arguments: barang,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inventory, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              "Edit Stok",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
