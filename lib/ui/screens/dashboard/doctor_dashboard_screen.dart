import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/appointments/appointment_list_screen.dart';
import 'package:patient_management_app/ui/screens/patients/patient_list_screen.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  bool _isLoading = false;
  int _appointmentsToday = 0;
  int _totalPatients = 0;
  int _pendingTasks = 0;

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
        _appointmentsToday = 1;
        _totalPatients = 3;
        _pendingTasks = 3;
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
    final userName = currentUser?.name ?? 'Doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
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
                  _buildSectionTitle('Recent Patients'),
                  const SizedBox(height: 16),
                  _buildRecentPatients(),
                ],
              ),
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
              'Welcome back, Dr. $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have $_appointmentsToday appointments today',
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
        _buildStatCard('Patients', _totalPatients.toString(), Icons.people, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Appointments', _appointmentsToday.toString(), Icons.calendar_today, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('Tasks', _pendingTasks.toString(), Icons.task, Colors.green),
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
          'Prescriptions',
          Icons.medical_services,
          () {
            // TODO: Navigate to prescription screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prescription feature coming soon')),
            );
          },
        ),
        _buildActionButton(
          'Medical Records',
          Icons.folder_shared,
          () {
            // TODO: Navigate to medical records screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medical records feature coming soon')),
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

  Widget _buildRecentPatients() {
    // In a real app, this would be loaded from a repository
    final dummyPatients = [
      {'name': 'John Smith', 'age': 45, 'condition': 'Hypertension'},
      {'name': 'Sarah Johnson', 'age': 32, 'condition': 'Pregnancy'},
      {'name': 'Michael Brown', 'age': 58, 'condition': 'Diabetes'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dummyPatients.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = dummyPatients[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                (patient['name'] as String).substring(0, 2).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(patient['name'] as String),
            subtitle: Text('Age: ${patient['age']} - ${patient['condition'] as String}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to patient detail
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View details for ${patient['name'] as String}')),
              );
            },
          );
        },
      ),
    );
  }
}