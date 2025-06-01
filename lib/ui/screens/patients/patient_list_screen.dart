import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/patient_model.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/patients/patient_detail_screen.dart';
import 'package:provider/provider.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientRepository _patientRepository = locator<PatientRepository>();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
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
      print('PatientListScreen: Loading patients from repository...');
      final patients = await _patientRepository.getAllPatients();
      print('PatientListScreen: Loaded ${patients.length} patients');
      
      if (mounted) {
        setState(() {
          _patients = patients;
          _filteredPatients = patients;
          _isLoading = false;
        });
        
        // Show a message if no patients were found
        if (patients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No patients found in database. Try adding a patient.')),
          );
        }
      }
    } catch (e) {
      print('PatientListScreen: Error loading patients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading patients: ${e.toString()}')),
        );
      }
    }
  }
  
  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final name = patient.name.toLowerCase();
          final searchLower = query.toLowerCase();
          final phoneMatch = patient.phoneNumber != null ? 
              patient.phoneNumber!.contains(searchLower) : false;
          final emailMatch = patient.email != null ? 
              patient.email!.toLowerCase().contains(searchLower) : false;
          
          return name.contains(searchLower) || phoneMatch || emailMatch;
        }).toList();
      }
    });
  }
  
  void _navigateToAddPatient() {
    // TODO: Navigate to add patient screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add patient functionality coming soon')),
    );
  }
  
  void _navigateToPatientDetail(String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailScreen(patientId: patientId),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterPatients,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: _searchQuery.isEmpty
                            ? const Text('No patients found. Add a new patient to get started.')
                            : const Text('No patients match your search criteria.'),
                      )
                    : ListView.builder(
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return _buildPatientCard(patient);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: currentUser != null && 
                           (currentUser.role == UserRole.admin || 
                            currentUser.role == UserRole.doctor || 
                            currentUser.role == UserRole.nurse || 
                            currentUser.role == UserRole.receptionist)
          ? FloatingActionButton(
              onPressed: _navigateToAddPatient,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(patient.name),
        subtitle: Text(
          '${_formatGender(patient.gender)} • ${_calculateAge(patient.dateOfBirth)} years • ${patient.phoneNumber ?? 'No phone'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToPatientDetail(patient.id),
      ),
    );
  }
  
  String _formatGender(String gender) {
    return gender.isNotEmpty ? gender[0].toUpperCase() + gender.substring(1) : 'Unknown';
  }
  
  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    final monthDiff = currentDate.month - birthDate.month;
    
    if (monthDiff < 0 || (monthDiff == 0 && currentDate.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
}