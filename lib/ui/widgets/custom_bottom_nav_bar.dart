import 'package:flutter/material.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:provider/provider.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem>? customItems;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.customItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    // Default items if no custom items are provided
    final items = customItems ?? _getDefaultItems(currentUser);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        elevation: 0,
        items: items.map((item) => item.toBottomNavBarItem()).toList(),
      ),
    );
  }

  List<BottomNavItem> _getDefaultItems(User? user) {
    // Default items based on user role
    if (user == null) {
      return _getGuestItems();
    }

    switch (user.role) {
      case UserRole.patient:
        return _getPatientItems();
      case UserRole.doctor:
        return _getDoctorItems();
      case UserRole.nurse:
        return _getNurseItems();
      case UserRole.receptionist:
        return _getReceptionistItems();
      case UserRole.admin:
        return _getAdminItems();
      default:
        return _getGuestItems();
    }
  }

  List<BottomNavItem> _getGuestItems() {
    return [
      BottomNavItem(icon: Icons.home, label: 'Home'),
      BottomNavItem(icon: Icons.info, label: 'About'),
      BottomNavItem(icon: Icons.contact_support, label: 'Contact'),
      BottomNavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }

  List<BottomNavItem> _getPatientItems() {
    return [
      BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
      BottomNavItem(icon: Icons.calendar_today, label: 'Appointments'),
      BottomNavItem(icon: Icons.medical_services, label: 'Records'),
      BottomNavItem(icon: Icons.person, label: 'Profile'),
    ];
  }

  List<BottomNavItem> _getDoctorItems() {
    return [
      BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
      BottomNavItem(icon: Icons.people, label: 'Patients'),
      BottomNavItem(icon: Icons.calendar_today, label: 'Schedule'),
      BottomNavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }

  List<BottomNavItem> _getNurseItems() {
    return [
      BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
      BottomNavItem(icon: Icons.people, label: 'Patients'),
      BottomNavItem(icon: Icons.medical_services, label: 'Tasks'),
      BottomNavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }

  List<BottomNavItem> _getReceptionistItems() {
    return [
      BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
      BottomNavItem(icon: Icons.calendar_today, label: 'Appointments'),
      BottomNavItem(icon: Icons.people, label: 'Patients'),
      BottomNavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }

  List<BottomNavItem> _getAdminItems() {
    return [
      BottomNavItem(icon: Icons.dashboard, label: 'Dashboard'),
      BottomNavItem(icon: Icons.people, label: 'Staff'),
      BottomNavItem(icon: Icons.analytics, label: 'Analytics'),
      BottomNavItem(icon: Icons.settings, label: 'Settings'),
    ];
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.label,
  });

  BottomNavigationBarItem toBottomNavBarItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}