import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/widgets/app_scaffold.dart';
import 'package:patient_management_app/ui/widgets/card_button.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthService.roleRestricted(
      requiredRole: UserRole.admin,
      child: AppScaffold(
        title: 'Admin Dashboard',
        showAppBar: true,
        showDrawer: true,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Consumer<AuthService>(
                    builder: (context, authService, _) {
                      final user = authService.currentUser;
                      if (user == null) {
                        return const Text('Loading...');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user.name}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your staff and patients efficiently.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CardButton(
                        icon: index == 0 ? Icons.people_alt : Icons.sick,
                        label: index == 0
                            ? 'Staff Management'
                            : 'Patient Management',
                        onTap: () => Navigator.pushNamed(
                          context,
                          index == 0
                              ? Routes.staffManager
                              : Routes.patientManager,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      fallback: const Center(child: Text('Access Denied: Admin Only')),
    );
  }
}