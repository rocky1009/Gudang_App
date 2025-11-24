import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AddDiscount extends StatefulWidget {
  const AddDiscount({super.key});

  @override
  State<AddDiscount> createState() => _AddDiscountState();
}

class _AddDiscountState extends State<AddDiscount> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  
  // Dropdown selections
  String? _selectedBrandId;
  String? _selectedBarangId;
  
  // Filtered lists
  List<dynamic> _filteredBarang = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all required data
      await Future.wait([
        dataController.getData(), // Load brands
        dataController.getBarangData(), // Load barang
      ]);
    } catch (e) {
      print('Error in _initializeData: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterBarangByBrand(String? brandId) {
    if (brandId == null) {
      _filteredBarang = [];
      return;
    }
    
    // First, find the brand name for this brandId
    final selectedBrand = dataController.myData.firstWhere(
      (brand) => brand['brand_id'] == brandId,
      orElse: () => null,
    );
    
    if (selectedBrand == null) {
      _filteredBarang = [];
      return;
    }
    
    final brandName = selectedBrand['brand_nama'];
    
    // Filter barang by brand name
    _filteredBarang = dataController.barangData.where((barang) {
      return barang['brand_nama'] == brandName;
    }).toList();
    
    setState(() {
      _selectedBarangId = null; // Reset barang selection
      _discountController.clear();
      _deadlineController.clear();
    });
  }

  void _onBarangSelected(String? barangId) {
    if (barangId == null) {
      _discountController.clear();
      _deadlineController.clear();
      return;
    }
    
    // Find the selected barang
    final selectedBarang = dataController.barangData.firstWhere(
      (barang) => barang['barang_id'] == barangId,
      orElse: () => null,
    );
    
    if (selectedBarang != null) {
      // Auto-fill discount fields
      final currentDiscount = selectedBarang['barang_diskon'];
      final currentDeadline = selectedBarang['barang_deadline_diskon'];
      
      _discountController.text = (currentDiscount == null || currentDiscount == '-' || currentDiscount.toString().isEmpty) 
          ? '' 
          : currentDiscount.toString();
      _deadlineController.text = (currentDeadline == null || currentDeadline == '-' || currentDeadline.toString().isEmpty) 
          ? '' 
          : currentDeadline.toString();
    }
    
    setState(() {
      _selectedBarangId = barangId;
    });
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

    if (_selectedBrandId == null || _selectedBarangId == null) {
      Get.snackbar(
        'Error',
        'Silakan pilih brand dan barang terlebih dahulu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Find the selected barang to get all its data
      final selectedBarang = dataController.barangData.firstWhere(
        (barang) => barang['barang_id'] == _selectedBarangId,
        orElse: () => null,
      );

      if (selectedBarang == null) {
        throw Exception('Barang tidak ditemukan');
      }

      final updateData = {
        'barang_nama': selectedBarang['barang_nama'],
        'brand_nama': selectedBarang['brand_nama'],
        'barang_harga_asli': selectedBarang['barang_harga_asli'],
        'barang_harga_jual': selectedBarang['barang_harga_jual'],
        'barang_diskon': _discountController.text.isEmpty ? '' : _discountController.text,
        'barang_deadline_diskon': _deadlineController.text.isEmpty ? '' : _deadlineController.text,
        'barang_status': selectedBarang['barang_status'],
      };

      print('AddDiscount: Starting update for barang ID: $_selectedBarangId');
      final success = await dataController.updateBarang(updateData, _selectedBarangId!);
      print('AddDiscount: Update result: $success');

      setState(() {
        _isLoading = false;
      });

      if (success) {
        print('AddDiscount: Update successful, showing snackbar and navigating back');
        
        Get.snackbar(
          'Sukses',
          'Diskon berhasil disimpan',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
        
        // Wait a bit for the snackbar to show, then navigate back
        await Future.delayed(const Duration(milliseconds: 800));
        
        // Navigate back to the discount view page
        Get.offNamed('/viewDiscount');
        print('AddDiscount: Navigation back completed');
      } else {
        print('AddDiscount: Update failed');
        Get.snackbar(
          'Error',
          'Gagal menyimpan diskon',
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
      print('AddDiscount: Error occurred: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Tambah Diskon",
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
                              // Brand Selection
                              Text(
                                'Brand *',
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
                                  child: DropdownButton<String>(
                                    value: _selectedBrandId,
                                    hint: const Text('Pilih Brand'),
                                    isExpanded: true,
                                    items: dataController.myData.map<DropdownMenuItem<String>>((brand) {
                                      return DropdownMenuItem<String>(
                                        value: brand['brand_id'],
                                        child: Text(brand['brand_nama'] ?? 'Unknown Brand'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedBrandId = value;
                                      });
                                      _filterBarangByBrand(value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Barang Selection
                              Text(
                                'Nama Barang *',
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
                                  child: DropdownButton<String>(
                                    value: _selectedBarangId,
                                    hint: Text(_selectedBrandId == null 
                                        ? 'Pilih Brand terlebih dahulu' 
                                        : 'Pilih Barang'),
                                    isExpanded: true,
                                    items: _filteredBarang.map<DropdownMenuItem<String>>((barang) {
                                      return DropdownMenuItem<String>(
                                        value: barang['barang_id'],
                                        child: Text(barang['barang_nama'] ?? 'Unknown Barang'),
                                      );
                                    }).toList(),
                                    onChanged: _selectedBrandId == null ? null : (value) {
                                      _onBarangSelected(value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Auto-filled discount info section
                              if (_selectedBarangId != null) ...[
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
                                        'Data Diskon Saat Ini',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mainColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Data di bawah akan diperbarui dengan informasi yang Anda masukkan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Discount Field
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

                              // Deadline Field
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
                                          'Simpan Diskon',
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
