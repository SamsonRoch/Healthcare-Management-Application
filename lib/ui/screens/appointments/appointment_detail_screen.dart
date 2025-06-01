import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/appointment_model.dart';
import 'package:patient_management_app/data/models/patient_model.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/appointment_repository.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/services/rbac_service.dart';
import 'package:patient_management_app/ui/widgets/custom_button.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailScreen({Key? key, required this.appointmentId}) : super(key: key);

  @override
  _AppointmentDetailScreenState createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentRepository _appointmentRepository = locator<AppointmentRepository>();
  final PatientRepository _patientRepository = locator<PatientRepository>();
  final UserRepository _userRepository = locator<UserRepository>();
  final RBACService _rbacService = locator<RBACService>();
  
  bool _isLoading = true;
  bool _canEdit = false;
  Appointment? _appointment;
  Patient? _patient;
  User? _doctor;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _rbacService.hasPermission('manage_appointments');
    setState(() {
      _canEdit = hasPermission;
    });
  }

 Future<void> _loadAppointmentData() async {
  try {
    final appointment = await _appointmentRepository.getAppointmentById(widget.appointmentId);
    
    if (appointment != null) {
      // Check if appointment is active
      if (!appointment.isActive) {
        setState(() {
          _errorMessage = 'This appointment has been deleted.';
          _isLoading = false;
        });
        return;
      }
      
      // Validate patientId before querying
      if (appointment.patientId.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid patient ID in appointment.';
          _isLoading = false;
        });
        return;
      }
      
      final patient = await _patientRepository.getPatientById(appointment.patientId);
      
      // Validate doctorId before querying
      if (appointment.doctorId.isEmpty) {
        setState(() {
          _errorMessage = 'No doctor assigned to this appointment.';
          _appointment = appointment;
          _patient = patient;
          _doctor = null;
          _isLoading = false;
        });
        return;
      }
      
      // Get doctor information and cache it
      final doctor = await _userRepository.getUserById(appointment.doctorId);
      if (doctor == null) {
        setState(() {
          _errorMessage = 'Doctor not found for this appointment.';
          _appointment = appointment;
          _patient = patient;
          _doctor = null;
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _appointment = appointment;
        _patient = patient;
        _doctor = doctor;
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = 'Appointment not found';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error loading appointment: ${e.toString()}';
      _isLoading = false;
    });
  }
}
  Future<void> _updateAppointmentStatus(AppointmentStatus status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_appointment != null) {
        final updatedAppointment = _appointment!.copyWith(status: status);
        await _appointmentRepository.updateAppointment(updatedAppointment);
        
        // Reload appointment data
        await _loadAppointmentData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Appointment status updated to ${status.toString().split('.').last}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating appointment: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateAppointmentStatus(AppointmentStatus.cancelled);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadAppointmentData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildAppointmentDetails(),
    );
  }

  Widget _buildAppointmentDetails() {
    if (_appointment == null || _patient == null || _doctor == null) {
      return const Center(child: Text('Unable to load appointment details'));
    }

    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateFormat.format(_appointment!.appointmentDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      _buildStatusChip(_appointment!.status.toString().split('.').last),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeFormat.format(_appointment!.startTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Patient', _patient!.name),
                  _buildInfoRow('Doctor', _doctor!.name ?? _doctor!.email),
                  _buildInfoRow('Type', _appointment!.reason ?? 'Regular checkup'),
                  _buildInfoRow('Duration', '${_appointment!.durationInMinutes} minutes'),
                  if (_appointment!.notes != null && _appointment!.notes!.isNotEmpty) 
                    _buildInfoRow('Notes', _appointment!.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_canEdit && _appointment!.status != AppointmentStatus.cancelled && _appointment!.status != AppointmentStatus.completed) ...[  
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Mark as Completed',
                    onPressed: () => _updateAppointmentStatus(AppointmentStatus.completed),
                    textColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Cancel Appointment',
                    onPressed: _cancelAppointment,
                    textColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusStr) {
    Color chipColor;
    switch (statusStr) {
      case 'scheduled':
        chipColor = Colors.blue;
        break;
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      case 'noShow':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        statusStr.substring(0, 1).toUpperCase() + statusStr.substring(1),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}