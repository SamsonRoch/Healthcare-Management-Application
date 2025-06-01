import 'package:flutter/material.dart';
import 'package:patient_management_app/ui/widgets/custom_app_bar.dart';
import 'package:patient_management_app/ui/widgets/custom_bottom_nav_bar.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final Function(int)? onNavItemTap;
  final List<BottomNavItem>? navItems;
  final bool showAppBar;
  final bool showBottomNavBar;
  final List<Widget>? appBarActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final FloatingActionButton? floatingActionButton;
  final Color? backgroundColor;
  final bool showDrawer;  // Add this line

  const AppScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.onNavItemTap,
    this.navItems,
    this.showAppBar = true,
    this.showBottomNavBar = true,
    this.appBarActions,
    this.showBackButton = false,
    this.onBackPressed,
    this.floatingActionButton,
    this.backgroundColor,
    required this.showDrawer,  // Add this required parameter
  }) : super(key: key);

  @override
Widget build(BuildContext context) {
  final authService = Provider.of<AuthService>(context);
  final currentUser = authService.currentUser;

  return Scaffold(
    backgroundColor: backgroundColor,
    appBar: showAppBar
        ? CustomAppBar(
            title: title,
            actions: appBarActions,
            showDrawer: showDrawer,
            showBackButton: showBackButton,
            onBackPressed: onBackPressed,
          )
        : null,
    drawer: showDrawer ? const CustomDrawer() : null,
    body: body,
    bottomNavigationBar: showBottomNavBar && onNavItemTap != null
        ? CustomBottomNavBar(
            currentIndex: currentIndex,
            onTap: onNavItemTap!,
            customItems: navItems,
          )
        : null,
    floatingActionButton: floatingActionButton,
  );
}
}