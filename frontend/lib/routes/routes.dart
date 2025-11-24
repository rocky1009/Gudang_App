import 'package:get/get.dart';
import 'package:proyek_gudang/screens/login_screen.dart';
import 'package:proyek_gudang/screens/register_screen.dart';
import 'package:proyek_gudang/screens/change_password_screen.dart';
import 'package:proyek_gudang/screens/add_gudang.dart';
import 'package:proyek_gudang/screens/add_task.dart';
import 'package:proyek_gudang/screens/add_barang.dart';
import 'package:proyek_gudang/screens/add_barangStock.dart';
import 'package:proyek_gudang/screens/add_barangInOut.dart';
import 'package:proyek_gudang/screens/all_gudang.dart';
import 'package:proyek_gudang/screens/all_task.dart';
import 'package:proyek_gudang/screens/all_barang.dart';
import 'package:proyek_gudang/screens/edit_gudang.dart' as editGudangScreen;
import 'package:proyek_gudang/screens/edit_task.dart' as edit;
import 'package:proyek_gudang/screens/edit_barang.dart' as editBarangScreen;
import 'package:proyek_gudang/screens/edit_barangStock.dart' as editBarangStockScreen;
import 'package:proyek_gudang/screens/home_screen.dart';
import 'package:proyek_gudang/screens/view_gudang.dart' as viewGudangScreen;
import 'package:proyek_gudang/screens/view_task.dart' as view;
import 'package:proyek_gudang/screens/view_barang.dart' as viewBarangScreen;
import 'package:proyek_gudang/screens/add_customer.dart';
import 'package:proyek_gudang/screens/all_customer.dart';
import 'package:proyek_gudang/screens/edit_customer.dart' as editCustomerScreen;
import 'package:proyek_gudang/screens/view_customer.dart' as viewCustomerScreen;
import 'package:proyek_gudang/screens/logs_barang.dart';
import 'package:proyek_gudang/screens/edit_logs_barang.dart';
import 'package:proyek_gudang/screens/orders_barang.dart';
import 'package:proyek_gudang/screens/logs_orders.dart';
import 'package:proyek_gudang/screens/edit_logs_orders.dart';
import 'package:proyek_gudang/screens/view_discount.dart';
import 'package:proyek_gudang/screens/add_discount.dart';
import 'package:proyek_gudang/screens/edit_discount.dart';
import 'package:proyek_gudang/screens/add_sales.dart';
import 'package:proyek_gudang/screens/all_sales.dart';
import 'package:proyek_gudang/screens/view_sales.dart' as viewSalesScreen;
import 'package:proyek_gudang/screens/edit_sales.dart' as editSalesScreen;
import 'package:proyek_gudang/screens/logs_profit.dart';
import 'package:proyek_gudang/screens/logs_statistics.dart';
import 'package:proyek_gudang/screens/logs_ringkasan_barang.dart';
import 'package:proyek_gudang/screens/all_user.dart';
import 'package:proyek_gudang/screens/add_user.dart';
import 'package:proyek_gudang/screens/view_user.dart';
import 'package:proyek_gudang/screens/edit_user.dart';

class RoutesClass {
  static String login = "/login";
  static String register = "/register";
  static String changePassword = "/changePassword";
  static String home = "/";
  static String allTask = "/allTask";
  static String addTask = "/addTask";
  static String addGudang = "/addGudang";
  static String allGudang = "/allGudang";
  static String addBarang = "/addBarang";
  static String addBarangStock = "/addBarangStock";
  static String addBarangKeluar = "/addBarangKeluar";
  static String allBarang = "/allBarang";
  static String editTask = "/editTask";
  static String viewTask = "/viewTask";
  static String editGudang = "/editGudang";
  static String viewGudang = "/viewGudang";
  static String editBarang = "/editBarang";
  static String editBarangStock = "/editBarangStock";
  static String viewBarang = "/viewBarang";
  static String addCustomer = "/addCustomer";
  static String allCustomer = "/allCustomer";
  static String editCustomer = "/editCustomer";
  static String viewCustomer = "/viewCustomer";
  static String logsBarang = "/logsBarang";
  static String editLogsBarang = "/editLogsBarang";
  static String ordersBarang = "/ordersBarang";
  static String logsOrders = "/logsOrders";
  static String editLogsOrders = "/editLogsOrders";
  static String viewDiscount = "/viewDiscount";
  static String addDiscount = "/addDiscount";
  static String editDiscount = "/editDiscount";
  static String addSales = "/addSales";
  static String allSales = "/allSales";
  static String viewSales = "/viewSales";
  static String editSales = "/editSales";
  static String logsProfit = "/logsProfit";
  static String logsStatistics = "/logsStatistics";
  static String logsRingkasanBarang = "/logsRingkasanBarang";
  static String allUser = "/allUser";
  static String addUser = "/addUser";
  static String viewUser = "/viewUser";
  static String editUser = "/editUser";

  static String getLoginRoute() => login;
  static String getRegisterRoute() => register;
  static String getChangePasswordRoute() => changePassword;
  static String getHomeRoute() => home;
  static String getAllTaskRoute() => allTask;
  static String getAddTaskRoute() => addTask;
  static String getAddGudangRoute() => addGudang;
  static String getAllGudangRoute() => allGudang;
  static String getAddBarangRoute() => addBarang;
  static String getAddBarangKeluarRoute() => addBarangKeluar;
  static String getAllBarangRoute() => allBarang;
  static String getEditTaskRoute(String id) => "$editTask?id=$id";
  static String getViewTaskRoute(String id) => "$viewTask?id=$id";
  static String getEditGudangRoute(String id) => "$editGudang?id=$id";
  static String getViewGudangRoute(String id) => "$viewGudang?id=$id";
  static String getEditBarangRoute(String id) => "$editBarang?id=$id";
  static String getEditBarangStockRoute(String id) => "$editBarangStock?id=$id";
  static String getViewBarangRoute(String id) => "$viewBarang?id=$id";
  static String getAddCustomerRoute() => addCustomer;
  static String getAllCustomerRoute() => allCustomer;
  static String getEditCustomerRoute(String id) => "$editCustomer?id=$id";
  static String getViewCustomerRoute(String id) => "$viewCustomer?id=$id";
  static String getLogsBarangRoute() => logsBarang;
  static String getEditLogsBarangRoute() => editLogsBarang;
  static String getOrdersBarangRoute() => ordersBarang;
  static String getLogsOrdersRoute() => logsOrders;
  static String getEditLogsOrdersRoute() => editLogsOrders;
  static String getViewDiscountRoute() => viewDiscount;
  static String getAddDiscountRoute() => addDiscount;
  static String getEditDiscountRoute() => editDiscount;
  static String getAddSalesRoute() => addSales;
  static String getAllSalesRoute() => allSales;
  static String getViewSalesRoute() => viewSales;
  static String getEditSalesRoute() => editSales;
  static String getLogsProfitRoute() => logsProfit;
  static String getLogsStatisticsRoute() => logsStatistics;
  static String getLogsRingkasanBarangRoute() => logsRingkasanBarang;
  static String getAllUserRoute() => allUser;
  static String getAddUserRoute() => addUser;
  static String getViewUserRoute() => viewUser;
  static String getEditUserRoute() => editUser;

  static List<GetPage> routes = [
    GetPage(page: ()=> const LoginScreen(), name: login),
    GetPage(page: ()=> const RegisterScreen(), name: register),
    GetPage(page: ()=> const ChangePasswordScreen(), name: changePassword),
    GetPage(page: ()=> const HomeScreen(), name: home),
    GetPage(page: ()=> const AllTasks(), name: allTask, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddTask(), name: addTask, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddGudang(), name: addGudang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AllGudang(), name: allGudang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddBarang(), name: addBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddBarangStock(), name: addBarangStock, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddBarangInOut(), name: addBarangKeluar, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AllBarang(), name: allBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const edit.EditTask(id: "");
      }
      return edit.EditTask(id: id);
    }, name: editTask, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return view.ViewTask(id: "");
      }
      return view.ViewTask(id: id);
    }, name: viewTask, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const editGudangScreen.EditGudang(id: "");
      }
      return editGudangScreen.EditGudang(id: id);
    }, name: editGudang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return viewGudangScreen.ViewGudang(id: "");
      }
      return viewGudangScreen.ViewGudang(id: id);
    }, name: viewGudang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const editBarangScreen.EditBarang(id: "");
      }
      return editBarangScreen.EditBarang(id: id);
    }, name: editBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const editBarangStockScreen.EditBarangStock(id: "");
      }
      return editBarangStockScreen.EditBarangStock(id: id);
    }, name: editBarangStock, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return viewBarangScreen.ViewBarang(id: "");
      }
      return viewBarangScreen.ViewBarang(id: id);
    }, name: viewBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddCustomer(), name: addCustomer, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AllCustomer(), name: allCustomer, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const editCustomerScreen.EditCustomer(id: "");
      }
      return editCustomerScreen.EditCustomer(id: id);
    }, name: editCustomer, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      var id = Get.parameters['id'];
      if (id == null) {
        return const viewCustomerScreen.ViewCustomer(id: "");
      }
      return viewCustomerScreen.ViewCustomer(id: id);
    }, name: viewCustomer, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const LogsBarang(), name: logsBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        return EditLogsBarang(logData: {});
      }
      return EditLogsBarang(logData: arguments);
    }, name: editLogsBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const OrdersBarang(), name: ordersBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const LogsOrders(), name: logsOrders, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        return EditLogsOrders(orderData: {});
      }
      return EditLogsOrders(orderData: arguments);
    }, name: editLogsOrders, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const ViewDiscount(), name: viewDiscount, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddDiscount(), name: addDiscount, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        return EditDiscount(barangData: {});
      }
      return EditDiscount(barangData: arguments);
    }, name: editDiscount, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddSales(), name: addSales, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AllSales(), name: allSales, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        return const viewSalesScreen.ViewSales(salesData: {});
      }
      return viewSalesScreen.ViewSales(salesData: arguments);
    }, name: viewSales, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments == null) {
        return const editSalesScreen.EditSales(salesData: {});
      }
      return editSalesScreen.EditSales(salesData: arguments);
    }, name: editSales, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const LogsProfit(), name: logsProfit, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const LogsStatistics(), name: logsStatistics, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const LogsRingkasanBarang(), name: logsRingkasanBarang, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AllUser(), name: allUser, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const AddUser(), name: addUser, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const ViewUser(), name: viewUser, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
    GetPage(page: ()=> const EditUser(), name: editUser, transition: Transition.fadeIn, transitionDuration: const Duration(milliseconds: 200)),
  ];
}
