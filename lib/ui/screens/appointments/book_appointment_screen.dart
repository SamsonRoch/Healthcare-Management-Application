import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/appointment_model.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/appointment_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/appointments/appointment_detail_screen.dart';
import 'package:patient_management_app/ui/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String? appointmentId;
  final Map<String, dynamic>? existingData;

  const BookAppointmentScreen({
    Key? key,
    this.appointmentId,
    this.existingData,
  }) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final UserRepository _userRepository = locator<UserRepository>();
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _loadingDoctors = true;
  List<User> _doctors = [];
  User? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
    _loadDoctors();
  }
  
  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
    });
    
    try {
      final doctors = await _userRepository.getUsersByRoleFirestore('doctor');
      setState(() {
        _doctors = doctors;
        _loadingDoctors = false;
      });
      
      // If editing and doctor was previously selected, find and select that doctor
      if (widget.existingData != null && widget.existingData!['doctorId'] != null) {
        final doctorId = widget.existingData!['doctorId'];
        final doctor = _doctors.firstWhere(
          (doc) => doc.id == doctorId,
          orElse: () => throw Exception('Doctor not found'),
        );
        if (doctor != null) {
          setState(() {
            _selectedDoctor = doctor;
          });
        }
      }
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _loadingDoctors = false;
      });
    }
  }

  void _loadAppointmentData() {
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _timeController.text = widget.existingData!['time'] ?? '';
      
      if (widget.existingData!['date'] != null) {
        _selectedDate = (widget.existingData!['date'] as Timestamp).toDate();
      }
    }
    
    // Default date if not set
    if (_selectedDate == null) {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // Helper method to combine date and time into a single DateTime object
  DateTime _combineDateTime(DateTime date, DateTime time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
  
  // Helper method to format time string properly
  String _formatTimeString(String timeStr) {
    // If it's just a number, assume it's an hour and format it properly
    if (RegExp(r'^\d+$').hasMatch(timeStr)) {
      int hour = int.parse(timeStr);
      // Determine AM/PM
      String period = (hour >= 12) ? 'PM' : 'AM';
      // Convert to 12-hour format
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:00 $period';
    }
    
    // If it has a number followed by am/pm (case insensitive)
    if (RegExp(r'^\d+\s*(am|pm)$', caseSensitive: false).hasMatch(timeStr)) {
      // Extract the number and am/pm
      final match = RegExp(r'^(\d+)\s*(am|pm)$', caseSensitive: false).firstMatch(timeStr);
      if (match != null) {
        final hour = match.group(1);
        final period = match.group(2)?.toUpperCase();
        return '$hour:00 $period';
      }
    }
    
    // If it already has a proper format, return as is
    return timeStr;
  }

  Future<void> _saveAppointment() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_selectedDoctor == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a doctor')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // Parse time string to create DateTime objects for start and end times
    final timeComponents = _timeController.text.trim().split(' - ');
    String startTimeStr = timeComponents.isNotEmpty ? timeComponents[0] : '9:00 AM';
    String endTimeStr = timeComponents.length > 1 ? timeComponents[1] : '10:00 AM';
    
    // Format time strings properly if they're just numbers
    startTimeStr = _formatTimeString(startTimeStr);
    endTimeStr = _formatTimeString(endTimeStr);
    
    // Create DateTime objects for start and end times
    final format = DateFormat('h:mm a');
    final startTime = _combineDateTime(_selectedDate!, format.parse(startTimeStr));
    final endTime = _combineDateTime(_selectedDate!, format.parse(endTimeStr));
    
    // Create appointment using the repository to ensure proper model structure
    final appointment = Appointment(
      id: widget.appointmentId,
      patientId: userId,
      doctorId: _selectedDoctor!.id,
      appointmentDate: _selectedDate!,
      startTime: startTime,
      endTime: endTime,
      reason: _titleController.text.trim(),
      status: AppointmentStatus.scheduled,
    );
    
    final appointmentRepository = locator<AppointmentRepository>();
    String appointmentId;
    
    if (widget.appointmentId == null) {
      // Create new appointment
      appointmentId = await appointmentRepository.createAppointment(appointment);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment requested successfully')),
      );
    } else {
      // Update existing appointment
      appointmentId = widget.appointmentId!;
      await appointmentRepository.updateAppointment(appointment);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment updated successfully')),
      );
    }

    // Navigate to detail screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailScreen(appointmentId: appointmentId),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save appointment: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.appointmentId != null;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Edit Appointment' : 'Book Appointment',
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
                    // Appointment icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title/Reason field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Reason for Visit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medical_services),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter reason for visit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Doctor dropdown
                    _loadingDoctors
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        height: 60, // Fixed height to ensure dropdown displays properly
                        child: DropdownButtonFormField<User>(
                          isExpanded: true, // Make dropdown take full width
                          decoration: const InputDecoration(
                            labelText: 'Select Doctor',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          hint: const Text('Select a doctor'),
                          value: _selectedDoctor,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a doctor';
                            }
                            return null;
                          },
                          items: _doctors.map((User doctor) {
                            // Get specialty from metadata if available
                            String specialty = '';
                            if (doctor.metadata != null && 
                                doctor.metadata!.containsKey('specialty') && 
                                doctor.metadata!['specialty'] != null) {
                              specialty = ' (${doctor.metadata!["specialty"]})';
                            }
                            
                            return DropdownMenuItem<User>(
                              value: doctor,
                              child: Text('${doctor.name ?? doctor.email}$specialty'),
                            );
                          }).toList(),
                          onChanged: (User? newValue) {
                            setState(() {
                              _selectedDoctor = newValue;
                            });
                          },
                          menuMaxHeight: 300, // Set maximum height for dropdown menu
                          icon: const Icon(Icons.arrow_drop_down), // Explicit dropdown icon
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_selectedDate!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Time field
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                        hintText: '9:00 AM',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter preferred time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _saveAppointment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEditing ? 'UPDATE APPOINTMENT' : 'BOOK APPOINTMENT',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}