import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EditLogsOrders extends StatefulWidget {
  final Map<String, dynamic> orderData;
  
  const EditLogsOrders({
    super.key,
    required this.orderData,
  });

  @override
  State<EditLogsOrders> createState() => _EditLogsOrdersState();
}

class _EditLogsOrdersState extends State<EditLogsOrders> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // Dropdown selections
  int _selectedPayType = 1; // 0: Barang Keluar, 1: Lunas, 2: Uang Muka, 3: Kredit
  int _selectedStatus = 0; // 0: Belum Lunas, 1: Lunas
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _deadlineController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Initialize form with existing data
    _valueController.text = widget.orderData['orders_value']?.toString() ?? '';
    _deadlineController.text = widget.orderData['orders_deadline'] ?? '';
    _amountController.text = widget.orderData['orders_amount']?.toString() ?? '';
    _selectedPayType = widget.orderData['orders_pay_type'] ?? 1;
    _selectedStatus = widget.orderData['orders_status'] ?? 0;
    
    setState(() {});
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_deadlineController.text) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) {
      setState(() {
        _deadlineController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine if this is orders_masuk or orders_keluar based on logs_status
      // logs_status = 1 (Masuk/incoming), logs_status = 2 (Keluar/outgoing)
      final logsStatus = widget.orderData['logs_status'] ?? 1;
      
      // Check if this is a batch order
      final isBatch = widget.orderData['is_batch'] ?? false;
      final batchOrders = widget.orderData['batch_orders'] as List<dynamic>? ?? [widget.orderData];
      
      // For batch orders, we need to update ALL orders in the batch
      // For single orders, just update the one order
      bool allSuccess = true;
      int successCount = 0;
      
      if (isBatch) {
        // Update all orders in the batch
        print('Updating batch order with ${batchOrders.length} items');
        
        for (var batchOrder in batchOrders) {
          final ordersId = batchOrder['orders_id'];
          
          // Prepare update data - keep individual amounts/values but update shared fields
          final updateData = {
            'orders_amount': batchOrder['orders_amount'], // Keep original amount for each item
            'orders_value': batchOrder['orders_value'],   // Keep original value for each item
            'orders_deadline': _deadlineController.text,   // Update deadline (shared)
            'orders_pay_type': _selectedPayType,          // Update pay type (shared)
            'orders_status': _selectedStatus,              // Update status (shared)
          };

          bool success;
          if (logsStatus == 1) {
            // Orders Masuk (incoming)
            success = await dataController.updateOrdersMasuk(ordersId, updateData);
          } else {
            // Orders Keluar (outgoing)
            success = await dataController.updateOrdersKeluarStatus(ordersId, _selectedStatus);
          }
          
          if (success) {
            successCount++;
          } else {
            allSuccess = false;
            print('Failed to update order: $ordersId');
          }
        }
        
        print('Updated $successCount out of ${batchOrders.length} orders');
      } else {
        // Single order - update normally
        final ordersId = widget.orderData['orders_id'];
        
        final updateData = {
          'orders_amount': int.tryParse(_amountController.text) ?? 0,
          'orders_value': int.tryParse(_valueController.text.replaceAll('.', '')) ?? 0,
          'orders_deadline': _deadlineController.text,
          'orders_pay_type': _selectedPayType,
          'orders_status': _selectedStatus,
        };

        if (logsStatus == 1) {
          allSuccess = await dataController.updateOrdersMasuk(ordersId, updateData);
        } else {
          allSuccess = await dataController.updateOrdersKeluarStatus(ordersId, _selectedStatus);
        }
      }

      if (allSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBatch 
                ? 'Semua pesanan (${batchOrders.length} item) berhasil diperbarui'
                : 'Pesanan berhasil diperbarui'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Refresh data
          await Future.wait([
            dataController.getBarangLogs(),
            dataController.getOrdersMasuk(),
          ]);
          
          // Return true to indicate successful update
          Get.back(result: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBatch 
                ? 'Sebagian pesanan gagal diperbarui ($successCount/${batchOrders.length} berhasil)'
                : 'Gagal memperbarui pesanan'),
              backgroundColor: allSuccess ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('Error saving order: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    /* OLD CODE - DEPRECATED
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ordersId = widget.orderData['orders_id'];
      final updateData = {
        'orders_amount': int.tryParse(_amountController.text) ?? 0,
        'orders_value': int.tryParse(_valueController.text.replaceAll('.', '')) ?? 0,
        'orders_deadline': _deadlineController.text,
        'orders_pay_type': _selectedPayType,
        'orders_status': _selectedStatus,
      };

      final success = await dataController.updateOrders(ordersId, updateData);

      if (success) {
        Get.snackbar(
          'Sukses',
          'Data pesanan berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        
        // Return true to indicate successful update
        Get.back(result: true);
      } else {
        Get.snackbar(
          'Error',
          'Gagal memperbarui data pesanan',
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
      print('Error saving order: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    */
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    // Remove any non-digit characters
    String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) return '';
    
    // Format with thousands separator
    int number = int.parse(cleanValue);
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBatch = widget.orderData['is_batch'] ?? false;
    final batchOrders = widget.orderData['batch_orders'] as List<dynamic>? ?? [widget.orderData];
    
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Edit Pesanan",
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
                child: _isLoading
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
                              // Batch Order Warning
                              if (isBatch) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.purple),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.purple, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Batch Order: ${batchOrders.length} items - Perubahan akan diterapkan ke semua item',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Order Info Header
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
                                      'Detail Pesanan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Brand: ${widget.orderData['brand_nama'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Barang: ${widget.orderData['barang_nama'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Gudang: ${widget.orderData['gudang_nama'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Jumlah: ${widget.orderData['orders_amount'] ?? 'N/A'}',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              'ID: ${widget.orderData['orders_id'] ?? 'N/A'}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Jumlah Barang - Hide for batch orders
                              if (!isBatch) ...[
                                Text(
                                  'Jumlah Barang *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan jumlah barang',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: AppColors.mainColor),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Jumlah barang harus diisi';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Jumlah harus berupa angka';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Total Harga - Hide for batch orders
                              if (!isBatch) ...[
                                Text(
                                  'Total Harga *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _valueController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan total harga',
                                    prefixText: 'Rp ',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: AppColors.mainColor),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Total harga harus diisi';
                                    }
                                    if (int.tryParse(value.replaceAll('.', '')) == null) {
                                      return 'Total harga harus berupa angka';
                                    }
                                  return null;
                                },
                                onChanged: (value) {
                                  String formatted = _formatCurrency(value);
                                  if (formatted != value) {
                                    _valueController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );
                                  }
                                },
                              ),
                                const SizedBox(height: 20),
                              ],

                              // Jenis Pembayaran
                              Text(
                                'Jenis Pembayaran *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedPayType,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_upward, color: Colors.blue, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Barang Keluar'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Lunas'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Row(
                                          children: [
                                            Icon(Icons.payment, color: Colors.orange, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Uang Muka'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Row(
                                          children: [
                                            Icon(Icons.credit_card, color: Colors.blue, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Kredit'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPayType = value!;
                                        // Auto-set deadline if Lunas
                                        if (value == 1) {
                                          _deadlineController.text = widget.orderData['logs_date'] ?? '';
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Deadline
                              Text(
                                'Deadline *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _deadlineController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: 'Pilih tanggal deadline',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_today, color: AppColors.mainColor),
                                    onPressed: _selectedPayType != 1 ? _selectDeadline : null,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                ),
                                validator: (value) {
                                  if (_selectedPayType != 1 && (value == null || value.isEmpty)) {
                                    return 'Deadline harus diisi untuk jenis pembayaran ini';
                                  }
                                  return null;
                                },
                                onTap: _selectedPayType != 1 ? _selectDeadline : null,
                              ),
                              const SizedBox(height: 20),

                              // Status Pesanan
                              Text(
                                'Status Pesanan *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedStatus,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: 0,
                                        child: Row(
                                          children: [
                                            Icon(Icons.pending, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Belum Lunas'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Lunas'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveOrder,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Simpan Perubahan',
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
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
