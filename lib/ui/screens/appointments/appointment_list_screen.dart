import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/appointment_model.dart';
import 'package:patient_management_app/data/models/patient_model.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/data/repositories/appointment_repository.dart';
import 'package:patient_management_app/data/repositories/patient_repository.dart';
import 'package:patient_management_app/data/repositories/user_repository.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/appointments/appointment_detail_screen.dart';
import 'package:provider/provider.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> with SingleTickerProviderStateMixin {
  final AppointmentRepository _appointmentRepository = locator<AppointmentRepository>();
  final PatientRepository _patientRepository = locator<PatientRepository>();
  final UserRepository _userRepository = locator<UserRepository>();
  
  late TabController _tabController;
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  Map<String, Patient> _patientsMap = {};
  Map<String, User> _doctorsMap = {};
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _filterAppointments();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user to check role
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      // Load appointments based on user role
      List<Appointment> appointments = [];
      if (currentUser?.role == UserRole.doctor) {
        // For doctors, only load their appointments
        appointments = await _appointmentRepository.getAppointmentsByDoctor(currentUser!.id);
      } else if (currentUser?.role == UserRole.patient) {
        // For patients, only load their appointments
        appointments = await _appointmentRepository.getAppointmentsByPatient(currentUser!.id);
      } else {
        // For admin, receptionist, or other roles, load all appointments
        appointments = await _appointmentRepository.getAllAppointments();
      }
      
      // Filter out inactive appointments
      appointments = appointments.where((appointment) => appointment.isActive).toList();
      
      // Load patients and doctors for displaying names
      final patients = await _patientRepository.getAllPatients();
      final doctors = await _userRepository.getAllUsers();
      
      // Create maps for quick lookup
      final patientsMap = {for (var patient in patients) patient.id: patient};
      final doctorsMap = {for (var doctor in doctors) doctor.id: doctor};
      
      setState(() {
        _appointments = appointments;
        _patientsMap = patientsMap;
        _doctorsMap = doctorsMap;
        _isLoading = false;
      });
      
      _filterAppointments();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: ${e.toString()}')),
        );
      }
    }
  }
  
  void _filterAppointments() {
    final currentTab = _tabController.index;
    final now = DateTime.now();
    
    setState(() {
      // Filter by tab (Today, Upcoming, Past)
      switch (currentTab) {
        case 0: // Today
          _filteredAppointments = _appointments.where((appointment) {
            return _isSameDay(appointment.appointmentDate, now);
          }).toList();
          break;
        case 1: // Upcoming
          _filteredAppointments = _appointments.where((appointment) {
            return appointment.appointmentDate.isAfter(now) && 
                  !_isSameDay(appointment.appointmentDate, now);
          }).toList();
          break;
        case 2: // Past
          _filteredAppointments = _appointments.where((appointment) {
            return appointment.appointmentDate.isBefore(now) && 
                  !_isSameDay(appointment.appointmentDate, now);
          }).toList();
          break;
      }
      
      // Apply search filter if any
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        _filteredAppointments = _filteredAppointments.where((appointment) {
          final patientName = _patientsMap[appointment.patientId]?.name.toLowerCase() ?? '';
          final doctorName = _doctorsMap[appointment.doctorId]?.name?.toLowerCase() ?? '';
          final reason = appointment.reason?.toLowerCase() ?? '';
          
          return patientName.contains(query) || 
                doctorName.contains(query) || 
                reason.contains(query);
        }).toList();
      }
      
      // Sort by date and time
      _filteredAppointments.sort((a, b) {
        final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
        if (dateComparison != 0) return dateComparison;
        return a.startTime.compareTo(b.startTime);
      });
    });
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  void _navigateToAddAppointment() {
    // TODO: Navigate to add appointment screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add appointment functionality coming soon')),
    );
  }
  
  void _navigateToAppointmentDetail(String appointmentId) {
    // TODO: Implement appointment detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment detail functionality coming soon')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search appointments...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterAppointments();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? Center(
                        child: Text(
                          _getEmptyStateMessage(),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _filteredAppointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: currentUser != null && 
                           (currentUser.role == UserRole.admin || 
                            currentUser.role == UserRole.doctor || 
                            currentUser.role == UserRole.receptionist)
          ? FloatingActionButton(
              onPressed: _navigateToAddAppointment,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  String _getEmptyStateMessage() {
    final currentTab = _tabController.index;
    
    switch (currentTab) {
      case 0:
        return _searchQuery.isEmpty
            ? 'No appointments scheduled for today.'
            : 'No appointments match your search criteria.';
      case 1:
        return _searchQuery.isEmpty
            ? 'No upcoming appointments scheduled.'
            : 'No upcoming appointments match your search criteria.';
      case 2:
        return _searchQuery.isEmpty
            ? 'No past appointments found.'
            : 'No past appointments match your search criteria.';
      default:
        return 'No appointments found.';
    }
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      
      // Filter appointments for the selected date
      setState(() {
        _filteredAppointments = _appointments.where((appointment) {
          return _isSameDay(appointment.appointmentDate, _selectedDate);
        }).toList();
      });
      
      // Switch to Today tab
      _tabController.animateTo(0);
    }
  }
  
  Widget _buildAppointmentCard(Appointment appointment) {
    final patient = _patientsMap[appointment.patientId];
    final doctor = _doctorsMap[appointment.doctorId];
    final statusColor = _getStatusColor(appointment.status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(appointment.status),
            color: Colors.white,
          ),
        ),
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(appointment.patientId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading patient info...');
            }
            if (snapshot.hasError) {
              return const Text('Error loading patient');
            }
            if (snapshot.hasData && snapshot.data != null) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final patientName = userData?['name'] as String? ?? 'Unknown Patient';
              return Text(patientName);
            }
            return const Text('Unknown Patient');
          },
        ),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. ${doctor?.name ?? 'Unknown'}'),
            Text(
              '${_formatDate(appointment.appointmentDate)} • ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}',
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            _formatStatus(appointment.status),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          backgroundColor: statusColor,
        ),
        onTap: () => _navigateToAppointmentDetail(appointment.id),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
  
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
  
  String _formatStatus(AppointmentStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.teal;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.orange;
      case AppointmentStatus.rescheduled:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.task_alt;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
      case AppointmentStatus.rescheduled:
        return Icons.update;
      default:
        return Icons.event;
    }
  }
}