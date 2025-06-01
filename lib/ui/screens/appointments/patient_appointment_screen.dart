import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/appointments/patient_booking_screen.dart';
import 'package:provider/provider.dart';

class PatientAppointmentScreen extends StatefulWidget {
  const PatientAppointmentScreen({super.key});

  @override
  State<PatientAppointmentScreen> createState() => _PatientAppointmentScreenState();
}

class _PatientAppointmentScreenState extends State<PatientAppointmentScreen> {
  Stream<QuerySnapshot>? _appointmentsStream;
  bool _isLoading = true;
  String? _currentUserId;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
    }
  }
  
  void _initializeData() {
    if (_isInitialized) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    
    if (userId != null && userId != _currentUserId) {
      _currentUserId = userId;
      _setupStreams(userId);
      _isInitialized = true;
    } else if (userId == null) {
      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    }
  }
  
  void _setupStreams(String userId) {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appointmentsQuery = FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: userId);
      
      appointmentsQuery.get().then((querySnapshot) {
        if (mounted && _currentUserId == userId) {
          _appointmentsStream = appointmentsQuery.snapshots();
          setState(() {
            _isLoading = false;
          });
        }
      }).catchError((error) {
        print('Error fetching appointments: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
      // Set loading to false after a reasonable timeout
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error setting up streams: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    if (userId == null || userId != _currentUserId) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      _setupStreams(userId);
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    return;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    
    if (currentUser?.id != _currentUserId && !_isLoading) {
      _isInitialized = false;
      _initializeData();
    }
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookAppointmentDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Book Appointment',
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : currentUser == null
        ? _buildLoginPrompt()
        : RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Appointments',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _appointmentsStream == null 
                      ? const Center(child: Text('Unable to load appointments'))
                      : StreamBuilder<QuerySnapshot>(
                          stream: _appointmentsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            if (snapshot.hasError) {
                              return Center(child: Text('Error: ${snapshot.error}'));
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No appointments found',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => _showBookAppointmentDialog(context),
                                      child: const Text('Book New Appointment'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            final docs = snapshot.data!.docs;
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                return _buildAppointmentItem(index, docs[index]);
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAppointmentItem(int index, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();
    
    // Safely extract appointment details with fallbacks
    final appointmentDate = data['date'] as Timestamp?;
    final date = appointmentDate != null 
        ? DateFormat('MMM dd, yyyy').format(appointmentDate.toDate())
        : 'Not scheduled';
    
    // Fix for time display issue - check both 'time' field and fallback to title field if needed
    String time;
    if (data.containsKey('time') && data['time'] != null && data['time'].toString().isNotEmpty) {
      time = data['time'].toString();
    } else if (data.containsKey('title') && data['title'] != null) {
      time = 'Reason: ${data['title']}';
    } else {
      time = 'Time not set';
    }
    
    final doctorId = data['doctorId'] as String?;
    // Check both reason and title fields for appointment reason
    final reason = data['reason'] as String? ?? data['title'] as String? ?? 'General checkup';
    final status = data['status'] as String? ?? 'pending';
    
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(Icons.calendar_today),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        title: Text(reason),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctorId?.isNotEmpty ?? false)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(doctorId).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Doctor: Error loading doctor info');
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    final doctorData = snapshot.data!.data() as Map<String, dynamic>?;
                    final doctorName = doctorData?['name'] as String? ?? 'Unknown Doctor';
                    return Text('Doctor: $doctorName');
                  }
                  return const Text('Doctor: Loading...');
                },
              )
            else
              const Text('Doctor: Not assigned'),
            Text('$date at $time'),
            Row(
              children: [
                Text('Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: status.toLowerCase() != 'cancelled' && status.toLowerCase() != 'completed'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editAppointment(doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDeleteAppointment(doc),
                  ),
                ],
              )
            : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.appointmentDetail,
            arguments: doc.id,
          );
        },
      ),
    );
  }



  void _confirmDeleteAppointment(DocumentSnapshot doc) {
    if (!mounted) return;
    
    final BuildContext currentContext = context;
    showDialog(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(doc.id)
                    .update({'status': 'cancelled'});
                
                if (!mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(content: Text('Failed to cancel appointment: $e')),
                );
              }
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  void _navigateToBookingScreen() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return;
    }
    
    // Navigate to the dedicated booking screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientBookingScreen()),
    );
    
    // If appointment was successfully booked, refresh the list
    if (result == true) {
      _handleRefresh();
    }
  }
  
  void _showBookAppointmentDialog(BuildContext context, {String? appointmentId, Map<String, dynamic>? existingData}) {
    // Check if user is logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return;
    }
    
    final titleController = TextEditingController(text: existingData?['title'] ?? '');
    final doctorController = TextEditingController(text: existingData?['doctorName'] ?? '');
    final timeController = TextEditingController(text: existingData?['time'] ?? '');
    
    DateTime selectedDate = existingData?['date'] != null 
        ? (existingData!['date'] as Timestamp).toDate() 
        : DateTime.now().add(const Duration(days: 1));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(appointmentId == null ? 'Book Appointment' : 'Edit Appointment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Reason for Visit'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(labelText: 'Preferred Doctor (optional)'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Preferred Time'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter reason for visit')),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  try {
                    final userId = authService.currentUser?.id;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User login expired. Please log in again.')),
                      );
                      return;
                    }
                    
                    final appointmentData = {
                      'patientId': userId,
                      'title': titleController.text.trim(),
                      'doctorName': doctorController.text.trim(),
                      'date': Timestamp.fromDate(selectedDate),
                      'time': timeController.text.trim(),
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    
                    if (appointmentId != null) {
                      // Update existing appointment
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc(appointmentId)
                          .update(appointmentData);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment updated successfully')),
                      );
                    } else {
                      // Create new appointment
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .add(appointmentData);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment booked successfully')),
                      );
                    }
                    
                    // Refresh the appointments list
                    _handleRefresh();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to ${appointmentId != null ? 'update' : 'book'} appointment: $e')),
                    );
                  }
                },
                child: Text(appointmentId != null ? 'UPDATE' : 'BOOK'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _editAppointment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final appointmentId = doc.id;
    
    // For editing, we'll still use a dialog for now
    final titleController = TextEditingController(text: data['title'] ?? '');
    final doctorController = TextEditingController(text: data['doctorName'] ?? '');
    final timeController = TextEditingController(text: data['time'] ?? '');
    
    DateTime selectedDate = data['date'] != null 
        ? (data['date'] as Timestamp).toDate() 
        : DateTime.now().add(const Duration(days: 1));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Appointment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Reason for Visit'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: doctorController,
                    decoration: const InputDecoration(labelText: 'Preferred Doctor (optional)'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(labelText: 'Preferred Time'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter reason for visit')),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final userId = authService.currentUser?.id;
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User login expired. Please log in again.')),
                      );
                      return;
                    }
                    
                    final appointmentData = {
                      'patientId': userId,
                      'title': titleController.text.trim(),
                      'doctorName': doctorController.text.trim(),
                      'date': Timestamp.fromDate(selectedDate),
                      'time': timeController.text.trim(),
                      'status': 'pending',
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    
                    // Update existing appointment
                    await FirebaseFirestore.instance
                        .collection('appointments')
                        .doc(appointmentId)
                        .update(appointmentData);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update appointment: $e')),
                    );
                  }
                },
                child: const Text('UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Please log in to view your appointments',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.login);
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _isInitialized = false;
    _currentUserId = null;
    super.dispose();
  }
}