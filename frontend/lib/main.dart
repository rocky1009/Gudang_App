import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import 'package:proyek_gudang/controllers/auth_controller.dart';
import 'package:proyek_gudang/routes/routes.dart';
import 'package:get/get.dart';

void main() {
  Get.put(DataController());
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Gudang',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
        // Faster drawer animation
        drawerTheme: const DrawerThemeData(
          scrimColor: Colors.black26, // Lighter scrim for better performance
        ),
        // Faster expansion tile animations
        expansionTileTheme: const ExpansionTileThemeData(
          tilePadding: EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
        ),
        // Disable slow animations on web
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: RoutesClass.getLoginRoute(),
      getPages: RoutesClass.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
