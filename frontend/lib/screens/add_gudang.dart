import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:get/get.dart';

class AddGudang extends StatelessWidget {
  const AddGudang({super.key});

  @override
  Widget build(BuildContext context) {

    TextEditingController namaGudangController = TextEditingController();
    TextEditingController alamatGudangController = TextEditingController();
    TextEditingController jumlahLantaiController = TextEditingController();

    bool _dataValidation(){
      if(namaGudangController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Gudang", "Nama Gudang Kosong");
        return false;
      }
      if(alamatGudangController.text.trim()==''){
        Message.taskErrorOrWarning("Alamat Gudang", "Alamat Gudang Kosong");
        return false;
      }
      if(jumlahLantaiController.text.trim()==''){
        Message.taskErrorOrWarning("Jumlah Lantai", "Jumlah Lantai Kosong");
        return false;
      }
      int? jumlahLantai = int.tryParse(jumlahLantaiController.text.trim());
      if(jumlahLantai == null || jumlahLantai < 1){
        Message.taskErrorOrWarning("Jumlah Lantai", "Jumlah Lantai harus angka minimal 1");
        return false;
      }
      return true;
    }

    return ScaffoldWithHeader(
      title: "Tambah Gudang",
      body: Container(
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
                const SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    "Contoh: Masukkan 3 untuk membuat 3 lantai (Lt.1, Lt.2, Lt.3)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
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
                        int jumlahLantai = int.parse(jumlahLantaiController.text.trim());
                        await Get.find<DataController>().postGudang(
                          namaGudangController.text.trim(),
                          alamatGudangController.text.trim(),
                          jumlahLantai
                        );
                        // Show success message
                        Get.snackbar(
                          "Success", 
                          "Gudang dengan $jumlahLantai lantai berhasil ditambahkan",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: Duration(seconds: 2),
                        );
                        // Navigate back to home
                        Get.offNamed(RoutesClass.getHomeRoute());
                      }
                    },
                    child: ButtonWidget(
                      backgroundcolor: AppColors.mainColor, 
                      text: "Tambah", 
                      textColor: Colors.white
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Get.offNamed(RoutesClass.getHomeRoute());
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
      ),
    );
  }
}
