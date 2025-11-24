import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/data_controller.dart';
import '../widgets/textfield_widget.dart';
import '../widgets/button_widget.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../routes/routes.dart';

class AddBarang extends StatefulWidget {
  const AddBarang({super.key});

  @override
  State<AddBarang> createState() => _AddBarangState();
}

class _AddBarangState extends State<AddBarang> {
  final DataController dataController = Get.find<DataController>();
  
  // Text controllers
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaAsliController = TextEditingController();
  final TextEditingController hargaJualController = TextEditingController();
  final TextEditingController promoController = TextEditingController();
  final TextEditingController diskonController = TextEditingController();
  
  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Selected brand
  Map<String, dynamic>? selectedBrand;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupPriceFormatting();
  }
  
  void _setupPriceFormatting() {
    hargaAsliController.addListener(() {
      _formatCurrencyInput(hargaAsliController);
    });
    hargaJualController.addListener(() {
      _formatCurrencyInput(hargaJualController);
    });
  }
  
  void _formatCurrencyInput(TextEditingController controller) {
    String text = controller.text;
    if (text.isEmpty) return;
    
    // Remove all dots
    String cleanText = text.replaceAll('.', '');
    
    // If the cleaned text is not a valid number, don't format
    if (int.tryParse(cleanText) == null) return;
    
    // Format with dots
    String formatted = AppConstants.formatCurrency(cleanText);
    
    // Only update if different to avoid infinite loop
    if (formatted != text) {
      int cursorPosition = controller.selection.start;
      
      // Calculate cursor position adjustment
      int oldDots = text.split('.').length - 1;
      int newDots = formatted.split('.').length - 1;
      int cursorAdjustment = newDots - oldDots;
      
      // Ensure cursor position is within bounds
      int newCursorPosition = (cursorPosition + cursorAdjustment).clamp(0, formatted.length);
      
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }
  
  void _initializeData() {
    // Load brands data
    dataController.getData(); // This loads brand data
  }
  
  // Calculate status based on default (will be updated when stock is added)
  int _calculateStatus() {
    return 0; // Default to 'Habis' since no stock is added yet
  }
  
  // Submit form
  void _submitForm() {
    // Basic validation
    if (namaController.text.isEmpty) {
      Get.snackbar("Error", "Nama barang tidak boleh kosong", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    int hargaAsli = AppConstants.parseCurrency(hargaAsliController.text);
    int hargaJual = AppConstants.parseCurrency(hargaJualController.text);
    
    if (hargaAsli <= 0) {
      Get.snackbar("Error", "Harga asli harus berupa angka yang valid", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (hargaJual <= 0) {
      Get.snackbar("Error", "Harga jual harus berupa angka yang valid", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedBrand == null) {
      Get.snackbar(
        "Error",
        "Pilih brand terlebih dahulu",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    // Prepare data for API matching BarangRequest structure
    Map<String, dynamic> barangData = {
      'barang_nama': namaController.text,
      'brand_nama': selectedBrand!['brand_nama'] ?? selectedBrand!['nama'],
      'barang_harga_asli': hargaAsli,
      'barang_harga_jual': hargaJual,
      'barang_promo': promoController.text.isEmpty ? null : promoController.text,
      'barang_diskon': diskonController.text.isEmpty ? null : diskonController.text,
      'barang_status': _calculateStatus(),
    };
    
    dataController.postBarang(barangData).then((response) {
      // Navigate to add stock page with the created barang data
      if (response != null && response['barang_id'] != null) {
        Get.toNamed(RoutesClass.addBarangStock, arguments: {
          'barang_id': response['barang_id'],
          'barang_nama': response['barang_nama'],
          'brand_nama': response['brand_nama'],
        });
      } else {
        Get.snackbar(
          "Sukses",
          "Barang berhasil ditambahkan. Silakan tambahkan stok.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offNamed(RoutesClass.allBarang);
      }
    }).catchError((error) {
      Get.snackbar(
        "Error",
        "Gagal menambahkan barang: $error",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Tambah Barang",
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
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nama Barang
                              TextFieldWidget(
                                textController: namaController,
                                hintText: "Nama Barang",
                              ),
                              const SizedBox(height: 15),
                              
                              // Brand Dropdown
                              const Text(
                                "Brand",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Map<String, dynamic>>(
                                    isExpanded: true,
                                    hint: const Text("Pilih Brand"),
                                    value: selectedBrand,
                                    items: controller.myData.map<DropdownMenuItem<Map<String, dynamic>>>((brand) {
                                      return DropdownMenuItem<Map<String, dynamic>>(
                                        value: brand,
                                        child: Text(brand['brand_nama'] ?? brand['nama'] ?? 'Unknown'),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedBrand = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Harga Asli
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: hargaAsliController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: "Harga Asli",
                                    prefixText: "Rp ",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Harga Jual
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: hargaJualController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: "Harga Jual",
                                    prefixText: "Rp ",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Promo
                              TextFieldWidget(
                                textController: promoController,
                                hintText: "Promo (opsional)",
                              ),
                              const SizedBox(height: 15),
                              
                              // Diskon
                              TextFieldWidget(
                                textController: diskonController,
                                hintText: "Diskon (opsional)",
                              ),
                              const SizedBox(height: 30),
                              
                              // Submit Button
                              controller.isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : GestureDetector(
                                      onTap: _submitForm,
                                      child: ButtonWidget(
                                        backgroundcolor: AppColors.mainColor,
                                        text: "Tambah Barang",
                                        textColor: Colors.white,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
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
  @override
  void dispose() {
    // Remove listeners before disposing
    hargaAsliController.removeListener(() => _formatCurrencyInput(hargaAsliController));
    hargaJualController.removeListener(() => _formatCurrencyInput(hargaJualController));
    
    namaController.dispose();
    hargaAsliController.dispose();
    hargaJualController.dispose();
    promoController.dispose();
    diskonController.dispose();
    super.dispose();
  }
}
