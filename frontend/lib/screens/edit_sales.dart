import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EditSales extends StatefulWidget {
  final Map<String, dynamic> salesData;
  
  const EditSales({
    super.key,
    required this.salesData,
  });

  @override
  State<EditSales> createState() => _EditSalesState();
}

class _EditSalesState extends State<EditSales> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for sales header
  final TextEditingController _dateController = TextEditingController();
  
  // Sales selections
  String? _selectedCustomerId;
  String _selectedPayment = '1';
  int _selectedStatus = 1;
  
  // Sale items from backend
  List<dynamic> _saleItems = [];
  
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all necessary data
      await Future.wait([
        dataController.getCustomerData(),
        dataController.getSingleSalesData(widget.salesData['sales_id']),
      ]);
      
      final salesDetail = dataController.singleSalesData;
      
      // Initialize form with existing data
      _dateController.text = salesDetail['sales_date'] ?? '';
      _selectedCustomerId = salesDetail['customer_id'];
      _selectedPayment = salesDetail['sales_payment']?.toString() ?? '1';
      _selectedStatus = salesDetail['sales_status'] ?? 1;
      _saleItems = salesDetail['sale_items'] ?? [];
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing data: $e');
    }

    setState(() {
      _isLoading = false;
    });
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
        return Colors.green;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getSalesStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  int _calculateTotal() {
    int total = 0;
    for (var item in _saleItems) {
      final amount = item['sale_items_amount'] is int 
          ? item['sale_items_amount'] as int
          : (item['sale_items_amount'] as num?)?.toInt() ?? 0;
      final value = item['sale_value'] is int 
          ? item['sale_value'] as int
          : (item['sale_value'] as num?)?.toInt() ?? 0;
      total += amount * value;
    }
    return total;
  }

  void _editItem(int index) async {
    final item = _saleItems[index];
    
    final TextEditingController amountController = TextEditingController(
      text: item['sale_items_amount']?.toString() ?? '0',
    );
    final TextEditingController valueController = TextEditingController(
      text: item['sale_value']?.toString() ?? '0',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item ${index + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barang: ${item['barang_nama'] ?? '-'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gudang: ${item['gudang_nama'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lantai: ${item['lantai_nama'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga Jual (Rp)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newAmount = int.tryParse(amountController.text) ?? 0;
                final newValue = int.tryParse(valueController.text) ?? 0;
                
                if (newAmount <= 0 || newValue <= 0) {
                  Get.snackbar(
                    'Error',
                    'Jumlah dan harga harus lebih dari 0',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                // Update via API
                final updateData = {
                  'barang_id': item['barang_id'],
                  'gudang_id': item['gudang_id'],
                  'sale_items_amount': newAmount,
                  'sale_value': newValue,
                };

                final success = await dataController.updateSaleItem(
                  item['sale_items_id'],
                  updateData,
                );

                if (success) {
                  setState(() {
                    _saleItems[index]['sale_items_amount'] = newAmount;
                    _saleItems[index]['sale_value'] = newValue;
                  });
                  Get.snackbar(
                    'Sukses',
                    'Item berhasil diperbarui',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                  Navigator.pop(context);
                } else {
                  Get.snackbar(
                    'Error',
                    'Gagal memperbarui item',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
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
      final item = _saleItems[index];
      final success = await dataController.deleteSaleItem(item['sale_items_id']);
      
      if (success) {
        setState(() {
          _saleItems.removeAt(index);
        });
        Get.snackbar(
          'Sukses',
          'Item berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Gagal menghapus item',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _saveSales() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomerId == null) {
      Get.snackbar(
        'Error',
        'Pilih customer terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_saleItems.isEmpty) {
      Get.snackbar(
        'Error',
        'Minimal harus ada 1 item penjualan',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final salesId = widget.salesData['sales_id'];
      final updateData = {
        'customer_id': _selectedCustomerId,
        'sales_payment': _selectedPayment,
        'sales_date': _dateController.text,
        'sales_status': _selectedStatus,
      };

      final success = await dataController.updateSales(salesId, updateData);

      if (success) {
        Get.snackbar(
          'Sukses',
          'Data penjualan berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Return true to indicate successful update
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Error',
          'Gagal memperbarui data penjualan',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      print('Error saving sales: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              title: "Edit Penjualan",
            ),
            Expanded(
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _isLoading && !_isInitialized
                    ? Center(
                        child: SpinKitCircle(
                          color: AppColors.mainColor,
                          size: 50.0,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sales Info Header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detail Penjualan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ID: ${widget.salesData['sales_id'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Customer Selection
                              Text(
                                'Customer *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedCustomerId,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                ),
                                hint: const Text('Pilih Customer'),
                                items: dataController.customerData.map((customer) {
                                  return DropdownMenuItem<String>(
                                    value: customer['customer_id'],
                                    child: Text(customer['customer_nama'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCustomerId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih customer';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Date Field
                              Text(
                                'Tanggal Penjualan *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                onTap: _selectDate,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih tanggal';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Payment Type
                              Text(
                                'Jenis Pembayaran *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedPayment,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '1', child: Text('Tunai')),
                                  DropdownMenuItem(value: '2', child: Text('Transfer')),
                                  DropdownMenuItem(value: '3', child: Text('Kredit')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPayment = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Status
                              Text(
                                'Status Penjualan *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('Selesai')),
                                  DropdownMenuItem(value: 2, child: Text('Diproses')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Sale Items Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Item Penjualan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_saleItems.length} item',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              if (_saleItems.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Tidak ada item. Minimal harus ada 1 item.',
                                          style: TextStyle(color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._saleItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return _buildSaleItemCard(index, item);
                                }).toList(),
                              
                              const SizedBox(height: 24),
                              
                              // Total
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue, width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Penjualan:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(_calculateTotal()),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Get.back();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Batal'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveSales,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.mainColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Simpan Perubahan',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
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

  Widget _buildSaleItemCard(int index, Map<String, dynamic> item) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editItem(index),
                      tooltip: 'Edit',
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _deleteItem(index),
                      tooltip: 'Hapus',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            Text(
              item['barang_nama'] ?? '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gudang: ${item['gudang_nama'] ?? '-'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lantai: ${item['lantai_nama'] ?? '-'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${item['sale_items_amount'] ?? 0} pcs',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Satuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatCurrency(item['sale_value'] ?? 0),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency((item['sale_items_amount'] ?? 0) * (item['sale_value'] ?? 0)),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
}
