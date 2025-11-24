import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LogsStatistics extends StatefulWidget {
  const LogsStatistics({super.key});

  @override
  State<LogsStatistics> createState() => _LogsStatisticsState();
}

class _LogsStatisticsState extends State<LogsStatistics> {
  final DataController dataController = Get.find<DataController>();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = '';
  bool _isLoading = false;
  String _viewMode = 'monthly'; // 'daily', 'monthly', 'yearly'
  String _sortOrder = 'top'; // 'top', 'bottom'
  
  List<dynamic> _items = [];
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _updatePeriodString();
    _loadReport();
  }
  
  void _updatePeriodString() {
    if (_viewMode == 'daily') {
      _selectedPeriod = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    } else if (_viewMode == 'monthly') {
      _selectedPeriod = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    } else {
      _selectedPeriod = '${_selectedDate.year}';
    }
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await dataController.getItemSalesReport(_viewMode, _selectedPeriod, _sortOrder);
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

    setState(() {
      _isLoading = false;
    });
  }

  void _processReportData() {
    final data = dataController.itemSalesReportData;
    
    if (data.isEmpty || data['items'] == null) {
      setState(() {
        _items = [];
        _totalItems = 0;
      });
      return;
    }
    
    final items = data['items'] as List<dynamic>;
    
    setState(() {
      _totalItems = items.length;
      _items = items;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: _viewMode == 'yearly' ? DatePickerMode.year : DatePickerMode.day,
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updatePeriodString();
      });
      _loadReport();
    }
  }
  
  String _getPeriodDisplayText() {
    if (_viewMode == 'daily') {
      return '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    } else if (_viewMode == 'monthly') {
      return '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
    } else {
      return 'Tahun ${_selectedDate.year}';
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final intValue = value is int ? value : (value is double ? value.toInt() : 0);
    return 'Rp ${intValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Statistik Barang",
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
                            child: Column(
                              children: [
                                // View mode selector
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildViewModeButton('Harian', 'daily'),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildViewModeButton('Bulanan', 'monthly'),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildViewModeButton('Tahunan', 'yearly'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Date selector and Refresh
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: _selectDate,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _getPeriodDisplayText(),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today, size: 20),
                                            ],
                                          ),
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
                                
                                const SizedBox(height: 12),
                                
                                // Sort order toggle
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSortButton('Terlaris', 'top', Icons.trending_up),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildSortButton('Kurang Laris', 'bottom', Icons.trending_down),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Summary card
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          color: AppColors.mainColor,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$_totalItems',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.mainColor,
                                          ),
                                        ),
                                        const Text(
                                          'Total Item',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 60,
                                      width: 1,
                                      color: Colors.grey[300],
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          _sortOrder == 'top' ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: _sortOrder == 'top' ? Colors.green : Colors.orange,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _sortOrder == 'top' ? 'Terlaris' : 'Kurang Laris',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _sortOrder == 'top' ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                        Text(
                                          'Urutan: ${_sortOrder == 'top' ? 'Tertinggi' : 'Terendah'}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
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

  Widget _buildViewModeButton(String label, String mode) {
    final isSelected = _viewMode == mode;
    return ElevatedButton(
      onPressed: () {
        if (_viewMode != mode) {
          setState(() {
            _viewMode = mode;
            _updatePeriodString();
          });
          _loadReport();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.mainColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSortButton(String label, String order, IconData icon) {
    final isSelected = _sortOrder == order;
    return ElevatedButton.icon(
      onPressed: () {
        if (_sortOrder != order) {
          setState(() {
            _sortOrder = order;
          });
          _loadReport();
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.mainColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
              'Tidak ada data penjualan',
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
        return _buildItemCard(item, index + 1);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int rank) {
    final barangNama = item['barang_nama'] ?? '-';
    final brandNama = item['brand_nama'] ?? '-';
    final totalQty = item['total_quantity_sold'] ?? 0;
    final totalRevenue = item['total_revenue'] ?? 0;
    final transactionCount = item['transaction_count'] ?? 0;
    final avgPrice = item['avg_sale_price'] ?? 0;
    
    Color rankColor = _sortOrder == 'top'
        ? (rank <= 3 ? Colors.amber : Colors.green)
        : Colors.orange;
    
    IconData rankIcon = _sortOrder == 'top'
        ? (rank == 1 ? Icons.emoji_events : Icons.trending_up)
        : Icons.trending_down;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 && _sortOrder == 'top' ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: rank <= 3 && _sortOrder == 'top' 
            ? BorderSide(color: rankColor, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(rankIcon, color: rankColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
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
                      Expanded(
                        child: _buildStatItem(
                          'Terjual',
                          '$totalQty pcs',
                          Icons.shopping_cart,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Transaksi',
                          '$transactionCount',
                          Icons.receipt,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Pendapatan',
                          _formatCurrency(totalRevenue),
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Harga Rata-rata',
                          _formatCurrency(avgPrice),
                          Icons.price_check,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
