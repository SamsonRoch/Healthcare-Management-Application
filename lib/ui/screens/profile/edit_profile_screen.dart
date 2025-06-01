import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _genderController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _nameController.text = user.name ?? "";
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _bloodTypeController.text = user.bloodType ?? '';
      _genderController.text = user.gender ?? '';
      _dobController.text = user.dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').format(user.dateOfBirth!)
          : '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Update user profile in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .update({
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dateOfBirth': _dobController.text.trim(),
      'gender': _genderController.text.trim(),
      'bloodType': _bloodTypeController.text.trim(),
      });
      
      // Update local user object through AuthService
      await authService.updateUserProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _genderController.text.trim(),
        bloodType: _bloodTypeController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        showDrawer: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile picture placeholder (you can add image upload later)
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final initialDate = _dobController.text.isNotEmpty
                            ? DateFormat('yyyy-MM-dd').parse(_dobController.text)
                            : DateTime.now();

                        final DateTime? picked = await showDatePicker(
                          context: context, // Add required context
                          initialDate: initialDate,
                          firstDate: DateTime(1900), // 100 years back
                          lastDate: DateTime.now(), // Today for birth dates
                        );

                        if (picked != null) {
                          _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                        }
                      },

                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _genderController.text.isEmpty ? null : _genderController.text,
                      items: ['Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onChanged: (value) => _genderController.text = value ?? '',
                      decoration: InputDecoration(labelText: 'Gender'),
                    ),
                    const SizedBox(height: 16),
                    // Blood Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _bloodTypeController.text.isEmpty ? null : _bloodTypeController.text,
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) => _bloodTypeController.text = value ?? '',
                      decoration: InputDecoration(labelText: 'Blood Type'),
                    ),
                    const SizedBox(height: 16),
                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Address field
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SAVE PROFILE', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}