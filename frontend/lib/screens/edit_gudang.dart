import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:get/get.dart';

class EditGudang extends StatefulWidget {
  final String id;
  const EditGudang({super.key, required this.id});

  @override
  State<EditGudang> createState() => _EditGudangState();
}

class _EditGudangState extends State<EditGudang> {
  late TextEditingController namaGudangController;
  late TextEditingController alamatGudangController;
  late TextEditingController jumlahLantaiController;

  @override
  void initState() {
    super.initState();
    namaGudangController = TextEditingController();
    alamatGudangController = TextEditingController();
    jumlahLantaiController = TextEditingController();
    _loadSingleGudang();
  }

  @override
  void dispose() {
    namaGudangController.dispose();
    alamatGudangController.dispose();
    jumlahLantaiController.dispose();
    super.dispose();
  }

  _loadSingleGudang() async {
    try {
      print("Attempting to load gudang with ID: ${widget.id}");
      await Get.find<DataController>().getSingleGudang(widget.id.toString());
      print("Gudang data loaded successfully");
    } catch (e) {
      print("Error loading gudang: $e");
      Get.snackbar(
        "Error", 
        "Failed to load gudang data: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    bool _dataValidation(){
      if(namaGudangController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Gudang", "Nama Gudang Kosong");
        return false;
      }
      if(alamatGudangController.text.trim()==''){
        Message.taskErrorOrWarning("Alamat Gudang", "Alamat Gudang Kosong");
        return false;
      }
      
      int? jumlahLantai = int.tryParse(jumlahLantaiController.text.trim());
      if(jumlahLantai == null || jumlahLantai < 1){
        Message.taskErrorOrWarning("Jumlah Lantai", "Jumlah Lantai harus berupa angka minimal 1");
        return false;
      }
      
      return true;
    }

    return ScaffoldWithHeader(
      title: "Edit Gudang",
      body: GetBuilder<DataController>(builder: (controller){
        namaGudangController.text = controller.singleGudangData['gudang_nama'] ?? 'Nama Gudang tidak ditemukan';
        alamatGudangController.text = controller.singleGudangData['gudang_alamat'] ?? 'Alamat Gudang tidak ditemukan';
        jumlahLantaiController.text = controller.singleGudangData['jumlah_lantai']?.toString() ?? '1';
        return Container(
          width: double.maxFinite,
          height: double.maxFinite,
          padding: const EdgeInsets.only(left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.grey[300], // Light grey background like other screens
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20,),
                  TextFieldWidget(
                    textController: namaGudangController,
                    hintText: "Nama Gudang",
                    borderRadius: 15,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20,), 
                  TextFieldWidget(
                    textController: alamatGudangController,
                    hintText: "Alamat Gudang",
                    borderRadius: 15,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20,), 
                  TextFieldWidget(
                    textController: jumlahLantaiController,
                    hintText: "Jumlah Lantai (angka)",
                    borderRadius: 15,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 5,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "Contoh: Masukkan 3 untuk 3 lantai. Sistem akan otomatis menambah/mengurangi lantai.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if(_dataValidation()){
                          print("Starting update for gudang ID: ${widget.id}");
                          
                          int jumlahLantai = int.tryParse(jumlahLantaiController.text.trim()) ?? 1;
                          
                          bool success = await Get.find<DataController>().updateGudang(
                            namaGudangController.text.trim(),
                            alamatGudangController.text.trim(),
                            jumlahLantai,
                            widget.id
                          );
                          
                          print("Update result: $success");
                          
                          if(success) {
                            // Refresh the data first
                            await Get.find<DataController>().getGudangData();
                            // Show success message and navigate back
                            Get.back();
                            Get.snackbar(
                              "Success", 
                              "Gudang dan $jumlahLantai lantai berhasil diperbarui",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: Duration(seconds: 2),
                            );
                          } else {
                            // Show error message
                            Get.snackbar(
                              "Error", 
                              "Failed to update gudang",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              duration: Duration(seconds: 1),
                            );
                          }
                        }
                      },
                      child: controller.isLoading ? 
                        Container(
                          width: double.maxFinite,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            )
                          ),
                        ) :
                        ButtonWidget(
                          backgroundcolor: AppColors.mainColor, 
                          text: "Edit", 
                          textColor: Colors.white
                        ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: ButtonWidget(
                        backgroundcolor: Colors.grey[600]!, 
                        text: "Kembali", 
                        textColor: Colors.white
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }),
    );
  }
}
