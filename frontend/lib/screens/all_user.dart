import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/widgets/header_widget.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AllUser extends StatefulWidget {
  const AllUser({super.key});

  @override
  State<AllUser> createState() => _AllUserState();
}

class _AllUserState extends State<AllUser> {
  final DataController dataController = Get.find<DataController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Redirect if not on web
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          "Tidak Tersedia",
          "Fitur User Management hanya tersedia di versi web",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        Get.back();
      });
      return;
    }
    
    _loadUserData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    dataController.getUserData();
  }

  List<dynamic> _getFilteredUsers() {
    if (_searchQuery.isEmpty) {
      return dataController.userData;
    }
    return dataController.userData.where((user) {
      final nama = user['users_nama']?.toString().toLowerCase() ?? '';
      final tlp = user['users_tlp']?.toString().toLowerCase() ?? '';
      final level = user['users_level'] == 1 ? 'admin' : 'user';
      return nama.contains(_searchQuery) || 
             tlp.contains(_searchQuery) ||
             level.contains(_searchQuery);
    }).toList();
  }

  String _getUserLevel(int level) {
    return level == 1 ? 'Admin' : 'User';
  }

  String _getUserStatus(int status) {
    return status == 1 ? 'Aktif' : 'Pending';
  }

  Color _getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  void _toggleUserStatus(String userId, String userNama, Map<String, dynamic> userData) async {
    final currentStatus = userData['users_status'] as int;
    final newStatus = currentStatus == 1 ? 0 : 1;
    final statusText = newStatus == 1 ? 'Aktif' : 'Pending';
    
    bool success = await dataController.updateUser(
      userId,
      userData['users_nama'],
      userData['users_tlp'],
      userData['users_level'],
      newStatus,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Status user berhasil diubah menjadi $statusText'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Gagal mengubah status user'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteUser(String userId, String userNama) async {
    bool success = await dataController.deleteUser(userId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('User berhasil dihapus'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Gagal menghapus user'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Daftar User",
            ),
            Expanded(
              child: Container(
                width: double.maxFinite,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: GetBuilder<DataController>(
                  builder: (controller) {
                    if (controller.isLoading) {
                      return Center(
                        child: SpinKitCircle(
                          color: AppColors.mainColor,
                          size: 50.0,
                        ),
                      );
                    }

                    final filteredUsers = _getFilteredUsers();

                    return Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari user...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),

                        // User count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: ${filteredUsers.length} user',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // User list
                        Expanded(
                          child: filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Belum ada user'
                                            : 'User tidak ditemukan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: () async {
                                    _loadUserData();
                                  },
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = filteredUsers[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          leading: CircleAvatar(
                                            backgroundColor: AppColors.mainColor,
                                            child: Text(
                                              user['users_nama'][0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            user['users_nama'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(user['users_tlp']),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: user['users_level'] == 1
                                                          ? Colors.blue.withOpacity(0.2)
                                                          : Colors.grey.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      _getUserLevel(user['users_level']),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: user['users_level'] == 1
                                                            ? Colors.blue
                                                            : Colors.grey[700],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(user['users_status'])
                                                          .withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      _getUserStatus(user['users_status']),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _getStatusColor(user['users_status']),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert),
                                            onSelected: (value) {
                                              if (value == 'view') {
                                                Get.toNamed(
                                                  RoutesClass.getViewUserRoute(),
                                                  arguments: user['users_id'],
                                                );
                                              } else if (value == 'edit') {
                                                Get.toNamed(
                                                  RoutesClass.getEditUserRoute(),
                                                  arguments: user['users_id'],
                                                );
                                              } else if (value == 'toggle_status') {
                                                _toggleUserStatus(
                                                  user['users_id'],
                                                  user['users_nama'],
                                                  user,
                                                );
                                              } else if (value == 'delete') {
                                                _deleteUser(
                                                  user['users_id'],
                                                  user['users_nama'],
                                                );
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => [
                                              const PopupMenuItem<String>(
                                                value: 'view',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.visibility, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Lihat Detail'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'toggle_status',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      user['users_status'] == 1 
                                                        ? Icons.unpublished 
                                                        : Icons.check_circle,
                                                      size: 20,
                                                      color: user['users_status'] == 1 
                                                        ? Colors.orange 
                                                        : Colors.green,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      user['users_status'] == 1 
                                                        ? 'Set Pending' 
                                                        : 'Set Aktif',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(RoutesClass.getAddUserRoute());
        },
        backgroundColor: AppColors.mainColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
