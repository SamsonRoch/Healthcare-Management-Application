import 'package:flutter/material.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:patient_management_app/ui/screens/patients/patient_list_screen.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  bool _isLoading = false;
  int _patientsAssigned = 0;
  int _medicationsDue = 0;
  int _tasksCompleted = 0;

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
        _patientsAssigned = 8;
        _medicationsDue = 12;
        _tasksCompleted = 5;
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
    final userName = currentUser?.name ?? 'Nurse';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse Dashboard'),
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
                  _buildSectionTitle('Medication Schedule'),
                  const SizedBox(height: 16),
                  _buildMedicationSchedule(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Patient Vitals'),
                  const SizedBox(height: 16),
                  _buildPatientVitals(),
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
              'Welcome back, $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have $_medicationsDue medications due today',
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
        _buildStatCard('Patients', _patientsAssigned.toString(), Icons.people, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Medications', _medicationsDue.toString(), Icons.medication, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard('Tasks Done', _tasksCompleted.toString(), Icons.task_alt, Colors.green),
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
          'Record Vitals',
          Icons.monitor_heart,
          () {
            // TODO: Navigate to vitals recording screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vitals recording feature coming soon')),
            );
          },
        ),
        _buildActionButton(
          'Medications',
          Icons.medication,
          () {
            // TODO: Navigate to medication administration screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Medication administration feature coming soon')),
            );
          },
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
          'Care Notes',
          Icons.note_alt,
          () {
            // TODO: Navigate to care notes screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Care notes feature coming soon')),
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

  Widget _buildMedicationSchedule() {
    // In a real app, this would be loaded from a repository
    final medications = [
      {'patient': 'John Smith', 'medication': 'Lisinopril 10mg', 'time': '10:00 AM', 'status': 'Pending'},
      {'patient': 'Sarah Johnson', 'medication': 'Prenatal Vitamin', 'time': '12:00 PM', 'status': 'Pending'},
      {'patient': 'Michael Brown', 'medication': 'Insulin', 'time': '11:30 AM', 'status': 'Administered'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: medications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final med = medications[index];
          final bool isAdministered = med['status'] == 'Administered';
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isAdministered ? Colors.green : Colors.orange,
              child: Icon(
                isAdministered ? Icons.check : Icons.access_time,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(med['medication']!),
            subtitle: Text('${med['patient']} - ${med['time']}'),
            trailing: TextButton(
              onPressed: isAdministered ? null : () {
                // TODO: Mark as administered
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${med['medication']} marked as administered')),
                );
              },
              child: Text(isAdministered ? 'Completed' : 'Administer'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientVitals() {
    // In a real app, this would be loaded from a repository
    final patients = [
      {'name': 'John Smith', 'room': '101', 'lastVitals': '2 hours ago', 'status': 'Stable'},
      {'name': 'Sarah Johnson', 'room': '105', 'lastVitals': '30 minutes ago', 'status': 'Monitoring'},
      {'name': 'Michael Brown', 'room': '110', 'lastVitals': '4 hours ago', 'status': 'Due Check'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patients.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patient = patients[index];
          final Color statusColor = patient['status'] == 'Stable' 
              ? Colors.green 
              : (patient['status'] == 'Monitoring' ? Colors.orange : Colors.red);
          
          return ListTile(
            title: Text(patient['name']!),
            subtitle: Text('Room ${patient['room']} - Last check: ${patient['lastVitals']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    patient['status']!,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_chart),
                  onPressed: () {
                    // TODO: Navigate to record vitals screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Record vitals for ${patient['name']}')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}