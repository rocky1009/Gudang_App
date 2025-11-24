import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/controllers/auth_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LogsRingkasanBarang extends StatefulWidget {
  const LogsRingkasanBarang({super.key});

  @override
  State<LogsRingkasanBarang> createState() => _LogsRingkasanBarangState();
}

class _LogsRingkasanBarangState extends State<LogsRingkasanBarang> {
  final DataController dataController = Get.find<DataController>();
  final AuthController authController = Get.find<AuthController>();
  
  bool _isLoading = false;
  String _selectedFilter = 'all';
  String _selectedBrand = 'Semua Brand';
  int _lowStockThreshold = 10;
  int _inactiveDays = 90;
  
  List<dynamic> _items = [];
  Map<String, dynamic> _summary = {};
  
  List<String> _brands = ['Semua Brand'];
  
  final List<Map<String, dynamic>> _filterOptions = [
    {'value': 'all', 'label': 'Semua Item', 'icon': Icons.inventory_2},
    {'value': 'available', 'label': 'Stok Tersedia', 'icon': Icons.check_circle},
    {'value': 'low_stock', 'label': 'Stok Menipis', 'icon': Icons.warning},
    {'value': 'out_of_stock', 'label': 'Stok Habis', 'icon': Icons.remove_circle},
    {'value': 'inactive', 'label': 'Item Tidak Laku', 'icon': Icons.access_time},
  ];

  @override
  void initState() {
    super.initState();
    
    // Check if there's a filter argument passed from navigation
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('filter')) {
      _selectedFilter = arguments['filter'] as String;
    }
    
    _loadBrands();
    _loadReport();
  }
  
  Future<void> _loadBrands() async {
    try {
      await dataController.getData();
      if (!mounted) return;
      setState(() {
        _brands = ['Semua Brand'];
        for (var brand in dataController.myData) {
          if (brand['brand_nama'] != null) {
            _brands.add(brand['brand_nama']);
          }
        }
      });
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await dataController.getInventorySummary(
        filter: _selectedFilter,
        brand: _selectedBrand,
        lowStockThreshold: _lowStockThreshold,
        inactiveDays: _inactiveDays,
      );
      _processReportData();
    } catch (e) {
      print('Error loading report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _processReportData() {
    final data = dataController.inventorySummaryData;
    
    if (data.isEmpty) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _summary = {};
      });
      return;
    }
    
    if (!mounted) return;
    setState(() {
      _summary = {
        'total_items': data['total_items'] ?? 0,
        'available_items': data['available_items'] ?? 0,
        'low_stock_items': data['low_stock_items'] ?? 0,
        'out_of_stock_items': data['out_of_stock_items'] ?? 0,
        'inactive_items': data['inactive_items'] ?? 0,
      };
      _items = data['items'] ?? [];
    });
  }

  Future<void> _showFilterBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter & Pengaturan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                // Brand filter
                const Text(
                  'Brand',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBrand,
                      isExpanded: true,
                      items: _brands.map((brand) {
                        return DropdownMenuItem(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedBrand = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Low stock threshold
                Text(
                  'Batas Stok Menipis: $_lowStockThreshold pcs',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _lowStockThreshold.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '$_lowStockThreshold pcs',
                  activeColor: AppColors.mainColor,
                  onChanged: (value) {
                    setModalState(() {
                      _lowStockThreshold = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Inactive days threshold
                Text(
                  'Item Tidak Laku: $_inactiveDays hari',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _inactiveDays.toDouble(),
                  min: 30,
                  max: 365,
                  divisions: 67,
                  label: '$_inactiveDays hari',
                  activeColor: AppColors.mainColor,
                  onChanged: (value) {
                    setModalState(() {
                      _inactiveDays = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          // Values are already updated via setModalState
                        });
                      }
                      Navigator.pop(context);
                      _loadReport();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final intValue = value is int ? value : (value is double ? value.toInt() : 0);
    return 'Rp ${intValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return 'Tersedia';
      case 'low_stock':
        return 'Menipis';
      case 'out_of_stock':
        return 'Habis';
      default:
        return 'Unknown';
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
              title: "Statistik Stok",
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
                child: _isLoading
                    ? Center(
                        child: SpinKitCircle(
                          color: AppColors.mainColor,
                          size: 50.0,
                        ),
                      )
                    : Column(
                        children: [
                          // Controls
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _showFilterBottomSheet,
                                    icon: const Icon(Icons.tune, size: 18),
                                    label: const Text('Filter & Pengaturan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.mainColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadReport,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Filter chips
                          Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filterOptions.length,
                              itemBuilder: (context, index) {
                                final option = _filterOptions[index];
                                final isSelected = _selectedFilter == option['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          option['icon'],
                                          size: 16,
                                          color: isSelected ? Colors.white : Colors.grey[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(option['label']),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (mounted) {
                                        setState(() {
                                          _selectedFilter = option['value'];
                                        });
                                      }
                                      _loadReport();
                                    },
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: AppColors.mainColor,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Summary cards
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Item',
                                    _summary['total_items']?.toString() ?? '0',
                                    Icons.inventory_2,
                                    AppColors.mainColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Tersedia',
                                    _summary['available_items']?.toString() ?? '0',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Menipis',
                                    _summary['low_stock_items']?.toString() ?? '0',
                                    Icons.warning,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Habis',
                                    _summary['out_of_stock_items']?.toString() ?? '0',
                                    Icons.remove_circle,
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Tidak Laku',
                                    _summary['inactive_items']?.toString() ?? '0',
                                    Icons.access_time,
                                    Colors.grey,
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Items list
                          Expanded(
                            child: _buildItemsList(),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final barangNama = item['barang_nama'] ?? '-';
    final brandNama = item['brand_nama'] ?? '-';
    final totalStock = item['total_stock'] ?? 0;
    final stockStatus = item['stock_status'] ?? 'unknown';
    final hargaAsli = item['barang_harga_asli'] ?? 0;
    final hargaJual = item['barang_harga_jual'] ?? 0;
    final lastSaleDate = item['last_sale_date'] ?? 'Never';
    final daysSinceLastSale = item['days_since_last_sale'] ?? -1;
    final totalSalesCount = item['total_sales_count'] ?? 0;
    final stockGudang = item['stock_gudang'] ?? [];
    
    final statusColor = _getStatusColor(stockStatus);
    final statusText = _getStatusText(stockStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: stockStatus == 'out_of_stock' ? Colors.red : Colors.transparent,
          width: stockStatus == 'out_of_stock' ? 2 : 0,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2,
            color: statusColor,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              brandNama,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$statusText: $totalStock pcs',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (daysSinceLastSale >= _inactiveDays || daysSinceLastSale == -1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.access_time, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Tidak Laku',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          // Price info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Harga Asli - Admin only
                    if (authController.currentUser.value?.isAdmin ?? false)
                      Expanded(
                        child: _buildDetailRow(
                          'Harga Asli',
                          _formatCurrency(hargaAsli),
                          Icons.price_change,
                          Colors.blue,
                        ),
                      ),
                    Expanded(
                      child: _buildDetailRow(
                        'Harga Jual',
                        _formatCurrency(hargaJual),
                        Icons.sell,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        'Total Terjual',
                        '$totalSalesCount transaksi',
                        Icons.shopping_cart,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailRow(
                        'Penjualan Terakhir',
                        lastSaleDate == 'Never' 
                            ? 'Belum Pernah'
                            : (daysSinceLastSale >= 0 ? '$daysSinceLastSale hari lalu' : lastSaleDate),
                        Icons.history,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Stock per warehouse
          if (stockGudang.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stok per Gudang:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...stockGudang.map((stock) {
              final gudangNama = stock['gudang_nama'] ?? '-';
              final stockBarang = stock['stock_barang'] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warehouse,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          gudangNama,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$stockBarang pcs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: stockBarang == 0 
                            ? Colors.red 
                            : (stockBarang <= _lowStockThreshold ? Colors.orange : Colors.green),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
