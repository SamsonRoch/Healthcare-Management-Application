import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/patient_model.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  
  const PatientDetailScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> with SingleTickerProviderStateMixin {
  final PatientRepository _patientRepository = locator<PatientRepository>();
  final UserRepository _userRepository = locator<UserRepository>();
  late TabController _tabController;
  Patient? _patient;
  User? _user;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatient();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPatient() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First try to get patient from PatientRepository
      try {
        final patient = await _patientRepository.getPatientById(widget.patientId);
        if (patient != null) {
          setState(() {
            _patient = patient;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error loading from PatientRepository: $e');
      }
      
      // If that fails, try to get user from UserRepository
      final user = await _userRepository.getUserById(widget.patientId);
      if (user != null && user.role == UserRole.patient) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        return;
      }
      
      // If we get here, no patient was found
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patient: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient?.name ?? _user?.name ?? 'Patient Details'),
        actions: [
          if (currentUser != null && 
              (currentUser.role == UserRole.admin || 
               currentUser.role == UserRole.doctor || 
               currentUser.role == UserRole.nurse))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditPatient,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Medical History'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_patient == null && _user == null)
              ? const Center(child: Text('Patient not found'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildMedicalHistoryTab(),
                    _buildAppointmentsTab(),
                  ],
                ),
      floatingActionButton: _buildFloatingActionButton(currentUser),
    );
  }
  
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_patient != null) ...[  // Display Patient model data
            // Patient photo/avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _patient!.name.isNotEmpty ? _patient!.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Basic information
            _buildInfoCard('Personal Information', [
              _buildInfoRow('Name', _patient!.name),
              _buildInfoRow('Gender', _patient!.gender),
              _buildInfoRow('Date of Birth', _formatDate(_patient!.dateOfBirth)),
              _buildInfoRow('Blood Group', _patient!.bloodGroup ?? 'Not specified'),
            ]),
            const SizedBox(height: 16),
            
            // Contact information
            _buildInfoCard('Contact Information', [
              _buildInfoRow('Phone', _patient!.phoneNumber ?? 'Not provided'),
              _buildInfoRow('Email', _patient!.email ?? 'Not provided'),
              _buildInfoRow('Address', _patient!.address ?? 'Not provided'),
            ]),
            const SizedBox(height: 16),
            
            // Emergency contact
            _buildInfoCard('Emergency Contact', [
              _buildInfoRow('Name', _patient!.emergencyContact ?? 'Not provided'),
              _buildInfoRow('Phone', _patient!.emergencyContactPhone ?? 'Not provided'),
            ]),
          ] else if (_user != null) ...[  // Display User model data
            // User photo/avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  _user!.name!.isNotEmpty ? _user!.name![0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Basic information
            _buildInfoCard('Personal Information', [
              _buildInfoRow('Name', _user?.name?? ''),
              _buildInfoRow('Role', _user!.role.toString().split('.').last),
              _buildInfoRow('Status', _user!.isActive ? 'Active' : 'Inactive'),
            ]),
            const SizedBox(height: 16),
            
            // Contact information
            _buildInfoCard('Contact Information', [
              if (_user!.phoneNumber != null)
                _buildInfoRow('Phone', _user!.phoneNumber!),
              _buildInfoRow('Email', _user!.email),
            ]),
            const SizedBox(height: 16),
            
            // Account information
            _buildInfoCard('Account Information', [
              _buildInfoRow('Created', _formatDate(_user!.createdAt)),
              _buildInfoRow('Last Updated', _formatDate(_user!.updatedAt)),
            ]),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMedicalHistoryTab() {
    if (_patient != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Allergies
          _buildInfoCard('Allergies', [
            if (_patient!.allergies == null || _patient!.allergies!.isEmpty)
              _buildInfoRow('', 'No known allergies')
            else
              ..._patient!.allergies!.map((allergy) => _buildInfoRow('', allergy)).toList(),
          ]),
          const SizedBox(height: 16),
          
          // Chronic conditions
          _buildInfoCard('Chronic Conditions', [
            if (_patient!.chronicConditions == null || _patient!.chronicConditions!.isEmpty)
              _buildInfoRow('', 'No chronic conditions')
            else
              ..._patient!.chronicConditions!.map((condition) => _buildInfoRow('', condition)).toList(),
          ]),
          const SizedBox(height: 16),
          
          // Medical history
          if (_patient!.medicalHistory != null && _patient!.medicalHistory!.isNotEmpty)
            ..._patient!.medicalHistory!.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(entry.key, [
                    _buildInfoRow('', entry.value.toString()),
                  ]),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
        ],
      );
    } else if (_user != null) {
      // For User model, show simplified medical history
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_information, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Basic patient account',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This patient was created from the user system and does not have detailed medical records yet.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return const Center(child: Text('No medical history available'));
    }
  }
  
  Widget _buildAppointmentsTab() {
    if (_patient != null || _user != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No appointments found',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Appointments for this patient will be shown here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return const Center(child: Text('No appointment data available'));
    }
  }
  
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[  
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  Widget _buildFloatingActionButton(User? currentUser) {
    if (currentUser == null || 
        !(currentUser.role == UserRole.admin || 
          currentUser.role == UserRole.doctor || 
          currentUser.role == UserRole.nurse)) {
      return Container();
    }
    
    return FloatingActionButton(
      onPressed: () {
        // Implement action based on current tab
        final currentTab = _tabController.index;
        switch (currentTab) {
          case 0: // Info tab
            _navigateToEditPatient();
            break;
          case 1: // Medical History tab
            if (_patient != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add/edit medical history functionality coming soon')),
              );
            } else if (_user != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This patient needs to be converted to a full patient record first')),
              );
            }
            break;
          case 2: // Appointments tab
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Book appointment functionality coming soon')),
            );
            break;
        }
      },
      child: const Icon(Icons.add),
    );
  }
  
  void _navigateToEditPatient() {
    if (_patient != null) {
      // Navigate to edit patient screen with Patient model
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit patient functionality coming soon')),
      );
    } else if (_user != null) {
      // Navigate to edit user screen with User model
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit patient account functionality coming soon')),
      );
    }
  }
}