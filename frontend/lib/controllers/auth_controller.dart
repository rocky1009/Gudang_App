import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/services/auth_service.dart';
import 'package:proyek_gudang/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable variables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadUserFromPrefs();
  }

  // Load user from SharedPreferences
  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = json.decode(userJson);
        currentUser.value = UserModel.fromJson(userData);
        isLoggedIn.value = true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user from prefs: $e');
      }
    }
  }

  // Save user to SharedPreferences
  Future<void> _saveUserToPrefs(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', json.encode(user.toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user to prefs: $e');
      }
    }
  }

  // Clear user from SharedPreferences
  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user from prefs: $e');
      }
    }
  }

  // Login
  Future<bool> login(String usersNama, String password) async {
    if (usersNama.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Nama dan password harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final response = await _authService.login(usersNama, password);

      if (response.statusCode == 200 && response.body != null) {
        final loginResponse = LoginResponse.fromJson(response.body);

        if (loginResponse.success && loginResponse.user != null) {
          currentUser.value = loginResponse.user;
          isLoggedIn.value = true;
          await _saveUserToPrefs(loginResponse.user!);
          
          Get.snackbar(
            'Berhasil',
            'Selamat datang ${loginResponse.user!.usersNama}!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
            colorText: Get.theme.colorScheme.onPrimary,
          );
          
          return true;
        } else {
          Get.snackbar(
            'Login Gagal',
            loginResponse.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return false;
        }
      } else {
        // Check if response has body with error message
        String errorMessage = 'Server error';
        if (response.body != null && response.body is Map) {
          errorMessage = response.body['message'] ?? 'Server error: ${response.statusText}';
        } else {
          errorMessage = 'Server error: ${response.statusText}';
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Server mengembalikan response yang tidak valid';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Coba lagi.';
      } else {
        errorMessage = 'Terjadi kesalahan saat login';
      }
      
      if (kDebugMode) {
        print('Login error: $e');
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Register
  Future<bool> register(String nama, String tlp, String password) async {
    if (nama.isEmpty || tlp.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Semua field harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final request = RegisterRequest(
        usersNama: nama,
        usersTlp: tlp,
        usersPass: password,
      );

      final response = await _authService.register(request);

      if (response.statusCode == 200 && response.body != null) {
        final result = response.body;

        if (result['success'] == true) {
          Get.snackbar(
            'Berhasil',
            result['message'] ?? 'Registrasi berhasil. Menunggu persetujuan admin.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
            colorText: Get.theme.colorScheme.onPrimary,
            duration: const Duration(seconds: 4),
          );
          return true;
        } else {
          Get.snackbar(
            'Registrasi Gagal',
            result['message'] ?? 'Registrasi gagal',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return false;
        }
      } else {
        Get.snackbar(
          'Error',
          'Server error: ${response.statusText}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Server mengembalikan response yang tidak valid';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Coba lagi.';
      } else {
        errorMessage = 'Terjadi kesalahan saat registrasi';
      }
      
      if (kDebugMode) {
        print('Register error: $e');
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (currentUser.value == null) {
      Get.snackbar(
        'Error',
        'Tidak ada user yang login',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      Get.snackbar(
        'Error',
        'Password lama dan password baru harus diisi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final request = ChangePasswordRequest(
        usersId: currentUser.value!.usersId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      final response = await _authService.changePassword(request);

      if (response.statusCode == 200 && response.body != null) {
        final result = response.body;

        if (result['success'] == true) {
          Get.snackbar(
            'Berhasil',
            result['message'] ?? 'Password berhasil diubah',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
            colorText: Get.theme.colorScheme.onPrimary,
          );
          return true;
        } else {
          Get.snackbar(
            'Gagal',
            result['message'] ?? 'Gagal mengubah password',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
          );
          return false;
        }
      } else {
        // Handle non-200 responses with error message from body
        String errorMessage = 'Server error: ${response.statusText}';
        if (response.body != null && response.body is Map && response.body['message'] != null) {
          errorMessage = response.body['message'];
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return false;
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Server mengembalikan response yang tidak valid';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Coba lagi.';
      } else {
        errorMessage = 'Terjadi kesalahan saat mengubah password';
      }
      
      if (kDebugMode) {
        print('Change password error: $e');
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    currentUser.value = null;
    isLoggedIn.value = false;
    await _clearUserFromPrefs();
    
    Get.snackbar(
      'Berhasil Logout',
      'Anda telah keluar dari aplikasi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
      colorText: Get.theme.colorScheme.onPrimary,
    );
  }

  // Check if user is admin
  bool get isAdmin => currentUser.value?.isAdmin ?? false;

  // Check if user is active
  bool get isActive => currentUser.value?.isActive ?? false;
}
