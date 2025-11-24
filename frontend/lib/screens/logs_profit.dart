import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LogsProfit extends StatefulWidget {
  const LogsProfit({super.key});

  @override
  State<LogsProfit> createState() => _LogsProfitState();
}

class _LogsProfitState extends State<LogsProfit> {
  final DataController dataController = Get.find<DataController>();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = '';
  bool _isLoading = false;
  String _viewMode = 'monthly'; // 'daily', 'monthly', 'yearly'
  
  Map<String, dynamic> _reportData = {};
  int _totalProfit = 0;
  int _totalSales = 0;
  int _totalTransactions = 0;

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
      if (_viewMode == 'daily') {
        await dataController.getDailySalesReport(_selectedPeriod);
      } else if (_viewMode == 'monthly') {
        await dataController.getMonthlySalesReport(_selectedPeriod);
      } else {
        await dataController.getYearlySalesReport(_selectedPeriod);
      }
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
    Map<String, dynamic> data;
    
    if (_viewMode == 'daily') {
      data = dataController.dailyReportData;
    } else if (_viewMode == 'monthly') {
      data = dataController.monthlyReportData;
    } else {
      data = dataController.yearlyReportData;
    }
    
    if (data.isEmpty) {
      setState(() {
        _totalProfit = 0;
        _totalSales = 0;
        _totalTransactions = 0;
        _reportData = {};
      });
      return;
    }
    
    setState(() {
      _totalProfit = data['total_profit'] ?? 0;
      _totalSales = data['total_sales'] ?? 0;
      _totalTransactions = data['total_transactions'] ?? 0;
      _reportData = data;
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

  String _formatCurrency(int value) {
    final absValue = value.abs();
    final formatted = absValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return value < 0 ? '-Rp $formatted' : 'Rp $formatted';
  }
  
  Color _getProfitColor(int value) {
    return value < 0 ? Colors.red : Colors.green;
  }
  
  String _getProfitLabel(int value) {
    return value < 0 ? 'Kerugian' : 'Keuntungan';
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

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
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

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType) {
      case '1':
        return Colors.green;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.orange;
      default:
        return Colors.grey;
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
              title: "Statistik Keuntungan",
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
                          // View mode selector
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
                                // View mode tabs
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
                                // Date/Period selector
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
                              ],
                            ),
                          ),
                          
                          // Summary cards
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Total Profit Card
                                Card(
                                  elevation: 4,
                                  color: _getProfitColor(_totalProfit),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Text(
                                          'TOTAL ${_getProfitLabel(_totalProfit).toUpperCase()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatCurrency(_totalProfit),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Stats Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.shopping_cart,
                                                color: Colors.blue,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '$_totalTransactions',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const Text(
                                                'Transaksi',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Card(
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.attach_money,
                                                color: Colors.orange,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _formatCurrency(_totalSales),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                              const Text(
                                                'Total Penjualan',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
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
                          
                          // Transactions list
                          Expanded(
                            child: _buildTransactionsList(),
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

  Widget _buildTransactionsList() {
    final transactions = _reportData['transactions'] as List<dynamic>? ?? [];
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'di bulan ini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final salesDate = transaction['sales_date'] ?? '';
    final customerName = transaction['customer_name'] ?? 'Unknown';
    final salesTotal = transaction['sales_total'] ?? 0;
    final totalProfit = transaction['total_profit'] ?? 0;
    final paymentType = transaction['sales_payment']?.toString() ?? '1';
    final saleItems = transaction['sale_items'] as List<dynamic>? ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentTypeColor(paymentType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPaymentTypeColor(paymentType),
                    ),
                  ),
                  child: Text(
                    _getPaymentTypeText(paymentType),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPaymentTypeColor(paymentType),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Penjualan',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatCurrency(salesTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getProfitLabel(totalProfit),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatCurrency(totalProfit),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getProfitColor(totalProfit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Detail Item:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...saleItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildItemDetail(index, item);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemDetail(int index, Map<String, dynamic> item) {
    final barangNama = item['barang_nama'] ?? '-';
    final brandNama = item['brand_nama'] ?? '-';
    final amount = item['sale_items_amount'] ?? 0;
    final saleValue = item['sale_value'] ?? 0;
    final hargaAsli = item['barang_harga_asli'] ?? 0;
    final itemProfit = item['item_profit'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brandNama,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      barangNama,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah: $amount pcs',
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                'Harga Jual: ${_formatCurrency(saleValue)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harga Asli: ${_formatCurrency(hargaAsli)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getProfitColor(itemProfit).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_getProfitLabel(itemProfit)}: ${_formatCurrency(itemProfit)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getProfitColor(itemProfit),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
