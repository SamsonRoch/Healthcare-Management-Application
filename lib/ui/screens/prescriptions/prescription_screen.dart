import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class PrescriptionScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  
  const PrescriptionScreen({
    Key? key,
    this.patientId,
    this.patientName,
  }) : super(key: key);

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _prescriptions = [];
  
  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }
  
  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, these would be loaded from repositories
      // For now, we'll use placeholder data
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (widget.patientId != null) {
        // Load prescriptions for specific patient
        setState(() {
          _prescriptions = [
            {
              'id': '1',
              'medication': 'Amoxicillin',
              'dosage': '500mg',
              'frequency': 'Three times daily',
              'duration': '7 days',
              'instructions': 'Take with food',
              'date': DateTime.now().subtract(const Duration(days: 2)),
              'status': 'Active',
            },
            {
              'id': '2',
              'medication': 'Ibuprofen',
              'dosage': '400mg',
              'frequency': 'As needed',
              'duration': '5 days',
              'instructions': 'Take for pain',
              'date': DateTime.now().subtract(const Duration(days: 5)),
              'status': 'Completed',
            },
          ];
        });
      } else {
        // Load all recent prescriptions
        setState(() {
          _prescriptions = [
            {
              'id': '1',
              'patient': 'John Smith',
              'medication': 'Amoxicillin',
              'dosage': '500mg',
              'frequency': 'Three times daily',
              'date': DateTime.now().subtract(const Duration(days: 2)),
              'status': 'Active',
            },
            {
              'id': '2',
              'patient': 'Sarah Johnson',
              'medication': 'Prenatal Vitamins',
              'dosage': '1 tablet',
              'frequency': 'Once daily',
              'date': DateTime.now().subtract(const Duration(days: 1)),
              'status': 'Active',
            },
            {
              'id': '3',
              'patient': 'Michael Brown',
              'medication': 'Insulin',
              'dosage': '10 units',
              'frequency': 'Before meals',
              'date': DateTime.now().subtract(const Duration(days: 3)),
              'status': 'Active',
            },
          ];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prescriptions: ${e.toString()}')),
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
  
  void _showAddPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Prescription'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _medicationController,
                  decoration: const InputDecoration(
                    labelText: 'Medication',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _frequencyController,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Special Instructions',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // In a real app, save to database
                setState(() {
                  _prescriptions.insert(0, {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'patient': widget.patientName ?? 'Current Patient',
                    'medication': _medicationController.text,
                    'dosage': _dosageController.text,
                    'frequency': _frequencyController.text,
                    'duration': _durationController.text,
                    'instructions': _instructionsController.text,
                    'date': DateTime.now(),
                    'status': 'Active',
                  });
                });
                
                // Clear form
                _medicationController.clear();
                _dosageController.clear();
                _frequencyController.clear();
                _durationController.clear();
                _instructionsController.clear();
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription added successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final bool isDoctor = currentUser?.role == UserRole.doctor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName != null 
            ? 'Prescriptions for ${widget.patientName}' 
            : 'Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No prescriptions found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      if (isDoctor)
                        ElevatedButton.icon(
                          onPressed: _showAddPrescriptionDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Prescription'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index];
                    final bool isActive = prescription['status'] == 'Active';
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    prescription['medication'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    prescription['status'],
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (prescription.containsKey('patient'))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Patient: ${prescription['patient']}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                const Icon(Icons.medical_information, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Dosage: ${prescription['dosage']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Frequency: ${prescription['frequency']}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            if (prescription.containsKey('duration'))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duration: ${prescription['duration']}',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            if (prescription.containsKey('instructions') && prescription['instructions'] != null && prescription['instructions'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Instructions: ${prescription['instructions']}',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            if (isDoctor && isActive)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        // In a real app, update in database
                                        setState(() {
                                          prescription['status'] = 'Completed';
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Prescription marked as completed')),
                                        );
                                      },
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      label: const Text('Complete', style: TextStyle(color: Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        // TODO: Implement edit functionality
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Edit functionality coming soon')),
                                        );
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: isDoctor
          ? FloatingActionButton(
              onPressed: _showAddPrescriptionDialog,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}