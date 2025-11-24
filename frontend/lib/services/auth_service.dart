import 'package:get/get.dart';
import 'package:proyek_gudang/utils/app_constants.dart';
import 'package:proyek_gudang/models/user_model.dart';

class AuthService extends GetConnect {
  // Login user
  Future<Response> login(String usersNama, String password) async {
    try {
      final response = await post(
        AppConstants.BASE_URL + AppConstants.LOGIN,
        {
          'users_nama': usersNama,
          'users_pass': password,
        },
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Register new user
  Future<Response> register(RegisterRequest request) async {
    try {
      final response = await post(
        AppConstants.BASE_URL + AppConstants.REGISTER,
        request.toJson(),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Change password
  Future<Response> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await post(
        AppConstants.BASE_URL + AppConstants.CHANGE_PASSWORD,
        request.toJson(),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Get all users (admin only)
  Future<Response> getAllUsers() async {
    try {
      final response = await get(
        AppConstants.BASE_URL + AppConstants.GET_USERS,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Get single user
  Future<Response> getUser(String userId) async {
    try {
      final response = await get(
        '${AppConstants.BASE_URL}${AppConstants.GET_USER}/$userId',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Update user (admin only)
  Future<Response> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      final response = await put(
        '${AppConstants.BASE_URL}${AppConstants.UPDATE_USER}/$userId',
        userData,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Approve user (admin only)
  Future<Response> approveUser(String userId) async {
    try {
      final response = await put(
        '${AppConstants.BASE_URL}${AppConstants.APPROVE_USER}/$userId/approve',
        {},
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Delete user (admin only)
  Future<Response> deleteUser(String userId) async {
    try {
      final response = await delete(
        '${AppConstants.BASE_URL}${AppConstants.DELETE_USER}/$userId',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Get login history
  Future<Response> getLoginHistory() async {
    try {
      final response = await get(
        AppConstants.BASE_URL + AppConstants.GET_LOGIN_HISTORY,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }

  // Get user login history
  Future<Response> getUserLoginHistory(String userId) async {
    try {
      final response = await get(
        '${AppConstants.BASE_URL}${AppConstants.GET_LOGIN_HISTORY}/$userId',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      return response;
    } catch (e) {
      return Response(
        statusCode: 500,
        body: {'success': false, 'message': 'Kesalahan koneksi: $e'},
      );
    }
  }
}
