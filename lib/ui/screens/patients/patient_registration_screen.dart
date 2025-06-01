import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/widgets/custom_button.dart';
import 'package:patient_management_app/ui/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                validator: (value) => value!.isEmpty ? 'Required' : null, 
                hintText: 'Full Name',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.contains('@') ? null : 'Invalid email', 
                hintText: 'Email',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                validator: (value) => value!.length >= 6 ? null : 'Min 6 characters', 
                hintText: 'Password',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                keyboardType: TextInputType.phone, 
                hintText: 'Phone Number ',
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              CustomButton(
                text: 'Register',
                isLoading: _isLoading,
                onPressed: _registerPatient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        UserRole.patient,
        additionalData: {
          'phoneNumber': _phoneController.text.trim(),
          'createdAt': DateTime.now(),
        },
      );

      // Registration success handled in AuthService navigation
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}'; 
        _isLoading = false;
      });
    }
  }
}