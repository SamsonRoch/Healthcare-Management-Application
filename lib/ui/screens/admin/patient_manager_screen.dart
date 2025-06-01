import 'package:flutter/material.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/widgets/app_scaffold.dart';
import 'package:patient_management_app/ui/widgets/user_list_tile.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:provider/provider.dart';

class PatientManagerScreen extends StatefulWidget {
  const PatientManagerScreen({super.key});

  @override
  State<PatientManagerScreen> createState() => _PatientManagerScreenState();
}

class _PatientManagerScreenState extends State<PatientManagerScreen> {
  bool _isLoading = true;
  List<User> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('PatientManagerScreen: Loading patients from AuthService...');
      final userRepository = locator<UserRepository>();
      
      // Directly fetch patients by role from Firestore
      final patientsList = await userRepository.getUsersByRoleFirestore(UserRole.patient.name);
      print('PatientManagerScreen: Fetched ${patientsList.length} patients directly from Firestore');
      
      if (patientsList.isEmpty) {
        // Create a sample patient if none exist
        final samplePatient = User(
          id: 'sample_patient_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Sample Patient',
          email: 'sample.patient@example.com',
          role: UserRole.patient,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          phoneNumber: '+1234567890',
        );
        
        await userRepository.createUser(samplePatient);
        print('Created sample patient with ID: ${samplePatient.id}');
        
        // Try fetching again
        final refreshedList = await userRepository.getUsersByRoleFirestore(UserRole.patient.name);
        print('PatientManagerScreen: After creating sample, found ${refreshedList.length} patients');
        
        if (mounted) {
          setState(() {
            _patients = refreshedList;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _patients = patientsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('PatientManagerScreen: Error loading patients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthService.roleRestricted(
      requiredRole: UserRole.admin,
      child: AppScaffold(
        title: 'Patient Management',
        showAppBar: true,
        showDrawer: true,
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatients,
              child: _patients.isEmpty
                ? const Center(child: Text('No patients found'))
                : ListView.builder(
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      final patient = _patients[index];
                      return UserListTile(
                        user: patient,
                        onTap: () => _navigateToPatientDetails(context, patient),
                      );
                    },
                  ),
            ),
      ),
    );
  }

  void _navigateToPatientDetails(BuildContext context, User patient) {
    Navigator.pushNamed(
      context,
      Routes.patientDetails,
      arguments: patient.id,
    );
  }
}