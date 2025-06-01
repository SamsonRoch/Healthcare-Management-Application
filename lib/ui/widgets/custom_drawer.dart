import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_app/data/models/user_model.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentColor,
                  radius: 36,
                  child: _buildAvatarContent(currentUser),
                ),
                const SizedBox(height: 10),
                Text(
                  currentUser?.name ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser?.email ?? 'Please sign in',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (currentUser?.role == UserRole.admin) ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != Routes.adminDashboard) {
                  Navigator.pushReplacementNamed(context, Routes.adminDashboard);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Manage Staff'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.staffManager);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Manage Patients'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.patientManager);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != Routes.patientDashboard) {
                  Navigator.pushReplacementNamed(context, Routes.patientDashboard);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appointments'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointments coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Medical Records'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medical Records coming soon')),
                );
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.editProfile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Version: 1.0.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(User? currentUser) {
    if (currentUser == null) {
      return const Text(
        'G',
        style: TextStyle(color: Colors.white, fontSize: 24),
      );
    }
    if (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Image.network(
          currentUser.photoUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              _getAvatarInitial(currentUser),
              style: const TextStyle(color: Colors.white, fontSize: 24),
            );
          },
        ),
      );
    }
    return Text(
      _getAvatarInitial(currentUser),
      style: const TextStyle(color: Colors.white, fontSize: 24),
    );
  }

  String _getAvatarInitial(User user) {
    if (user.name != null && user.name!.isNotEmpty) {
      return user.name![0].toUpperCase();
    }
    if (user.email.isNotEmpty) {
      return user.email[0].toUpperCase();
    }
    return 'U';
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                      (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}