import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/services/staff_service.dart';
import 'package:patient_management_app/ui/screens/admin/create_staff.dart';
import 'package:patient_management_app/ui/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';

class StaffManagerScreen extends StatefulWidget {
  const StaffManagerScreen({super.key});

  @override
  State<StaffManagerScreen> createState() => _StaffManagerScreenState();
}

class _StaffManagerScreenState extends State<StaffManagerScreen> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return AuthService.roleRestricted(
      requiredRole: UserRole.admin,
      child: AppScaffold(
        title: 'Manage Staff',
        showAppBar: true,
        showDrawer: true,
        floatingActionButton: FloatingActionButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const CreateStaffScreen()),
  ),
  backgroundColor: AppTheme.primaryColor,
  child: const Icon(Icons.add),
  tooltip: 'Add Staff',
),
        body: FutureBuilder<List<User>>(
          future: Future.wait([
            // Use getUsersByRoleFirestore instead of getUsersByRole to fetch from Firestore
            locator<UserRepository>().getUsersByRoleFirestore(UserRole.doctor.name),
            locator<UserRepository>().getUsersByRoleFirestore(UserRole.nurse.name),
            locator<UserRepository>().getUsersByRoleFirestore(UserRole.receptionist.name),
          ]).then((results) => results.expand((list) => list).toList()),
          builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load staff'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final staff = snapshot.data ?? [];
    if (staff.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No staff found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final user = staff[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.accentColor,
              child: Text(user.name![0].toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            title: Text(user.name ?? user.email),
            subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('${user.email} (${user.role.name})'),
      if (user.specialty != null) Text('Specialty: ${user.specialty}'),
      if (user.departments?.isNotEmpty ?? false)
        Text('Departments: ${user.departments!.join(', ')}'),
    ],
  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    user.isActive ? Icons.lock_open : Icons.lock,
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                  onPressed: () => _toggleStaffStatus(context, user),
                  tooltip: user.isActive ? 'Deactivate' : 'Activate',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showUpdateStaffDialog(context, user),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
        );
      },
    );
  },
),
      ),
      fallback: const Center(child: Text('Access Denied: Admin Only')),
    );
  }

  void _showCreateStaffDialog(BuildContext context) {
  onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const CreateStaffScreen()),
  );
}

  void _showUpdateStaffDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => UpdateStaffDialog(user: user),
    );
  }

  Future<void> _toggleStaffStatus(BuildContext context, User user) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.currentUser!.hasPermission(Permission.deactivateStaff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
      return;
    }
    try {
      setState(() => _isLoading = true);
      
      // Use the StaffService to update staff status through the backend API
      final staffService = locator<StaffService>();
      final success = await staffService.updateStaffStatus(
        user.id,
        !user.isActive,
      );
      
      if (success) {
        // Update local state after successful API call
        final updatedUser = user.copyWith(
          isActive: !user.isActive,
          updatedAt: DateTime.now(),
        );
        await locator<UserRepository>().updateUser(updatedUser);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Staff ${user.isActive ? 'deactivated' : 'activated'}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update staff status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}



class UpdateStaffDialog extends StatefulWidget {
  final User user;
  const UpdateStaffDialog({super.key, required this.user});

  @override
  State<UpdateStaffDialog> createState() => _UpdateStaffDialogState();
}

class _UpdateStaffDialogState extends State<UpdateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _phoneNumber;
  late UserRole _role;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = widget.user.name!;
    _phoneNumber = widget.user.phoneNumber ?? '';
    _role = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Update Staff'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _name = value!,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _phoneNumber,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                      return 'Invalid phone number';
                    }
                  }
                  return null;
                },
                onSaved: (value) => _phoneNumber = value ?? '',
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<UserRole>(
                value: _role,
                items: [
                  UserRole.doctor,
                  UserRole.nurse,
                  UserRole.receptionist,
                ].map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(role.name),
                )).toList(),
                onChanged: _isLoading ? null : (value) => setState(() => _role = value!),
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStaff,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }

  Future<void> _updateStaff() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.currentUser!.hasPermission(Permission.updateStaff)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied')),
        );
        Navigator.pop(context);
        return;
      }
      setState(() => _isLoading = true);
      try {
        final updatedUser = widget.user.copyWith(
          name: _name,
          phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : null,
          role: _role,
          updatedAt: DateTime.now(),
        );
        await locator<UserRepository>().updateUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}