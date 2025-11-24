import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:get/get.dart';

class AddCustomer extends StatelessWidget {
  const AddCustomer({super.key});

  @override
  Widget build(BuildContext context) {

    TextEditingController namaCustomerController = TextEditingController();
    TextEditingController kontakCustomerController = TextEditingController();
    TextEditingController alamatCustomerController = TextEditingController();

    bool _dataValidation(){
      if(namaCustomerController.text.trim()==''){
        Message.taskErrorOrWarning("Nama Customer", "Nama Customer Kosong");
        return false;
      }
      if(kontakCustomerController.text.trim()==''){
        Message.taskErrorOrWarning("Kontak Customer", "Kontak Customer Kosong");
        return false;
      }
      if(alamatCustomerController.text.trim()==''){
        Message.taskErrorOrWarning("Alamat Customer", "Alamat Customer Kosong");
        return false;
      }
      return true;
    }

    return ScaffoldWithHeader(
      title: "Tambah Customer",
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
                  textController: namaCustomerController,
                  hintText: "Nama Customer",
                  borderRadius: 15,
                  maxLines: 1,
                ),
                const SizedBox(height: 20,), 
                TextFieldWidget(
                  textController: kontakCustomerController,
                  hintText: "Kontak Customer (Phone/Email)",
                  borderRadius: 15,
                  maxLines: 1,
                ),
                const SizedBox(height: 20,), 
                TextFieldWidget(
                  textController: alamatCustomerController,
                  hintText: "Alamat Customer",
                  borderRadius: 15,
                  maxLines: 3,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  GetBuilder<DataController>(
                    builder: (controller) {
                      return GestureDetector(
                        onTap: controller.isLoading ? null : () async {
                          if(_dataValidation()){
                            Map<String, dynamic> customerData = {
                              'customer_nama': namaCustomerController.text.trim(),
                              'customer_kontak': kontakCustomerController.text.trim(),
                              'customer_alamat': alamatCustomerController.text.trim(),
                            };
                            
                            var result = await Get.find<DataController>().postCustomer(customerData);
                            
                            if (result != null) {
                              // Show success message
                              Get.snackbar(
                                "Success", 
                                "Customer added successfully",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                                duration: Duration(seconds: 2),
                              );
                              // Navigate back to customer list
                              Get.offNamed(RoutesClass.getAllCustomerRoute());
                            } else {
                              // Show error message
                              Get.snackbar(
                                "Error", 
                                "Failed to add customer",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                duration: Duration(seconds: 2),
                              );
                            }
                          }
                        },
                        child: ButtonWidget(
                          backgroundcolor: controller.isLoading ? Colors.grey : AppColors.mainColor, 
                          text: controller.isLoading ? "Adding..." : "Tambah", 
                          textColor: Colors.white
                        ),
                      );
                    }
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
