import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/config/routes/routes.dart';
import 'package:patient_management_app/ui/screens/appointments/book_appointment_screen.dart';

class AppointmentItem extends StatelessWidget {
  final DocumentSnapshot document;
  final Function onRefresh;

  const AppointmentItem({
    Key? key,
    required this.document,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataMap = document.data();
    
    // Add null check for document data
    if (dataMap == null) {
      // Return an empty container or a placeholder if data is null
      return const SizedBox.shrink(); 
    }
    final data = dataMap as Map<String, dynamic>; 
    
    // Skip if appointment is not active
    if (data['isActive'] == false) {
      return const SizedBox.shrink();
    }

    String formattedDate = 'No date';
    final dateValue = data['date'];
    if (dateValue is Timestamp) {
      formattedDate = DateFormat('MMM dd, yyyy').format(dateValue.toDate());
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: const Icon(Icons.calendar_today),
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        title: Text(data['title'] ?? 'Appointment'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${data['doctorName'] ?? 'Not specified'}'),
            Text('$formattedDate at ${data['time'] ?? 'Not specified'}'),
            Text('Status: ${data['status'] ?? 'pending'}', 
                style: TextStyle(
                  color: _getStatusColor(data['status']),
                  fontWeight: FontWeight.bold,
                ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editAppointment(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteAppointment(context),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.appointmentDetail,
            arguments: document.id,
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  void _editAppointment(BuildContext context) async {
    final dataMap = document.data();
    if (dataMap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Appointment data not found.')),
      );
      return;
    }
    final data = dataMap as Map<String, dynamic>;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAppointmentScreen(
          appointmentId: document.id,
          existingData: data,
        ),
      ),
    );
    
    if (result == true) {
      onRefresh();
    }
  }

  void _confirmDeleteAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              _deleteAppointment(context);
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  void _deleteAppointment(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(document.id)
          .update({'isActive': false});
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
      
      onRefresh();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }
}