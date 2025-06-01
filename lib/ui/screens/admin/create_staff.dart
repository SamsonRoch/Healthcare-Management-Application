// lib/ui/screens/admin/create_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/services/staff_service.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class CreateStaffScreen extends StatefulWidget {
  const CreateStaffScreen({super.key});

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _availableDepartments = [
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Orthopedics',
    'Dermatology',
    'Oncology',
    'Emergency',
    'General Medicine',
  ];

  String _email = '', _name = '', _phoneNumber = '';
  UserRole _role = UserRole.doctor;
  String _specialty = '', _licenseNumber = '', _nursingLicense = '';
  List<String> _selectedDepartments = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Staff Member'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildPhoneField(),
                const SizedBox(height: 16),
                _buildRoleDropdown(),
                const SizedBox(height: 16),
                if (_role == UserRole.doctor) ...[
                  _buildSpecialtyField(),
                  const SizedBox(height: 16),
                  _buildLicenseField(),
                  const SizedBox(height: 16),
                ],
                if (_role == UserRole.nurse) ...[
                  _buildNursingLicenseField(),
                  const SizedBox(height: 16),
                ],
                if (_role != UserRole.receptionist) 
                  _buildDepartmentSelection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Invalid email';
        }
        return null;
      },
      onSaved: (value) => _email = value!,
      enabled: !_isLoading,
    );
  }
  Widget _buildNameField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Full Name',
      border: OutlineInputBorder(),
      hintText: 'Enter full name',
    ),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (value.length < 3) return 'Minimum 3 characters';
      return null;
    },
    onSaved: (value) => _name = value!,
    enabled: !_isLoading,
    textCapitalization: TextCapitalization.words,
  );
}

Widget _buildPhoneField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Phone Number',
      border: OutlineInputBorder(),
      hintText: '+1 234 567 8901',
      prefixText: '+',
    ),
    keyboardType: TextInputType.phone,
    validator: (value) {
      if (value != null && value.isNotEmpty) {
        if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
          return 'Invalid phone number format';
        }
      }
      return null;
    },
    onSaved: (value) => _phoneNumber = value ?? '',
    enabled: !_isLoading,
  );
}

Widget _buildRoleDropdown() {
  return DropdownButtonFormField<UserRole>(
    value: _role,
    onChanged: _isLoading
        ? null
        : (value) => setState(() => _role = value ?? UserRole.doctor),
    decoration: const InputDecoration(
      labelText: 'Role',
      border: OutlineInputBorder(),
    ),
    items: UserRole.values
        .where((role) => role != UserRole.admin && role != UserRole.patient)
        .map<DropdownMenuItem<UserRole>>((role) => DropdownMenuItem<UserRole>(
              value: role,
              child: Text(
                role.name,
                style: const TextStyle(fontSize: 14),
              ),
            ))
        .toList(),
  );
}

Widget _buildSpecialtyField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Medical Specialty',
      border: OutlineInputBorder(),
      hintText: 'Cardiology, Pediatrics, etc.',
    ),
    validator: (value) {
      if (_role == UserRole.doctor && (value == null || value.isEmpty)) {
        return 'Required for doctors';
      }
      return null;
    },
    onSaved: (value) => _specialty = value!,
    enabled: !_isLoading,
  );
}

Widget _buildLicenseField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Medical License Number',
      border: OutlineInputBorder(),
      hintText: 'MD-123456',
    ),
    validator: (value) {
      if (_role == UserRole.doctor) {
        if (value == null || value.isEmpty) return 'Required for doctors';
        if (!RegExp(r'^[A-Z]{2}-\d{6}$').hasMatch(value)) {
          return 'Format: AA-123456';
        }
      }
      return null;
    },
    onSaved: (value) => _licenseNumber = value!,
    enabled: !_isLoading,
  );
}

Widget _buildNursingLicenseField() {
  return TextFormField(
    decoration: const InputDecoration(
      labelText: 'Nursing License Number',
      border: OutlineInputBorder(),
      hintText: 'RN-123456',
    ),
    validator: (value) {
      if (_role == UserRole.nurse) {
        if (value == null || value.isEmpty) return 'Required for nurses';
        if (!RegExp(r'^[A-Z]{2}-\d{6}$').hasMatch(value)) {
          return 'Format: RN-123456';
        }
      }
      return null;
    },
    onSaved: (value) => _nursingLicense = value!,
    enabled: !_isLoading,
  );
}

  // Add similar builder methods for other fields (_buildNameField, etc.)

  Widget _buildDepartmentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Departments:', 
          style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 4,
            ),
            itemCount: _availableDepartments.length,
            itemBuilder: (context, index) {
              final department = _availableDepartments[index];
              return FilterChip(
                label: Text(department),
                selected: _selectedDepartments.contains(department),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedDepartments.add(department);
                  } else {
                    _selectedDepartments.remove(department);
                  }
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _createStaff,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryColor,
      ),
      child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Create Staff Member', style: TextStyle(fontSize: 16)),
    );
  }

 Future<void> _createStaff() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!authService.currentUser!.hasPermission(Permission.createStaff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final tempPassword = _generateTempPassword();

    try {
      final staffService = locator<StaffService>();

      // Prepare specialty and license based on role
      String? specialty;
      String? licenseNumber;

      if (_role == UserRole.doctor) {
        specialty = _specialty;
        licenseNumber = _licenseNumber;
      } else if (_role == UserRole.nurse) {
        licenseNumber = _nursingLicense;
      }

      final success = await staffService.createStaffMember(
        _email,
        tempPassword,
        _name,
        _role,
        phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : null,
        specialty: specialty,
        licenseNumber: licenseNumber,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff created successfully')),
        );

        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Staff Account Created'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Temporary Password:'),
                  SelectableText(tempPassword),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tempPassword));
                      Navigator.of(context).pop();
                    },
                    child: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
            ),
          );

          Navigator.of(context).pop(); // Go back to previous screen
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create staff member')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

String _generateTempPassword() {
  return DateTime.now().millisecondsSinceEpoch.toRadixString(36) + 'Ab1!';
}


}