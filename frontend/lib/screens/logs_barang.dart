import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LogsBarang extends StatefulWidget {
  const LogsBarang({super.key});

  @override
  State<LogsBarang> createState() => _LogsBarangState();
}

class _LogsBarangState extends State<LogsBarang> {
  final DataController dataController = Get.find<DataController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = '';
  String _dateFilter = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadLogsData();
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

  void _loadLogsData() {
    dataController.getBarangLogs();
  }

  List<dynamic> _getFilteredLogs() {
    List<dynamic> logs = dataController.barangLogs;
    
    // Filter to show only logs_status = 2 (Keluar) for Riwayat Barang
    logs = logs.where((log) {
      return log['logs_status'] == 2;
    }).toList();
    
    // Filter out logs with no orders (old logs before database restructure)
    logs = logs.where((log) {
      final orders = log['orders'] as List<dynamic>? ?? [];
      return orders.isNotEmpty;
    }).toList();
    
    // Filter by status if selected
    if (_statusFilter.isNotEmpty) {
      logs = logs.where((log) {
        return log['logs_status'].toString() == _statusFilter;
      }).toList();
    }
    
    // Filter by date if selected
    if (_dateFilter.isNotEmpty) {
      logs = logs.where((log) {
        final logDate = log['logs_date']?.toString() ?? '';
        return logDate == _dateFilter;
      }).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      logs = logs.where((log) {
        final gudangNama = log['gudang_nama']?.toString().toLowerCase() ?? '';
        final desc = log['logs_desc']?.toString().toLowerCase() ?? '';
        
        // Also search in orders data
        bool matchesOrders = false;
        if (log['orders'] != null && log['orders'] is List) {
          for (var order in log['orders']) {
            final barangNama = order['barang_nama']?.toString().toLowerCase() ?? '';
            final brandNama = order['brand_nama']?.toString().toLowerCase() ?? '';
            if (barangNama.contains(_searchQuery) || brandNama.contains(_searchQuery)) {
              matchesOrders = true;
              break;
            }
          }
        }
        
        return gudangNama.contains(_searchQuery) ||
               desc.contains(_searchQuery) ||
               matchesOrders;
      }).toList();
    }
    
    return logs;
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Masuk';
      case 2:
        return 'Keluar';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green; // Masuk
      case 2:
        return Colors.orange; // Keluar
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.arrow_downward; // Masuk
      case 2:
        return Icons.arrow_upward; // Keluar
      default:
        return Icons.help;
    }
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
                leading: Icon(Icons.arrow_downward, color: Colors.green),
                title: const Text('Masuk'),
                onTap: () {
                  setState(() {
                    _statusFilter = '1';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: Colors.orange),
                title: const Text('Keluar'),
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

  // DEPRECATED: This method is no longer used with the new orders_masuk/orders_keluar structure
  // Status updates now happen at the individual order level via orders_masuk or orders_keluar tables
  // void _updateLogsDone(String logsId, int logsDone) async {
  //   // This functionality is obsolete - logs_done field removed from barang_logs table
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('Fitur ini tidak tersedia. Status dikelola per item di tabel orders.'),
  //       backgroundColor: Colors.orange,
  //     ),
  //   );
  // }

  void _navigateToEdit(Map<String, dynamic> log) async {
    final result = await Get.toNamed(
      RoutesClass.getEditLogsBarangRoute(),
      arguments: log,
    );
    
    // If the edit was successful, refresh the logs
    if (result == true) {
      _loadLogsData();
    }
  }

  void _deleteLog(String logsId, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus log "$description"?\n\nCatatan: Semua pesanan terkait akan dihapus dan stok akan dikembalikan jika pesanan sudah selesai.'),
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
                              Text('Menghapus log...'),
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
                    content: Text('Log berhasil dihapus dan stok telah dikembalikan'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadLogsData();
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus log'),
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

  void _updateOrdersStatus(List<dynamic> orders, bool currentlyDone) async {
    // Get the new status
    final newStatus = currentlyDone ? 0 : 1;
    final statusText = newStatus == 1 ? 'Selesai' : 'Pending';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Ubah Status'),
        content: Text('Apakah Anda yakin ingin mengubah status semua item ke $statusText?'),
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
                              Text('Mengubah status...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
              
              bool allSuccess = true;
              for (var order in orders) {
                final ordersId = order['orders_id'];
                bool success = await dataController.updateOrdersKeluarStatus(ordersId, newStatus);
                if (!success) {
                  allSuccess = false;
                  break;
                }
              }
              
              // Close loading dialog using root navigator
              if (mounted) {
                Navigator.of(this.context, rootNavigator: true).pop();
              }
              
              if (!mounted) return;
              
              if (allSuccess) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Status berhasil diubah ke $statusText'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadLogsData();
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal mengubah status'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Ubah ke $statusText'),
          ),
        ],
      ),
    );
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
              title: "Riwayat Barang",
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
                      // Status Filter Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showStatusFilter,
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 16),
                          label: Text(
                            _statusFilter.isEmpty 
                                ? 'Filter Status' 
                                : 'Status: ${_getStatusText(int.parse(_statusFilter))}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _statusFilter.isEmpty 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.3),
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
                                ? 'Filter Tanggal' 
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
                  if (_statusFilter.isNotEmpty || _selectedDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
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
                    
                    if (controller.barangLogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Belum ada riwayat barang",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Riwayat transaksi akan muncul di sini",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final filteredLogs = _getFilteredLogs();
                    
                    if (filteredLogs.isEmpty) {
                      // Check if we have logs but they're filtered out
                      final totalLogs = controller.barangLogs.where((log) => log['logs_status'] == 2).length;
                      final logsWithOrders = controller.barangLogs.where((log) {
                        if (log['logs_status'] != 2) return false;
                        final orders = log['orders'] as List<dynamic>? ?? [];
                        return orders.isNotEmpty;
                      }).length;
                      
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
                              "Logs tidak ditemukan",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalLogs > 0 
                                ? "Ada $totalLogs logs keluar, tapi $logsWithOrders memiliki data orders"
                                : "Belum ada riwayat barang keluar",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty || _statusFilter.isNotEmpty || _dateFilter.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                "Coba hapus filter untuk melihat semua data",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Riwayat (${filteredLogs.length})",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_statusFilter.isNotEmpty || _selectedDate != null) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              if (_statusFilter.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.blue),
                                                  ),
                                                  child: Text(
                                                    'Status: ${_getStatusText(int.parse(_statusFilter))}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.blue),
                                                  ),
                                                ),
                                              if (_selectedDate != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.purple),
                                                  ),
                                                  child: Text(
                                                    'Tanggal: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                                    style: const TextStyle(fontSize: 11, color: Colors.purple),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _loadLogsData,
                                    icon: Icon(
                                      Icons.refresh,
                                      color: AppColors.mainColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Logs list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredLogs.length,
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              final logsStatus = log['logs_status'] ?? 0;
                              final logsDate = log['logs_date'] ?? '';
                              final logsDesc = log['logs_desc'] ?? '';
                              final orders = log['orders'] as List<dynamic>? ?? [];
                              
                              // Check if all orders in this log are done (orders_status = 1)
                              bool allOrdersDone = orders.isNotEmpty && 
                                  orders.every((order) => (order['orders_status'] ?? 0) == 1);
                              
                              // Get warehouse names from orders
                              Set<String> gudangNames = {};
                              for (var order in orders) {
                                final gudangNama = order['gudang_nama'] ?? 'Unknown';
                                gudangNames.add(gudangNama);
                              }
                              final gudangDisplay = gudangNames.isEmpty 
                                  ? 'Unknown Gudang' 
                                  : gudangNames.join(', ');
                              
                              // Get first order for primary display (if exists)
                              final hasOrders = orders.isNotEmpty;
                              final isBatchOrder = orders.length > 1;
                              final firstOrder = hasOrders ? orders[0] : null;
                              final brandNama = firstOrder?['brand_nama'] ?? 'No Items';
                              final barangNama = firstOrder?['barang_nama'] ?? 'No items in this log';
                              
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
                                      // Header with brand name and status
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
                                                const SizedBox(height: 4),
                                                Text(
                                                  barangNama,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (isBatchOrder) ...[
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.blue),
                                                    ),
                                                    child: Text(
                                                      'Batch Order: ${orders.length} items',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.blue,
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
                                              color: _getStatusColor(logsStatus).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(logsStatus),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(logsStatus),
                                                  size: 16,
                                                  color: _getStatusColor(logsStatus),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getStatusText(logsStatus),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getStatusColor(logsStatus),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Order details container (warehouse, date, amount)
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
                                                Icon(
                                                  Icons.warehouse,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Gudang',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        gudangDisplay,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (hasOrders) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${firstOrder!['orders_amount']} unit',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  logsDate,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
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
                                      if (isBatchOrder) ...[
                                        Theme(
                                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                          child: ExpansionTile(
                                            tilePadding: EdgeInsets.zero,
                                            childrenPadding: const EdgeInsets.only(top: 8),
                                            title: Text(
                                              'Lihat semua ${orders.length} items',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.mainColor,
                                              ),
                                            ),
                                            iconColor: AppColors.mainColor,
                                            collapsedIconColor: AppColors.mainColor,
                                            children: orders.asMap().entries.map((entry) {
                                              final itemIndex = entry.key;
                                              final order = entry.value;
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue.withOpacity(0.2),
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
                                                            color: Colors.blue,
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
                                                                order['brand_nama'] ?? 'Unknown Brand',
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                order['barang_nama'] ?? 'Unknown Item',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey[700],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            '${order['orders_amount']} unit',
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.green,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (order['orders_value'] != null && logsStatus == 1) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Harga: ',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            _formatCurrency(order['orders_value'] as int),
                                                            style: const TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      
                                      // Bottom row with price/status and action buttons
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Price display (only for Barang Masuk)
                                          if (hasOrders && firstOrder!['orders_value'] != null && logsStatus == 1) ...[
                                            Row(
                                              children: [
                                                Text(
                                                  'Total: ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    _formatCurrency(firstOrder['orders_value'] as int),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.mainColor,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          
                                          // Bottom row with status badge and buttons
                                          Row(
                                            children: [
                                              // Status badge - based on individual order status
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (allOrdersDone ? Colors.green : Colors.orange).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: allOrdersDone ? Colors.green : Colors.orange,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      allOrdersDone ? Icons.check_circle : Icons.pending,
                                                      size: 16,
                                                      color: allOrdersDone ? Colors.green : Colors.orange,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      allOrdersDone ? "Selesai" : "Pending",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: allOrdersDone ? Colors.green : Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              const Spacer(),
                                              
                                              // 3-dot menu button
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'edit') {
                                                    _navigateToEdit(log);
                                                  } else if (value == 'status') {
                                                    _updateOrdersStatus(orders, allOrdersDone);
                                                  } else if (value == 'delete') {
                                                    _deleteLog(log['logs_id'], logsDesc);
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
                                                  PopupMenuItem(
                                                    value: 'status',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          allOrdersDone ? Icons.pending : Icons.check_circle,
                                                          size: 18,
                                                          color: allOrdersDone ? Colors.orange : Colors.green,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(allOrdersDone ? 'Ubah ke Pending' : 'Ubah ke Selesai'),
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
