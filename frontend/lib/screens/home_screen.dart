import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/controllers/auth_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataController dataController = Get.find<DataController>();
  final AuthController authController = Get.find<AuthController>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        dataController.getSalesData(),
        dataController.getInventorySummary(
          filter: 'all',
          brand: 'Semua Brand',
          lowStockThreshold: 10,
          inactiveDays: 90,
        ),
      ]);
    } catch (e) {
      print('Error loading home screen data: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getLatestSales() {
    final sales = dataController.salesData;
    if (sales.length <= 5) return sales;
    return sales.sublist(0, 5);
  }

  Map<String, dynamic> _getInventorySummary() {
    final data = dataController.inventorySummaryData;
    if (data.isEmpty) {
      return {
        'total_items': 0,
        'available_items': 0,
        'low_stock_items': 0,
        'out_of_stock_items': 0,
        'inactive_items': 0,
      };
    }
    return {
      'total_items': data['total_items'] ?? 0,
      'available_items': data['available_items'] ?? 0,
      'low_stock_items': data['low_stock_items'] ?? 0,
      'out_of_stock_items': data['out_of_stock_items'] ?? 0,
      'inactive_items': data['inactive_items'] ?? 0,
    };
  }

  void _navigateToInventory(String filter) {
    Get.toNamed(
      RoutesClass.getLogsRingkasanBarangRoute(),
      arguments: {'filter': filter},
    );
  }

  void _navigateToAllSales() {
    Get.toNamed(RoutesClass.getAllSalesRoute());
  }

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _getPaymentTypeText(String paymentType) {
    switch (paymentType) {
      case '1':
        return 'Tunai';
      case '2':
        return 'Transfer';
      case '3':
        return 'Kredit';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHeader(
      title: "Victoria",
      body: _isLoading
          ? Center(
              child: SpinKitCircle(
                color: AppColors.mainColor,
                size: 50.0,
              ),
            )
          : Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // User info first
                          Obx(() {
                            final user = authController.currentUser.value;
                            if (user == null) return SizedBox.shrink();
                            
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle,
                                      size: 50,
                                      color: AppColors.mainColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.usersNama,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.mainColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: user.isAdmin
                                                  ? Colors.purple[100]
                                                  : Colors.blue[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              user.isAdmin ? 'Admin' : 'User',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: user.isAdmin
                                                    ? Colors.purple[900]
                                                    : Colors.blue[900],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(),
                                const SizedBox(height: 16),
                              ],
                            );
                          }),
                          // Victoria branding below
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 60,
                                color: AppColors.mainColor,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Victoria",
                                      style: TextStyle(
                                        color: AppColors.mainColor,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Warehouse Management",
                                      style: TextStyle(
                                        color: AppColors.smallTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inventory Statistics Section
                    Text(
                      "Statistik Stok",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInventoryStatistics(),
                    const SizedBox(height: 24),

                    // Latest Sales Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Penjualan Terbaru",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToAllSales,
                          child: Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLatestSales(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInventoryStatistics() {
    final summary = _getInventorySummary();
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Total Item",
                value: summary['total_items'].toString(),
                icon: Icons.inventory_2,
                color: AppColors.mainColor,
                onTap: () => _navigateToInventory('all'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Tersedia",
                value: summary['available_items'].toString(),
                icon: Icons.check_circle,
                color: Colors.green,
                onTap: () => _navigateToInventory('available'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Menipis",
                value: summary['low_stock_items'].toString(),
                icon: Icons.warning,
                color: Colors.orange,
                onTap: () => _navigateToInventory('low_stock'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Habis",
                value: summary['out_of_stock_items'].toString(),
                icon: Icons.remove_circle,
                color: Colors.red,
                onTap: () => _navigateToInventory('out_of_stock'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Tidak Laku",
                value: summary['inactive_items'].toString(),
                icon: Icons.access_time,
                color: Colors.grey,
                onTap: () => _navigateToInventory('inactive'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSales() {
    final latestSales = _getLatestSales();

    if (latestSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Belum ada penjualan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: latestSales.map((sale) => _buildSaleCard(sale)).toList(),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final customerName = sale['customer_name'] ?? 'Unknown Customer';
    final salesTotal = sale['sales_total'] ?? 0;
    final salesPayment = sale['sales_payment']?.toString() ?? '1';
    final salesDate = sale['sales_date'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          RoutesClass.getViewSalesRoute(),
          arguments: sale,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.mainColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          salesDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(salesTotal),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPaymentTypeText(salesPayment),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}