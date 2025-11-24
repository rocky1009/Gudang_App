class UserModel {
  final String usersId;
  final String usersNama;
  final String usersTlp;
  final int usersLevel;
  final String usersDaftar;
  final int usersStatus;
  final String? levelName;
  final String? statusName;

  UserModel({
    required this.usersId,
    required this.usersNama,
    required this.usersTlp,
    required this.usersLevel,
    required this.usersDaftar,
    required this.usersStatus,
    this.levelName,
    this.statusName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      usersId: json['users_id'] ?? '',
      usersNama: json['users_nama'] ?? '',
      usersTlp: json['users_tlp'] ?? '',
      usersLevel: json['users_level'] ?? 2,
      usersDaftar: json['users_daftar'] ?? '',
      usersStatus: json['users_status'] ?? 0,
      levelName: json['level_name'],
      statusName: json['status_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users_id': usersId,
      'users_nama': usersNama,
      'users_tlp': usersTlp,
      'users_level': usersLevel,
      'users_daftar': usersDaftar,
      'users_status': usersStatus,
      'level_name': levelName,
      'status_name': statusName,
    };
  }

  bool get isAdmin => usersLevel == 1;
  bool get isActive => usersStatus == 1;
}

class LoginResponse {
  final bool success;
  final String message;
  final UserModel? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class RegisterRequest {
  final String usersNama;
  final String usersTlp;
  final String usersPass;

  RegisterRequest({
    required this.usersNama,
    required this.usersTlp,
    required this.usersPass,
  });

  Map<String, dynamic> toJson() {
    return {
      'users_nama': usersNama,
      'users_tlp': usersTlp,
      'users_pass': usersPass,
    };
  }
}

class ChangePasswordRequest {
  final String usersId;
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.usersId,
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'users_id': usersId,
      'old_password': oldPassword,
      'new_password': newPassword,
    };
  }
}
