import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

class PatientBookingScreen extends StatefulWidget {
  const PatientBookingScreen({super.key});

  @override
  State<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

class _PatientBookingScreenState extends State<PatientBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Appointment',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Visit',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter reason for visit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Doctor (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Time',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 9:00 AM',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _bookAppointment,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('BOOK APPOINTMENT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User login expired. Please log in again.')),
        );
        return;
      }
      
      // Parse time string to create DateTime objects for start and end times
      String timeStr = _timeController.text.trim();
      if (timeStr.isEmpty) {
        timeStr = '9:00 AM';
      }
      
      // Format time string properly
      final format = DateFormat('h:mm a');
      DateTime startTime;
      DateTime endTime;
      
      try {
        startTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          format.parse(timeStr).hour,
          format.parse(timeStr).minute,
        );
        
        // Default appointment duration is 1 hour
        endTime = startTime.add(const Duration(hours: 1));
      } catch (e) {
        // Fallback if time parsing fails
        startTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          9, 0, // 9:00 AM
        );
        endTime = startTime.add(const Duration(hours: 1));
      }
      
      final appointmentData = {
        'patientId': userId,
        'doctorId': '', // This will be assigned by admin/receptionist
        'reason': _titleController.text.trim(),
        'doctorName': _doctorController.text.trim(),
        'appointmentDate': Timestamp.fromDate(_selectedDate),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'scheduled',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment requested successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: $e')),
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
}