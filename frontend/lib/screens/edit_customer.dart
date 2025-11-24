import 'package:flutter/material.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/button_widget.dart';
import 'package:proyek_gudang/widgets/error_warning_ms.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:proyek_gudang/widgets/textfield_widget.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:get/get.dart';

class EditCustomer extends StatefulWidget {
  final String id;
  const EditCustomer({super.key, required this.id});

  @override
  State<EditCustomer> createState() => _EditCustomerState();
}

class _EditCustomerState extends State<EditCustomer> {
  late TextEditingController namaCustomerController;
  late TextEditingController kontakCustomerController;
  late TextEditingController alamatCustomerController;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    namaCustomerController = TextEditingController();
    kontakCustomerController = TextEditingController();
    alamatCustomerController = TextEditingController();
    _loadSingleCustomer();
  }

  @override
  void dispose() {
    namaCustomerController.dispose();
    kontakCustomerController.dispose();
    alamatCustomerController.dispose();
    super.dispose();
  }

  _loadSingleCustomer() async {
    await Get.find<DataController>().getSingleCustomerData(widget.id);
    _populateFields();
  }

  _populateFields() {
    final controller = Get.find<DataController>();
    if (controller.singleCustomerData.isNotEmpty && !_isDataLoaded) {
      namaCustomerController.text = controller.singleCustomerData['customer_nama'] ?? '';
      kontakCustomerController.text = controller.singleCustomerData['customer_kontak'] ?? '';
      alamatCustomerController.text = controller.singleCustomerData['customer_alamat'] ?? '';
      _isDataLoaded = true;
      setState(() {});
    }
  }

  bool _dataValidation() {
    if (namaCustomerController.text.trim() == '') {
      Message.taskErrorOrWarning("Nama Customer", "Nama Customer Kosong");
      return false;
    }
    if (kontakCustomerController.text.trim() == '') {
      Message.taskErrorOrWarning("Kontak Customer", "Kontak Customer Kosong");
      return false;
    }
    if (alamatCustomerController.text.trim() == '') {
      Message.taskErrorOrWarning("Alamat Customer", "Alamat Customer Kosong");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithHeader(
      title: "Edit Customer",
      body: GetBuilder<DataController>(builder: (controller) {
        // Populate fields when data is available
        if (controller.singleCustomerData.isNotEmpty && !_isDataLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateFields();
          });
        }

        return Container(
          width: double.maxFinite,
          height: double.maxFinite,
          padding: const EdgeInsets.only(left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  TextFieldWidget(
                    textController: namaCustomerController,
                    hintText: "Nama Customer",
                    borderRadius: 15,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),
                  TextFieldWidget(
                    textController: kontakCustomerController,
                    hintText: "Kontak Customer (Phone/Email)",
                    borderRadius: 15,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),
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
                    GestureDetector(
                      onTap: controller.isLoading ? null : () async {
                        if (_dataValidation()) {
                          Map<String, dynamic> customerData = {
                            'customer_nama': namaCustomerController.text.trim(),
                            'customer_kontak': kontakCustomerController.text.trim(),
                            'customer_alamat': alamatCustomerController.text.trim(),
                          };

                          bool success = await Get.find<DataController>().updateCustomer(customerData, widget.id);
                          
                          if (success) {
                            // Show success message
                            Get.snackbar(
                              "Success",
                              "Customer updated successfully",
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
                              "Failed to update customer",
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
                        text: controller.isLoading ? "Updating..." : "Update",
                        textColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Get.offNamed(RoutesClass.getAllCustomerRoute());
                      },
                      child: ButtonWidget(
                        backgroundcolor: Colors.grey[600]!,
                        text: "Kembali",
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
