import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:get/get.dart';

class AddTask extends StatelessWidget {
  const AddTask({super.key});

  @override
  Widget build(BuildContext context) {

    TextEditingController nameController = TextEditingController();
    TextEditingController contactController = TextEditingController();
    TextEditingController telephoneController = TextEditingController();

    bool _dataValidation(){
      if(nameController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Pabrik", "Nama Pabrik Kosong");
        return false;
      }
      if(contactController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Kontak", "Nama Kontak Kosong");
        return false;
      }
      if(telephoneController.text.trim()==''){
        Message.taskErrorOrWarning("Nomor Telepon", "Nomor Telepon Kosong");
        return false;
      }
      return true;
    }

    return ScaffoldWithHeader(
      title: "Tambah Pabrik",
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.grey[300], // Light grey background like home screen
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
                  textController: nameController,
                  hintText: "Nama Pabrik",
                  borderRadius: 15,
                  maxLines: 1,
                ),
                const SizedBox(height: 20,), 
                TextFieldWidget(
                  textController: contactController,
                  hintText: "Nama Kontak",
                  borderRadius: 15,
                  maxLines: 1,
                ),
                const SizedBox(height: 20,), 
                TextFieldWidget(
                  textController: telephoneController,
                  hintText: "Nomor Kontak",
                  borderRadius: 15,
                  maxLines: 1,
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
                        await Get.find<DataController>().postData(
                          nameController.text.trim(),
                          contactController.text.trim(),
                          telephoneController.text.trim()
                        );
                        // Show success message
                        Get.snackbar(
                          "Success", 
                          "Brand added successfully",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: Duration(seconds: 2),
                        );
                        // Navigate back to list
                        Get.offNamed(RoutesClass.getAllTaskRoute());
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