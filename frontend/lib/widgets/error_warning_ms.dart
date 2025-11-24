import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/utils/app_colors.dart';

class Message{
  static void taskErrorOrWarning(String taskName, String taskErrorOrWarning){
    Get.snackbar(taskName, taskErrorOrWarning,
      backgroundColor: AppColors.mainColor,
      titleText: Text(
        taskName,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
      messageText: Text(
        taskErrorOrWarning,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 145, 137),
        ),
      )
    );
  }
}