import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/appointments/appointment_list_screen.dart';
import 'package:patient_management_app/ui/screens/patients/patient_list_screen.dart';
import 'package:patient_management_app/ui/screens/patients/add_patient_screen.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ReceptionistDashboardScreen extends StatefulWidget {
  const ReceptionistDashboardScreen({super.key});

  @override
  State<ReceptionistDashboardScreen> createState() => _ReceptionistDashboardScreenState();
}

class _ReceptionistDashboardScreenState extends State<ReceptionistDashboardScreen> {
  bool _isLoading = false;
  int _appointmentsToday = 0;
  int _patientsWaiting = 0;
  int _newRegistrations = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, these would be loaded from repositories
      // For now, we'll use placeholder data
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _appointmentsToday = 12;
        _patientsWaiting = 3;
        _newRegistrations = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final userName = currentUser?.name ?? 'Receptionist';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receptionist Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(userName),
                  const SizedBox(height: 24),
                  _buildStatisticsRow(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Waiting Room'),
                  const SizedBox(height: 16),
                  _buildWaitingRoom(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add patient screen
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const AddPatientScreen()),
          // );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildWelcomeCard(String name) {
    return Card(
      elevation: 4,
      color: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: $_appointmentsToday appointments scheduled',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      children: [
        _buildStatCard('Appointments', _appointmentsToday.toString(), Icons.calendar_today, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Waiting', _patientsWaiting.toString(), Icons.people, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('New Patients', _newRegistrations.toString(), Icons.person_add, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          'Check-In',
          Icons.how_to_reg,
          () {
            // TODO: Navigate to patient check-in screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient check-in feature coming soon')),
            );
          },
        ),
        _buildActionButton(
          'Appointments',
          Icons.calendar_today,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppointmentListScreen()),
          ),
        ),
        _buildActionButton(
          'Patients',
          Icons.people,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientListScreen()),
          ),
        ),
        _buildActionButton(
          'Billing',
          Icons.receipt_long,
          () {
            // TODO: Navigate to billing screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Billing feature coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWaitingRoom() {
    // In a real app, this would be loaded from a repository
    final waitingPatients = [
      {'name': 'Emily Wilson', 'time': '09:15 AM', 'doctor': 'Dr. Johnson'},
      {'name': 'Robert Garcia', 'time': '09:30 AM', 'doctor': 'Dr. Smith'},
      {'name': 'Lisa Chen', 'time': '10:00 AM', 'doctor': 'Dr. Johnson'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: const [
                Expanded(child: Text('Patient', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 40),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: waitingPatients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final patient = waitingPatients[index];
              return ListTile(
                title: Row(
                  children: [
                    Expanded(child: Text(patient['name']!)),
                    Expanded(child: Text(patient['time']!)),
                    Expanded(child: Text(patient['doctor']!)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () {
                    // TODO: Mark patient as seen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${patient['name']} marked as checked in')),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
