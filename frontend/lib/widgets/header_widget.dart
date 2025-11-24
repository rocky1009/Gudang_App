import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proyek_gudang/routes/routes.dart';
import 'package:proyek_gudang/utils/app_colors.dart';
import 'package:proyek_gudang/controllers/auth_controller.dart';
import 'package:get/get.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawer;
  
  const HeaderWidget({
    super.key, 
    this.title = "Victoria",
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.mainColor,
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
      automaticallyImplyLeading: showDrawer,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isAdmin = authController.currentUser.value?.isAdmin ?? false;
    
    // Debug: Print values to console
    print('DEBUG - User Management Menu Check:');
    print('  isAdmin: $isAdmin');
    print('  kIsWeb: $kIsWeb');
    print('  Should show menu: ${isAdmin && kIsWeb}');
    print('  Current user: ${authController.currentUser.value?.usersNama}');
    print('  User level: ${authController.currentUser.value?.usersLevel}');
    
    return Drawer(
      // Optimize drawer performance
      width: 280,
      child: Material(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(), // Better scroll performance
          cacheExtent: 1000, // Pre-cache off-screen items
          children: [
            DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.mainColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 10),
                Text(
                  'Victoria',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: AppColors.mainColor),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Get.offAllNamed(RoutesClass.getHomeRoute());
            },
          ),
          // Gudang menu - Admin only
          if (isAdmin)
            ExpansionTile(
              leading: Icon(Icons.warehouse, color: AppColors.mainColor),
              title: Text('Gudang'),
              iconColor: AppColors.mainColor,
              collapsedIconColor: AppColors.mainColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.list, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('List Gudang'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getAllGudangRoute());
                  },
                ),
              ],
            ),
          ExpansionTile(
            leading: Icon(Icons.chair, color: AppColors.mainColor),
            title: Text('Barang'),
            iconColor: AppColors.mainColor,
            collapsedIconColor: AppColors.mainColor,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.list, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('List Barang'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getAllBarangRoute());
                },
              ),
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.output_outlined, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('Barang Keluar'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getAddBarangKeluarRoute());
                },
              ),
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.history, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('Riwayat Barang'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getLogsBarangRoute());
                },
              ),
              // Diskon - Admin only
              if (isAdmin)
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.local_offer, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Diskon'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getViewDiscountRoute());
                  },
                ),
            ],
          ),
          // Pabrik menu - Admin only
          if (isAdmin)
            ExpansionTile(
              leading: Icon(Icons.business, color: AppColors.mainColor),
              title: Text('Pabrik'),
              iconColor: AppColors.mainColor,
              collapsedIconColor: AppColors.mainColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.list, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('List Pabrik'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getAllTaskRoute());
                  },
                ),
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Pesan Barang'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getOrdersBarangRoute());
                  },
                ),
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.assignment, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Riwayat Pesanan'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getLogsOrdersRoute());
                  },
                ),
              ],
            ),
          ExpansionTile(
            leading: Icon(Icons.sell, color: AppColors.mainColor),
            title: Text('Penjualan'),
            iconColor: AppColors.mainColor,
            collapsedIconColor: AppColors.mainColor,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.people, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('List Customer'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getAllCustomerRoute());
                },
              ),
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.receipt, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('Nota'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getAddSalesRoute());
                },
              ),
              // Riwayat Penjualan - Admin only
              if (isAdmin)
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.point_of_sale, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Riwayat Penjualan'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getAllSalesRoute());
                  },
                ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.book, color: AppColors.mainColor),
            title: Text('Laporan'),
            iconColor: AppColors.mainColor,
            collapsedIconColor: AppColors.mainColor,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistik Keuntungan - Admin only
              if (isAdmin)
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Statistik Keuntungan'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getLogsProfitRoute());
                  },
                ),
              // Statistik Barang - Admin only
              if (isAdmin)
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.mainColor, size: 20),
                      SizedBox(width: 10),
                      Text('Statistik Barang'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getLogsStatisticsRoute());
                  },
                ),
              ListTile(
                leading: SizedBox(width: 24), // Indent for sub-menu
                title: Row(
                  children: [
                    Icon(Icons.analytics, color: AppColors.mainColor, size: 20),
                    SizedBox(width: 10),
                    Text('Statistik Stok'),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Get.toNamed(RoutesClass.getLogsRingkasanBarangRoute());
                },
              ),
            ],
          ),
          // User Management - Admin only and Web only
          if (isAdmin && kIsWeb)
            ExpansionTile(
              leading: Icon(Icons.people, color: AppColors.mainColor),
              title: Text('User Management'),
              iconColor: AppColors.mainColor,
              collapsedIconColor: AppColors.mainColor,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: SizedBox(width: 24), // Indent for sub-menu
                  title: Row(
                    children: [
                      Icon(Icons.list, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text('List User'),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(RoutesClass.getAllUserRoute());
                  },
                ),
              ],
            ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock_reset, color: AppColors.mainColor),
            title: Text('Ubah Password'),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed(RoutesClass.getChangePasswordRoute());
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              print('DEBUG: Logout tile tapped');
              
              final authController = Get.find<AuthController>();
              
              // Close drawer first
              Navigator.pop(context);
              
              // Use Get.dialog instead of showDialog to avoid context issues
              print('DEBUG: Showing logout dialog with Get.dialog');
              Get.dialog(
                AlertDialog(
                  title: Text('Logout'),
                  content: Text('Apakah anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        print('DEBUG: Batal button clicked');
                        Get.back(result: false);
                        print('DEBUG: Dialog closed with false');
                      },
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        print('DEBUG: Logout button clicked');
                        Get.back(result: true);
                        print('DEBUG: Dialog closed with true');
                        
                        print('DEBUG: Starting logout process');
                        await authController.logout();
                        print('DEBUG: Logout completed, navigating to login');
                        Get.offAllNamed(RoutesClass.getLoginRoute());
                        print('DEBUG: Navigation to login completed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Logout'),
                    ),
                  ],
                ),
                barrierDismissible: false,
              );
            },
          ),
        ],
        ),
      ),
    );
  }
}

// Complete scaffold with header and drawer for easy reuse
class ScaffoldWithHeader extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showDrawer;
  final FloatingActionButton? floatingActionButton;

  const ScaffoldWithHeader({
    super.key,
    required this.body,
    this.title = "Victoria",
    this.showDrawer = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderWidget(
        title: title,
        showDrawer: showDrawer,
      ),
      drawer: showDrawer ? const CustomDrawer() : null,
      drawerEdgeDragWidth: 60, // Increase drag area
      drawerEnableOpenDragGesture: true,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
