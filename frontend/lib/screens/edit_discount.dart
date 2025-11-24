import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EditDiscount extends StatefulWidget {
  final Map<String, dynamic> barangData;
  
  const EditDiscount({
    super.key,
    required this.barangData,
  });

  @override
  State<EditDiscount> createState() => _EditDiscountState();
}

class _EditDiscountState extends State<EditDiscount> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _barangController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _barangController.dispose();
    _discountController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Initialize form with existing data
    _brandController.text = widget.barangData['brand_nama'] ?? '';
    _barangController.text = widget.barangData['barang_nama'] ?? '';
    
    final currentDiscount = widget.barangData['barang_diskon'];
    final currentDeadline = widget.barangData['barang_deadline_diskon'];
    
    _discountController.text = (currentDiscount == null || currentDiscount == '-' || currentDiscount.toString().isEmpty) 
        ? '' 
        : currentDiscount.toString();
    _deadlineController.text = (currentDeadline == null || currentDeadline == '-' || currentDeadline.toString().isEmpty) 
        ? '' 
        : currentDeadline.toString();
    
    setState(() {});
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_deadlineController.text) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) {
      _deadlineController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return null;
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  void _saveDiscount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final barangId = widget.barangData['barang_id'];
      final updateData = {
        'barang_nama': widget.barangData['barang_nama'],
        'brand_nama': widget.barangData['brand_nama'],
        'barang_harga_asli': widget.barangData['barang_harga_asli'],
        'barang_harga_jual': widget.barangData['barang_harga_jual'],
        'barang_diskon': _discountController.text.isEmpty ? '' : _discountController.text,
        'barang_deadline_diskon': _deadlineController.text.isEmpty ? '' : _deadlineController.text,
        'barang_status': widget.barangData['barang_status'],
      };

      print('EditDiscount: Starting update for barang ID: $barangId');
      final success = await dataController.updateBarang(updateData, barangId);
      print('EditDiscount: Update result: $success');

      setState(() {
        _isLoading = false;
      });

      if (success) {
        print('EditDiscount: Update successful, showing snackbar and navigating back');
        
        // Show success message
        Get.snackbar(
          'Sukses',
          'Diskon berhasil diperbarui',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
        
        // Wait a bit for the snackbar to show, then navigate back
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate back to the discount view page
        Get.offNamed('/viewDiscount');
        print('EditDiscount: Navigation back completed');
      } else {
        print('EditDiscount: Update failed');
        Get.snackbar(
          'Error',
          'Gagal memperbarui diskon',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('EditDiscount: Error occurred: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String _formatDeadline(String? deadline) {
    if (deadline == null || deadline == '-' || deadline.isEmpty) {
      return '-';
    }
    
    try {
      final deadlineDate = DateTime.parse(deadline);
      return '${deadlineDate.day}/${deadlineDate.month}/${deadlineDate.year}';
    } catch (e) {
      return deadline;
    }
  }

  bool _isDiscountExpired(String? deadline) {
    if (deadline == null || deadline == '-' || deadline.isEmpty) {
      return false;
    }
    
    try {
      final deadlineDate = DateTime.parse(deadline);
      return deadlineDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _isDiscountExpired(widget.barangData['barang_deadline_diskon']);
    
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Edit Diskon",
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
                              // Current status indicator
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isExpired ? Colors.red : Colors.green,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isExpired ? Icons.warning : Icons.check_circle,
                                      color: isExpired ? Colors.red : Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isExpired ? 'Diskon Expired' : 'Diskon Aktif',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isExpired ? Colors.red : Colors.green,
                                            ),
                                          ),
                                          if (isExpired)
                                            Text(
                                              'Masa berlaku telah habis pada ${_formatDeadline(widget.barangData['barang_deadline_diskon'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Product Info Header
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
                                      'Informasi Produk',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.mainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Brand: ${widget.barangData['brand_nama'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              Text(
                                                'Barang: ${widget.barangData['barang_nama'] ?? 'N/A'}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'ID: ${widget.barangData['barang_id'] ?? 'N/A'}',
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

                              // Brand Field (Read-only)
                              Text(
                                'Brand',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _brandController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Barang Field (Read-only)
                              Text(
                                'Nama Barang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _barangController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Discount Field (Editable)
                              Text(
                                'Diskon *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _discountController,
                                decoration: InputDecoration(
                                  hintText: 'Contoh: 10%, Rp 50.000, dll',
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
                                    return 'Diskon harus diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Deadline Field (Editable)
                              Text(
                                'Masa Berlaku',
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
                                  hintText: 'Pilih tanggal masa berlaku (opsional)',
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_today, color: AppColors.mainColor),
                                    onPressed: _selectDate,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: AppColors.mainColor),
                                  ),
                                ),
                                onTap: _selectDate,
                              ),
                              const SizedBox(height: 40),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _saveDiscount,
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
