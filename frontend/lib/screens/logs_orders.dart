import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LogsOrders extends StatefulWidget {
  const LogsOrders({super.key});

  @override
  State<LogsOrders> createState() => _LogsOrdersState();
}

class _LogsOrdersState extends State<LogsOrders> {
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
    _loadOrdersData();
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

  void _loadOrdersData() {
    dataController.getOrdersMasuk();
  }

  List<dynamic> _getFilteredOrders() {
    List<dynamic> orders = dataController.ordersMasukData;
    
    // Group orders by logs_id to handle batch orders
    Map<String, List<dynamic>> groupedOrders = {};
    for (var order in orders) {
      String logsId = order['logs_id'] ?? '';
      if (logsId.isEmpty) continue;
      
      if (!groupedOrders.containsKey(logsId)) {
        groupedOrders[logsId] = [];
      }
      groupedOrders[logsId]!.add(order);
    }
    
    // Convert grouped orders back to list (one entry per logs_id with all orders)
    List<dynamic> result = [];
    groupedOrders.forEach((logsId, ordersList) {
      // Use the first order as base, but add 'batch_orders' field with all orders
      var baseOrder = Map<String, dynamic>.from(ordersList[0]);
      baseOrder['batch_orders'] = ordersList;
      baseOrder['is_batch'] = ordersList.length > 1;
      result.add(baseOrder);
    });
    
    // Filter by payment type if selected
    if (_paymentTypeFilter.isNotEmpty) {
      result = result.where((order) {
        return order['orders_pay_type'].toString() == _paymentTypeFilter;
      }).toList();
    }
    
    // Filter by status if selected
    if (_statusFilter.isNotEmpty) {
      result = result.where((order) {
        return order['orders_status'].toString() == _statusFilter;
      }).toList();
    }
    
    // Filter by date if selected
    if (_dateFilter.isNotEmpty) {
      result = result.where((order) {
        final orderDate = order['orders_deadline']?.toString() ?? '';
        return orderDate == _dateFilter;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((order) {
        final batchOrders = order['batch_orders'] as List<dynamic>? ?? [];
        
        // Search across all orders in the batch
        bool matchesAnyOrder = false;
        for (var batchOrder in batchOrders) {
          final barangNama = batchOrder['barang_nama']?.toString().toLowerCase() ?? '';
          final brandNama = batchOrder['brand_nama']?.toString().toLowerCase() ?? '';
          final gudangNama = batchOrder['gudang_nama']?.toString().toLowerCase() ?? '';
          final desc = order['logs_desc']?.toString().toLowerCase() ?? '';
          
          if (barangNama.contains(_searchQuery) || 
              brandNama.contains(_searchQuery) ||
              gudangNama.contains(_searchQuery) ||
              desc.contains(_searchQuery)) {
            matchesAnyOrder = true;
            break;
          }
        }
        return matchesAnyOrder;
      }).toList();
    }
    
    return result;
  }

  String _getPaymentTypeText(int paymentType) {
    switch (paymentType) {
      case 1:
        return 'Lunas';
      case 3:
        return 'Kredit';
      default:
        return 'Unknown';
    }
  }

  String _getOrderStatusText(int status) {
    switch (status) {
      case 0:
        return 'Belum Lunas';
      case 1:
        return 'Lunas';
      default:
        return 'Unknown';
    }
  }

  Color _getPaymentTypeColor(int paymentType) {
    switch (paymentType) {
      case 1:
        return Colors.green; // Lunas
      case 3:
        return Colors.blue; // Kredit
      default:
        return Colors.grey;
    }
  }

  Color _getOrderStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.red; // Belum Lunas
      case 1:
        return Colors.green; // Lunas
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentTypeIcon(int paymentType) {
    switch (paymentType) {
      case 1:
        return Icons.check_circle; // Lunas
      case 3:
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
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Lunas'),
                onTap: () {
                  setState(() {
                    _paymentTypeFilter = '1';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.credit_card, color: Colors.blue),
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
                leading: Icon(Icons.pending, color: Colors.red),
                title: const Text('Belum Lunas'),
                onTap: () {
                  setState(() {
                    _statusFilter = '0';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Lunas'),
                onTap: () {
                  setState(() {
                    _statusFilter = '1';
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
                'Filter by Deadline',
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
                    lastDate: DateTime.now().add(const Duration(days: 1095)),
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

  void _navigateToEdit(Map<String, dynamic> order) async {
    final result = await Get.toNamed(
      RoutesClass.getEditLogsOrdersRoute(),
      arguments: order,
    );
    
    // If the edit was successful, refresh the orders
    if (result == true) {
      _loadOrdersData();
    }
  }

  void _deleteOrder(String logsId, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus pesanan "$description"?\n\nCatatan: Semua pesanan terkait akan dihapus dan stok akan dikembalikan jika pesanan sudah lunas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Close confirmation dialog first
              Navigator.pop(context);
              
              // Show loading dialog using root navigator
              if (!mounted) return;
              showDialog(
                context: this.context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Menghapus pesanan...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
              
              bool success = await dataController.deleteBarangLogs(logsId);
              
              // Close loading dialog using root navigator
              if (mounted) {
                Navigator.of(this.context, rootNavigator: true).pop();
              }
              
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan berhasil dihapus dan stok telah dikembalikan'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadOrdersData();
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus pesanan'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _changeOrderStatus(Map<String, dynamic> order, int newStatus) async {
    final isBatch = order['is_batch'] ?? false;
    final batchOrders = order['batch_orders'] as List<dynamic>? ?? [order];
    final statusText = newStatus == 1 ? 'Lunas' : 'Belum Lunas';
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Ubah Status'),
        content: Text(
          isBatch 
            ? 'Apakah Anda yakin ingin mengubah status ${batchOrders.length} pesanan menjadi "$statusText"?'
            : 'Apakah Anda yakin ingin mengubah status pesanan menjadi "$statusText"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ubah Status'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mengubah status pesanan...'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    
    try {
      bool allSuccess = true;
      int successCount = 0;
      
      if (isBatch) {
        // Update all orders in the batch
        for (var batchOrder in batchOrders) {
          final ordersId = batchOrder['orders_id'];
          final logsStatus = batchOrder['logs_status'] ?? 1;
          
          bool success;
          if (logsStatus == 1) {
            // Orders Masuk (incoming)
            success = await dataController.updateOrdersMasukStatus(ordersId, newStatus);
          } else {
            // Orders Keluar (outgoing)
            success = await dataController.updateOrdersKeluarStatus(ordersId, newStatus);
          }
          
          if (success) {
            successCount++;
          } else {
            allSuccess = false;
          }
        }
      } else {
        // Single order
        final ordersId = order['orders_id'];
        final logsStatus = order['logs_status'] ?? 1;
        
        if (logsStatus == 1) {
          allSuccess = await dataController.updateOrdersMasukStatus(ordersId, newStatus);
        } else {
          allSuccess = await dataController.updateOrdersKeluarStatus(ordersId, newStatus);
        }
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (!mounted) return;
      
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBatch 
                ? 'Semua pesanan (${batchOrders.length} item) berhasil diubah menjadi $statusText'
                : 'Status pesanan berhasil diubah menjadi $statusText'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh data
        await Future.wait([
          dataController.getBarangLogs(),
          dataController.getOrdersMasuk(),
        ]);
        
        _loadOrdersData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBatch 
                ? 'Sebagian pesanan gagal diubah ($successCount/${batchOrders.length} berhasil)'
                : 'Gagal mengubah status pesanan'
            ),
            backgroundColor: allSuccess ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
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
              title: "Riwayat Pesanan",
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
                      hintText: "Cari barang, brand, gudang, atau deskripsi...",
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
                                ? 'Jenis Bayar' 
                                : _getPaymentTypeText(int.parse(_paymentTypeFilter)),
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
                                : _getOrderStatusText(int.parse(_statusFilter)),
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
                                ? 'Deadline' 
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
                    
                    if (controller.ordersMasukData.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
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
                                "Belum ada riwayat pesanan",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Riwayat pesanan akan muncul di sini",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadOrdersData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mainColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mungkin ada masalah dengan server',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final filteredOrders = _getFilteredOrders();
                    
                    if (filteredOrders.isEmpty) {
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
                              "Pesanan tidak ditemukan",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Coba kata kunci yang berbeda",
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Menampilkan ${filteredOrders.length} pesanan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _loadOrdersData,
                                    icon: Icon(Icons.refresh, color: AppColors.mainColor),
                                    tooltip: 'Refresh',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Orders list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final isBatch = order['is_batch'] ?? false;
                              final batchOrders = order['batch_orders'] as List<dynamic>? ?? [order];
                              final firstOrder = batchOrders[0];
                              
                              // Get warehouse names from all orders in batch
                              Set<String> gudangNames = {};
                              for (var batchOrder in batchOrders) {
                                final gudangNama = batchOrder['gudang_nama'] ?? 'Unknown';
                                gudangNames.add(gudangNama);
                              }
                              final gudangDisplay = gudangNames.isEmpty 
                                  ? 'Unknown Gudang' 
                                  : gudangNames.join(', ');
                              
                              final ordersValue = firstOrder['orders_value'] ?? 0;
                              final barangNama = firstOrder['barang_nama'] ?? 'Unknown Barang';
                              final brandNama = firstOrder['brand_nama'] ?? 'Unknown Brand';
                              final ordersPayType = firstOrder['orders_pay_type'] ?? 1;
                              final ordersDeadline = firstOrder['orders_deadline'] ?? '';
                              final logsDesc = order['logs_desc'] ?? '';
                              final ordersStatus = firstOrder['orders_status'] ?? 0;
                              final ordersAmount = firstOrder['orders_amount'] ?? 0;
                              
                              // Calculate total for batch
                              int totalValue = 0;
                              int totalAmount = 0;
                              for (var batchOrder in batchOrders) {
                                int amount = (batchOrder['orders_amount'] as int?) ?? 0;
                                int value = (batchOrder['orders_value'] as int?) ?? 0;
                                totalValue += (amount * value); // Multiply quantity by unit price
                                totalAmount += amount;
                              }
                              
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
                                      // Header with brand and payment type
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  brandNama,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  barangNama,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                if (isBatch) ...[
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.purple),
                                                    ),
                                                    child: Text(
                                                      'Batch Order: ${batchOrders.length} items',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.purple,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPaymentTypeColor(ordersPayType).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getPaymentTypeColor(ordersPayType),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getPaymentTypeIcon(ordersPayType),
                                                  size: 16,
                                                  color: _getPaymentTypeColor(ordersPayType),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getPaymentTypeText(ordersPayType),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: _getPaymentTypeColor(ordersPayType),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Order details
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
                                                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Jumlah: $ordersAmount',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(Icons.warehouse, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Text(
                                                  gudangDisplay,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Deadline: $ordersDeadline',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Description
                                      if (logsDesc.isNotEmpty) ...[
                                        Text(
                                          logsDesc,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      
                                      // Batch items expandable view
                                      if (isBatch) ...[
                                        Theme(
                                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                          child: ExpansionTile(
                                            tilePadding: EdgeInsets.zero,
                                            childrenPadding: const EdgeInsets.only(top: 8),
                                            title: Text(
                                              'Lihat semua ${batchOrders.length} items',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.mainColor,
                                              ),
                                            ),
                                            iconColor: AppColors.mainColor,
                                            collapsedIconColor: AppColors.mainColor,
                                            children: batchOrders.asMap().entries.map((entry) {
                                              final itemIndex = entry.key;
                                              final batchOrder = entry.value;
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.purple.withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.purple,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            '#${itemIndex + 1}',
                                                            style: const TextStyle(
                                                              fontSize: 11,
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
                                                                batchOrder['brand_nama'] ?? 'Unknown Brand',
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                batchOrder['barang_nama'] ?? 'Unknown Item',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey[700],
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
                                                        Row(
                                                          children: [
                                                            Icon(Icons.inventory, size: 14, color: Colors.grey[600]),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '${batchOrder['orders_amount']} unit',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          _formatCurrency(batchOrder['orders_value'] as int),
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.green,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.warehouse, size: 14, color: Colors.grey[600]),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          batchOrder['gudang_nama'] ?? 'Unknown',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      
                                      // Bottom row with price, status, and edit button
                                      Row(
                                        children: [
                                          // Price
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isBatch ? 'Total Semua Item' : 'Total Harga',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                                Text(
                                                  _formatCurrency(isBatch ? totalValue : (ordersValue * ordersAmount)),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.mainColor,
                                                  ),
                                                ),
                                                if (isBatch) ...[
                                                  Text(
                                                    '${totalAmount} total unit',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          
                                          // Status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getOrderStatusColor(ordersStatus).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getOrderStatusColor(ordersStatus),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _getOrderStatusText(ordersStatus),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: _getOrderStatusColor(ordersStatus),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 12),
                                          
                                          // 3-dot menu button
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _navigateToEdit(order);
                                              } else if (value == 'delete') {
                                                _deleteOrder(order['logs_id'], logsDesc);
                                              } else if (value == 'status_lunas') {
                                                _changeOrderStatus(order, 1);
                                              } else if (value == 'status_belum_lunas') {
                                                _changeOrderStatus(order, 0);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 18),
                                                    SizedBox(width: 8),
                                                    Text('Edit Data'),
                                                  ],
                                                ),
                                              ),
                                              // Status change menu - adapts based on current status
                                              PopupMenuItem(
                                                value: ordersStatus == 1 ? 'status_belum_lunas' : 'status_lunas',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      ordersStatus == 1 ? Icons.pending : Icons.check_circle,
                                                      size: 18,
                                                      color: ordersStatus == 1 ? Colors.orange : Colors.green,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      ordersStatus == 1 ? 'Ubah ke Belum Lunas' : 'Ubah ke Lunas',
                                                      style: TextStyle(
                                                        color: ordersStatus == 1 ? Colors.orange : Colors.green,
                                                      ),
                                                    ),
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
                                            icon: const Icon(Icons.more_vert),
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
    );
  }
}
