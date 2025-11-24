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

class EditBarang extends StatefulWidget {
  final String id;
  const EditBarang({super.key, required this.id});

  @override
  State<EditBarang> createState() => _EditBarangState();
}

class _EditBarangState extends State<EditBarang> {
  final DataController dataController = Get.find<DataController>();
  
  // Text controllers
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaJualController = TextEditingController();
  
  // Form key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Selected brand
  Map<String, dynamic>? selectedBrand;
  bool isDataLoaded = false;
  
  // Input formatters for currency
  void _formatCurrency(TextEditingController controller) {
    String text = controller.text.replaceAll('.', '');
    if (text.isNotEmpty) {
      String formatted = AppConstants.formatCurrency(text);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // Add listeners for currency formatting
    hargaJualController.addListener(() => _formatCurrency(hargaJualController));
  }
  
  void _initializeData() async {
    try {
      // Load brands data first
      await dataController.getData();
      
      // Load barang data if editing
      if (widget.id.isNotEmpty) {
        await dataController.getSingleBarang(widget.id);
      }
      
      // If data passed as arguments, use that first, otherwise use loaded data
      final barangData = Get.arguments as Map<String, dynamic>? ?? dataController.singleBarangData;
      if (barangData.isNotEmpty) {
        _populateFields(barangData);
      }
      
      setState(() {
        isDataLoaded = true;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        isDataLoaded = true;
      });
    }
  }
  
  void _populateFields(Map<String, dynamic> barang) {
    print("=== POPULATE FIELDS DEBUG ===");
    print("Raw barang data: $barang");
    print("barang['nama']: '${barang['nama']}'");
    print("barang['barang_nama']: '${barang['barang_nama']}'");
    print("==============================");
    
    // Try multiple field name variations for the name
    String barangNama = barang['nama'] ?? 
                       barang['barang_nama'] ?? 
                       barang['name'] ?? '';
    
    String barangHarga = (barang['harga'] ?? 
                         barang['barang_harga_jual'] ?? 
                         barang['harga_jual'] ?? 0).toString();
    
    print("Setting namaController to: '$barangNama'");
    print("Setting hargaJualController to: '$barangHarga'");
    
    namaController.text = barangNama;
    hargaJualController.text = AppConstants.formatCurrency(barangHarga);
    
    // Find and set selected brand
    final brandId = barang['id_brand'] ?? barang['brand_id'];
    final brandName = barang['brand_nama'];
    
    print("Looking for brand with ID: $brandId or Name: $brandName"); // Debug print
    
    if (dataController.myData.isNotEmpty) {
      // Try to find by ID first
      if (brandId != null) {
        selectedBrand = dataController.myData.firstWhere(
          (brand) => brand['id'] == brandId,
          orElse: () => {},
        );
      }
      
      // If not found by ID, try to find by name
      if ((selectedBrand == null || selectedBrand!.isEmpty) && brandName != null) {
        selectedBrand = dataController.myData.firstWhere(
          (brand) => (brand['nama'] ?? brand['brand_nama']) == brandName,
          orElse: () => {},
        );
      }
    }
    
    print("Selected brand: $selectedBrand"); // Debug print
    setState(() {}); // Refresh UI
  }
  
  // Submit form
  void _submitForm() {
    // Debug: Check controller values
    print("=== FORM SUBMISSION DEBUG ===");
    print("namaController.text: '${namaController.text}'");
    print("namaController.text.length: ${namaController.text.length}");
    print("hargaJualController.text: '${hargaJualController.text}'");
    print("selectedBrand: $selectedBrand");
    print("=============================");
    
    // Basic validation
    if (namaController.text.isEmpty) {
      Get.snackbar("Error", "Nama barang tidak boleh kosong", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (hargaJualController.text.isEmpty) {
      Get.snackbar("Error", "Harga jual tidak boleh kosong", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedBrand == null) {
      Get.snackbar("Error", "Pilih brand terlebih dahulu", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    // Get existing barang data - ensure we have the most complete dataset
    Map<String, dynamic> existingData = Get.arguments as Map<String, dynamic>? ?? dataController.singleBarangData;
    
    print("Existing data for preservation: $existingData"); // Debug print
    
    // Try sending barang_nama instead of nama to match your backend expectations
    Map<String, dynamic> barangData = {
      // Main fields being updated - try both field names
      'nama': namaController.text,  // Keep this for compatibility
      'barang_nama': namaController.text,  // Add this to match your backend struct
      'brand_nama': selectedBrand!['nama'] ?? selectedBrand!['brand_nama'],
      'barang_harga_jual': AppConstants.parseCurrency(hargaJualController.text),
      
      // Preserve existing fields - use the exact same names as your Go struct JSON tags
      'barang_harga_asli': existingData['barang_harga_asli'] ?? 
                          existingData['harga_asli'] ?? 
                          AppConstants.parseCurrency(hargaJualController.text),
      
      'barang_promo': existingData['barang_promo'] ?? 
                     existingData['promo'],  // Can be null
      
      'barang_diskon': existingData['barang_diskon'] ?? 
                      existingData['diskon'] ?? 0,
      
      'barang_status': existingData['barang_status'] ?? 
                      existingData['status'] ?? '2',
    };
    
    print("=== FINAL DATA CHECK ===");
    print("Final barangData being sent: $barangData");
    print("Widget ID: ${widget.id}");
    print("Nama from controller: '${namaController.text}'");
    print("barangData['nama']: '${barangData['nama']}'");
    print("========================");
    
    dataController.updateBarang(barangData, widget.id).then((success) {
      if (success) {
        // Show success message and option to edit stock
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text('Data barang berhasil diupdate.\n\nApakah Anda ingin mengedit stok barang?'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offNamed(RoutesClass.allBarang); // Navigate to barang list
                },
                child: const Text('Tidak'),
              ),
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.offNamed(RoutesClass.getEditBarangStockRoute(widget.id)); // Navigate to edit stock
                },
                child: const Text('Ya, Edit Stok'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar("Error", "Gagal mengupdate barang", backgroundColor: Colors.red, colorText: Colors.white);
      }
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
              title: "Edit Barang",
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
                    if (!isDataLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Expanded(
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
                                              child: Text(brand['nama'] ?? brand['brand_nama'] ?? 'Unknown'),
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
                                    
                                    // Harga Jual
                                    TextFieldWidget(
                                      textController: hargaJualController,
                                      hintText: "Harga Jual",
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Submit Button - Fixed at bottom
                            const SizedBox(height: 20),
                            controller.isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : GestureDetector(
                                    onTap: _submitForm,
                                    child: ButtonWidget(
                                      backgroundcolor: AppColors.mainColor,
                                      text: "Update Barang",
                                      textColor: Colors.white,
                                    ),
                                  ),
                          ],
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
    namaController.dispose();
    hargaJualController.dispose();
    
    // Remove listeners
    hargaJualController.removeListener(() => _formatCurrency(hargaJualController));
    super.dispose();
  }
}
