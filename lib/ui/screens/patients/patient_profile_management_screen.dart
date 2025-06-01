import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class PatientProfileManagementScreen extends StatefulWidget {
  const PatientProfileManagementScreen({super.key});

  @override
  State<PatientProfileManagementScreen> createState() => _PatientProfileManagementScreenState();
}

class _PatientProfileManagementScreenState extends State<PatientProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _allergyController;

  String? _selectedGender;
  String? _selectedBloodType;
  List<String> _allergies = [];
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = context.read<AuthService>().currentUser;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _dobController = TextEditingController(
      text: user?.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(user!.dateOfBirth!)
          : '',
    );
    _emergencyContactController = TextEditingController(text: user?.emergencyContact ?? '');
    _allergyController = TextEditingController();

    _selectedGender = user?.gender;
    _selectedBloodType = user?.bloodType;
    // Handle JSON-encoded allergies from SQLite
    if (user?.allergies != null) {
      try {
        _allergies = List<String>.from(user!.allergies!);
      } catch (e) {
        _allergies = [];
      }
    } else {
      _allergies = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _emergencyContactController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<AuthService>().updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        bloodType: _selectedBloodType,
        emergencyContact: _emergencyContactController.text.trim(),
        allergies: _allergies.isNotEmpty ? _allergies : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() {
          _isEditing = false;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addAllergy() {
    final allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty) {
      setState(() {
        _allergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(int index) {
    setState(() {
      _allergies.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    if (user == null) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _isEditing
                    ? Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _initializeControllers();
                        });
                      },
                      child: const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('SAVE'),
                    ),
                  ],
                )
                    : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProfileCard(user),
            const SizedBox(height: 20),
            _isEditing ? _buildEditForm() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : user.email[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.name ?? user.email,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Divider(height: 32),
            _buildInfoRow(Icons.phone, 'Phone', user.phoneNumber ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Address', user.address ?? 'Not provided'),
            _buildInfoRow(
              Icons.cake,
              'Date of Birth',
              user.dateOfBirth != null
                  ? DateFormat('yyyy-MM-dd').format(user.dateOfBirth!)
                  : 'Not provided',
            ),
            _buildInfoRow(Icons.person, 'Gender', user.gender ?? 'Not provided'),
            _buildInfoRow(Icons.bloodtype, 'Blood Type', user.bloodType ?? 'Not provided'),
            _buildInfoRow(Icons.emergency, 'Emergency Contact', user.emergencyContact ?? 'Not provided'),
            const SizedBox(height: 8),
            Text(
              'Allergies',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            user.allergies == null || user.allergies!.isEmpty
                ? const Text('No allergies recorded')
                : Wrap(
              spacing: 8,
              children: user.allergies!.map((allergy) {
                return Chip(
                  label: Text(allergy),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(
              labelText: 'Date of Birth (YYYY-MM-DD)',
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              final initialDate = _dobController.text.isNotEmpty
                  ? DateTime.tryParse(_dobController.text) ?? DateTime.now()
                  : DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: _genders.map((gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            decoration: const InputDecoration(
              labelText: 'Blood Type',
              border: OutlineInputBorder(),
            ),
            items: _bloodTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBloodType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyContactController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Allergies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _allergyController,
                  decoration: const InputDecoration(
                    labelText: 'Add Allergy',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addAllergy,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: List.generate(_allergies.length, (index) {
              return Chip(
                label: Text(_allergies[index]),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _removeAllergy(index),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Please log in to view your profile',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
}