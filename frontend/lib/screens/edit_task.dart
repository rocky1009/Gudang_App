import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:get/get.dart';

class EditTask extends StatefulWidget {
  final String id;
  const EditTask({super.key, required this.id});

  @override
  State<EditTask> createState() => _EditTaskState();
}

class _EditTaskState extends State<EditTask> {
  late TextEditingController nameController;
  late TextEditingController contactController;
  late TextEditingController telephoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    contactController = TextEditingController();
    telephoneController = TextEditingController();
    _loadSingleTask();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    telephoneController.dispose();
    super.dispose();
  }

  _loadSingleTask() async {
    await Get.find<DataController>().getSingleData(widget.id.toString());
  }

  @override
  Widget build(BuildContext context) {

    bool _dataValidation(){
      if(nameController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Merk", "Nama Merk Kosong");
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
      title: "Edit Pabrik",
      body: GetBuilder<DataController>(builder: (controller){
        nameController.text = controller.singleData['brand_nama'] ?? 'Nama Merk tidak ditemukan';
        contactController.text = controller.singleData['brand_kontak'] ?? 'Kontak tidak ditemukan';
        telephoneController.text = controller.singleData['brand_tlp'] ?? 'Telepon tidak ditemukan';
        return Container(
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
                    hintText: "Nama Merk",
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
                          print("Starting update for brand ID: ${widget.id}");
                          bool success = await Get.find<DataController>().updateData(
                            nameController.text.trim(),
                            contactController.text.trim(),
                            telephoneController.text.trim(),
                            widget.id
                          );
                          
                          print("Update result: $success");
                          
                          if(success) {
                            // Refresh the data first
                            await Get.find<DataController>().getData();
                            // Show success message and navigate back
                            Get.back();
                            Get.snackbar(
                              "Success", 
                              "Brand updated successfully",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                              duration: Duration(seconds: 2),
                            );
                          } else {
                            // Show error message
                            Get.snackbar(
                              "Error", 
                              "Failed to update brand",
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