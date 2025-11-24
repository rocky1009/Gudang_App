import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';

class AllSales extends StatefulWidget {
  const AllSales({super.key});

  @override
  State<AllSales> createState() => _AllSalesState();
}

class _AllSalesState extends State<AllSales> {
  final DataController dataController = Get.find<DataController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _paymentTypeFilter = '';
  String _statusFilter = '';
  String _dateFilter = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
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

  void _loadSalesData() {
    dataController.getSalesData();
  }

  List<dynamic> _getFilteredSales() {
    List<dynamic> sales = dataController.salesData;
    
    // Filter by payment type if selected
    if (_paymentTypeFilter.isNotEmpty) {
      sales = sales.where((sale) {
        return sale['sales_payment'].toString() == _paymentTypeFilter;
      }).toList();
    }
    
    // Filter by status if selected
    if (_statusFilter.isNotEmpty) {
      sales = sales.where((sale) {
        return sale['sales_status'].toString() == _statusFilter;
      }).toList();
    }
    
    // Filter by date if selected
    if (_dateFilter.isNotEmpty) {
      sales = sales.where((sale) {
        final saleDate = sale['sales_date']?.toString() ?? '';
        return saleDate == _dateFilter;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      sales = sales.where((sale) {
        final salesId = sale['sales_id']?.toString().toLowerCase() ?? '';
        final customerName = sale['customer_name']?.toString().toLowerCase() ?? '';
        final customerKontak = sale['customer_kontak']?.toString().toLowerCase() ?? '';
        final customerAlamat = sale['customer_alamat']?.toString().toLowerCase() ?? '';
        
        // Check basic fields
        bool matchesBasicFields = salesId.contains(_searchQuery) || 
               customerName.contains(_searchQuery) ||
               customerKontak.contains(_searchQuery) ||
               customerAlamat.contains(_searchQuery);
        
        if (matchesBasicFields) return true;
        
        // Check sale items for barang_nama
        final saleItems = sale['sale_items'] as List<dynamic>?;
        if (saleItems != null && saleItems.isNotEmpty) {
          return saleItems.any((item) {
            final barangNama = item['barang_nama']?.toString().toLowerCase() ?? '';
            return barangNama.contains(_searchQuery);
          });
        }
        
        return false;
      }).toList();
    }
    
    return sales;
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

  String _getSalesStatusText(int status) {
    switch (status) {
      case 1:
        return 'Selesai';
      case 2:
        return 'Diproses';
      default:
        return 'Unknown';
    }
  }

  Color _getPaymentTypeColor(String paymentType) {
    switch (paymentType) {
      case '1':
        return Colors.green; // Tunai
      case '2':
        return Colors.blue; // Transfer
      case '3':
        return Colors.orange; // Kredit
      default:
        return Colors.grey;
    }
  }

  Color _getSalesStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green; // Selesai
      case 2:
        return Colors.orange; // Diproses
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentTypeIcon(String paymentType) {
    switch (paymentType) {
      case '1':
        return Icons.money; // Tunai
      case '2':
        return Icons.account_balance; // Transfer
      case '3':
        return Icons.credit_card; // Kredit
      default:
        return Icons.help;
    }
  }

  void _showPaymentTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Payment Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Semua Jenis Pembayaran'),
                onTap: () {
                  setState(() {
                    _paymentTypeFilter = '';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.money, color: Colors.green),
                title: const Text('Tunai'),
                onTap: () {
                  setState(() {
                    _paymentTypeFilter = '1';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance, color: Colors.blue),
                title: const Text('Transfer'),
                onTap: () {
                  setState(() {
                    _paymentTypeFilter = '2';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.credit_card, color: Colors.orange),
                title: const Text('Kredit'),
                onTap: () {
                  setState(() {
                    _paymentTypeFilter = '3';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Semua Status'),
                onTap: () {
                  setState(() {
                    _statusFilter = '';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Selesai'),
                onTap: () {
                  setState(() {
                    _statusFilter = '1';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.pending, color: Colors.orange),
                title: const Text('Diproses'),
                onTap: () {
                  setState(() {
                    _statusFilter = '2';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDateFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Semua Tanggal'),
                onTap: () {
                  setState(() {
                    _dateFilter = '';
                    _selectedDate = null;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Pilih Tanggal'),
                onTap: () async {
                  Navigator.pop(context);
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateFilter = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              if (_selectedDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Filter aktif: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _navigateToView(Map<String, dynamic> sale) async {
    final result = await Get.toNamed(
      RoutesClass.getViewSalesRoute(),
      arguments: sale,
    );
    
    if (result == true) {
      _loadSalesData();
    }
  }

  void _navigateToEdit(Map<String, dynamic> sale) async {
    final result = await Get.toNamed(
      RoutesClass.getEditSalesRoute(),
      arguments: sale,
    );
    
    if (result == true) {
      _loadSalesData();
    }
  }

  void _deleteSale(String salesId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penjualan'),
        content: const Text('Apakah Anda yakin ingin menghapus penjualan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bool success = await dataController.deleteSales(salesId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penjualan berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSalesData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus penjualan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateReceipt(Map<String, dynamic> sale) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get full sale data with items
      await dataController.getSingleSalesData(sale['sales_id']);
      final fullSaleData = dataController.singleSalesData;
      
      // Generate receipt
      final pdfBytes = await PdfService.generateReceipt(fullSaleData);
      final filename = PdfService.generateReceiptFilename(fullSaleData);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Open print/share dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat struk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateInvoice(Map<String, dynamic> sale) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get full sale data with items
      await dataController.getSingleSalesData(sale['sales_id']);
      final fullSaleData = dataController.singleSalesData;
      
      // Generate invoice
      final pdfBytes = await PdfService.generateInvoice(fullSaleData);
      final filename = PdfService.generateInvoiceFilename(fullSaleData);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Open print/share dialog
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Daftar Penjualan",
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
                      hintText: "Cari customer, item barang, atau kontak...",
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
                  // Filter Buttons
                  Row(
                    children: [
                      // Payment Type Filter Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showPaymentTypeFilter,
                          icon: const Icon(Icons.payment, color: Colors.white, size: 16),
                          label: Text(
                            _paymentTypeFilter.isEmpty 
                                ? 'Pembayaran' 
                                : _getPaymentTypeText(_paymentTypeFilter),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _paymentTypeFilter.isEmpty 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Filter Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showStatusFilter,
                          icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                          label: Text(
                            _statusFilter.isEmpty 
                                ? 'Status' 
                                : _getSalesStatusText(int.parse(_statusFilter)),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _statusFilter.isEmpty 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.green.withOpacity(0.3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date Filter Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDateFilter,
                          icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                          label: Text(
                            _selectedDate == null 
                                ? 'Tanggal' 
                                : '${_selectedDate!.day}/${_selectedDate!.month}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedDate == null 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.purple.withOpacity(0.3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Clear filters row
                  if (_paymentTypeFilter.isNotEmpty || _statusFilter.isNotEmpty || _selectedDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _paymentTypeFilter = '';
                              _statusFilter = '';
                              _dateFilter = '';
                              _selectedDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all, color: Colors.white70, size: 16),
                          label: const Text(
                            'Hapus Semua Filter',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
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

                    final filteredSales = _getFilteredSales();
                    
                    if (filteredSales.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada penjualan',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || 
                              _paymentTypeFilter.isNotEmpty || 
                              _statusFilter.isNotEmpty || 
                              _selectedDate != null
                                  ? 'Tidak ada hasil dengan filter yang dipilih'
                                  : 'Belum ada data penjualan',
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
                        _loadSalesData();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          return _buildSaleCard(sale);
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
        onPressed: () async {
          final result = await Get.toNamed(RoutesClass.getAddSalesRoute());
          if (result == true) {
            _loadSalesData();
          }
        },
        backgroundColor: AppColors.mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final salesId = sale['sales_id'] ?? '';
    final customerName = sale['customer_name'] ?? 'Unknown Customer';
    final customerKontak = sale['customer_kontak'] ?? '';
    final customerAlamat = sale['customer_alamat'] ?? '';
    final salesTotal = sale['sales_total'] ?? 0;
    final salesPayment = sale['sales_payment']?.toString() ?? '1';
    final salesDate = sale['sales_date'] ?? '';
    final salesStatus = sale['sales_status'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToView(sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (customerKontak.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customerKontak,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (customerAlamat.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 13, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customerAlamat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Lihat Detail'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print_receipt',
                        child: Row(
                          children: [
                            Icon(Icons.receipt, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Print Struk', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'print_invoice',
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Print Invoice', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _navigateToView(sale);
                      } else if (value == 'edit') {
                        _navigateToEdit(sale);
                      } else if (value == 'print_receipt') {
                        _generateReceipt(sale);
                      } else if (value == 'print_invoice') {
                        _generateInvoice(sale);
                      } else if (value == 'delete') {
                        _deleteSale(salesId);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(salesTotal),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Payment Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPaymentTypeColor(salesPayment).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getPaymentTypeColor(salesPayment)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPaymentTypeIcon(salesPayment),
                              size: 14,
                              color: _getPaymentTypeColor(salesPayment),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPaymentTypeText(salesPayment),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getPaymentTypeColor(salesPayment),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSalesStatusColor(salesStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getSalesStatusColor(salesStatus)),
                        ),
                        child: Text(
                          _getSalesStatusText(salesStatus),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getSalesStatusColor(salesStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
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
      ),
    );
  }
}
