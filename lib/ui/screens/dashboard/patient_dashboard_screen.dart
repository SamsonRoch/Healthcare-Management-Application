import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/data/models/user_model.dart';

import 'package:patient_management_app/ui/widgets/custom_app_bar.dart';
import 'package:patient_management_app/ui/widgets/custom_bottom_nav_bar.dart';
import 'package:patient_management_app/ui/widgets/custom_drawer.dart';
import 'package:provider/provider.dart';

import '../appointments/patient_appointment_screen.dart';
import '../appointments/book_appointment_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../../widgets/appointment_item.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedIndex = 0;
  Stream<QuerySnapshot>? _appointmentsStream;
  Stream<QuerySnapshot>? _recordsStream;
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
      
      print('PatientDashboardScreen initialized without a valid user');
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
      
      final recordsQuery = FirebaseFirestore.instance
          .collection('medical_records')
          .where('patientId', isEqualTo: userId);
          
      appointmentsQuery.get().then((querySnapshot) {
        if (mounted && _currentUserId == userId) {
          _appointmentsStream = appointmentsQuery.snapshots();
          setState(() {});
        }
      }).catchError((error) {
        print('Error fetching appointments: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
      recordsQuery.get().then((querySnapshot) {
        if (mounted && _currentUserId == userId) {
          _recordsStream = recordsQuery.snapshots();
          setState(() {});
        }
      }).catchError((error) {
        print('Error fetching medical records: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
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
      drawer: const CustomDrawer(),
      appBar: const CustomAppBar(
        title: 'Patient Dashboard',
        showDrawer: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToBookAppointment(context),
        child: const Icon(Icons.add),
        tooltip: 'Book Appointment',
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          switch (index) {
            case 0: // Dashboard - already on this screen
              break;
            case 1: // Appointments
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientAppointmentScreen()),
              );
              break;
            case 2: // Medical Records
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Medical Records coming soon')),
              );
              break;
            case 3: // Profile
              _navigateToEditProfile(context);
              break;
          }
        },
      ),
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : currentUser == null
      ? _buildLoginPrompt()
      : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColorDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back,',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      Text(
                        currentUser.name ?? currentUser.email,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      Icons.medical_services, 
                      'Records',
                      onPressed: () {}, // View all medical records
                    ),
                    _buildActionButton(
                      Icons.calendar_today, 
                      'Appointments',
                      onPressed: () => _navigateToBookAppointment(context),
                    ),
                    _buildActionButton(
                      Icons.person, 
                      'Profile',
                      onPressed: () => _navigateToEditProfile(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Upcoming Appointments Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Appointments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PatientAppointmentScreen()),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                SizedBox(
                  height: 200, // Fixed height for appointments section
                  child: _appointmentsStream == null 
                  ? const Center(child: Text('Unable to load appointments'))
                  : StreamBuilder<QuerySnapshot>(
                        stream: _appointmentsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
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
                                  const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No upcoming appointments',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _navigateToBookAppointment(context),
                                    child: const Text('Book Appointment'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          // Sort appointments by date client-side
                          final appointments = snapshot.data!.docs;
                          appointments.sort((a, b) {
                            final aDataMap = a.data();
                            final bDataMap = b.data();
                            
                            // Handle cases where document data might be null
                            if (aDataMap == null && bDataMap == null) return 0;
                            if (aDataMap == null) return 1; // Null data goes last
                            if (bDataMap == null) return -1; // Null data goes last
                            
                            final aData = aDataMap as Map<String, dynamic>; 
                            final bData = bDataMap as Map<String, dynamic>;
                            
                            final dateA = aData['date'] as Timestamp?;
                            final dateB = bData['date'] as Timestamp?;

                            // Handle nulls first
                            if (dateA == null && dateB == null) return 0;
                            if (dateA == null) return 1; // Nulls last
                            if (dateB == null) return -1; // Nulls last

                            // Now we know both are non-null, compare them
                            return dateA.compareTo(dateB);
                          });
                          
                          return ListView.builder(
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              return AppointmentItem(
                                document: appointments[index],
                                onRefresh: _handleRefresh,
                              );
                            },
                          );
                        }
                      
                      ),
                  ),
                
                // Medical Records Section
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Medical Records',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all medical records screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Medical Records coming soon')),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                SizedBox(
                  height: 200, // Fixed height for medical records section
                  child: _recordsStream == null 
                  ? const Center(child: Text('Unable to load medical records'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: _recordsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
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
                                const Icon(Icons.medical_services, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No medical records available',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // Sort records by date client-side
                        final records = snapshot.data!.docs;
                        records.sort((a, b) {
                          final aDataMap = a.data();
                          final bDataMap = b.data();
                          
                          // Handle cases where document data might be null
                          if (aDataMap == null && bDataMap == null) return 0;
                          if (aDataMap == null) return 1; // Null data goes last
                          if (bDataMap == null) return -1; // Null data goes last
                          
                          final aData = aDataMap as Map<String, dynamic>; 
                          final bData = bDataMap as Map<String, dynamic>;
                           
                          final dateA = aData['date'] as Timestamp?;
                          final dateB = bData['date'] as Timestamp?;

                          // Prioritize Timestamps, handle nulls and other types (Descending Order)
                          final isATimestamp = dateA is Timestamp;
                          final isBTimestamp = dateB is Timestamp;

                          if (dateA != null && dateB != null) {
                            return dateB.compareTo(dateA); // Descending with valid timestamps
                          } else if (dateA != null) {
                            return -1; // Non-null dates first
                          } else if (dateB != null) {
                            return 1; // Non-null dates first
                          } else {
                            // Both are null or non-Timestamp, handle nulls explicitly
                            if (dateA == null && dateB == null) return 0;
                            if (dateA == null) return 1; // Nulls last (older)
                            if (dateB == null) return -1; // Nulls last (older)
                            return 0; // Both non-Timestamp, non-null, treat as equal
                          }
                        });
                        
                        return ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final recordData = records[index].data();
                            if (recordData == null) {
                            // Handle null data case, maybe return an empty container or a placeholder
                            return const SizedBox.shrink(); 
                            }
                            final record = recordData as Map<String, dynamic>;
                            
                            final dateValue = record['date'];
                            final diagnosis = record['diagnosis'] as String? ?? 'No diagnosis';
                            final doctor = record['doctorName'] as String? ?? 'Unknown doctor';
                            
                            String formattedDate = 'No date';
                            if (dateValue is Timestamp) {
                              formattedDate = DateFormat('MMM d, yyyy').format(dateValue.toDate());
                            }
                            
                            return ListTile(
                              title: Text(diagnosis),
                              subtitle: Text('Dr. $doctor'),
                              trailing: Text(formattedDate),
                              // onTap: () => _navigateToMedicalRecordDetails(context, records[index]),
                            );
                          },
                        );
                      },
                    ),
                ),
              ],
            ),
          ),
        ),
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
            'Please log in to view your dashboard',
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

  Widget _buildActionButton(IconData icon, String label, {required VoidCallback onPressed}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 32),
          onPressed: onPressed,
        ),
        Text(label),
      ],
    );
  }

  void _navigateToBookAppointment(BuildContext context) async {
    // Check if user is logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment')),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BookAppointmentScreen(),
      ),
    );
    
    if (result == true) {
      _handleRefresh();
    }
  }

  void _navigateToEditProfile(BuildContext context) async {
    // Check if user is logged in
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to edit your profile')),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    
    if (result == true) {
      _handleRefresh();
    }
  }
  
  @override
  void dispose() {
    _isInitialized = false;
    _currentUserId = null;
    super.dispose();
  }
}