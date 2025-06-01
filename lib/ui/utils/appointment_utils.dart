import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

/// A utility class that provides shared appointment functionality
/// to be used across different screens in the application.
class AppointmentUtils {
  /// Shows a dialog to book or edit an appointment
  static void showBookAppointmentDialog(BuildContext context, {
    String? appointmentId,
    Map<String, dynamic>? existingData,
    Function? onSuccess,
  }) {
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
                      'updatedAt': FieldValue.serverTimestamp(),
                    };
                    
                    if (appointmentId == null) {
                      // Create new appointment
                      appointmentData['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .add(appointmentData);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment booked successfully')),
                      );
                    } else {
                      // Update existing appointment
                      await FirebaseFirestore.instance
                          .collection('appointments')
                          .doc(appointmentId)
                          .update(appointmentData);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Appointment updated successfully')),
                      );
                    }
                    
                    // Call the success callback if provided
                    if (onSuccess != null) {
                      onSuccess();
                    }
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

  /// Confirms and deletes an appointment
  static void confirmDeleteAppointment(BuildContext context, DocumentSnapshot doc, {Function? onSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(doc.id)
                    .update({'status': 'cancelled'});
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment cancelled successfully')),
                );
                
                // Call the success callback if provided
                if (onSuccess != null) {
                  onSuccess();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
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

  /// Edits an existing appointment
  static void editAppointment(BuildContext context, DocumentSnapshot doc, {Function? onSuccess}) {
    final data = doc.data() as Map<String, dynamic>;
    showBookAppointmentDialog(
      context, 
      appointmentId: doc.id, 
      existingData: data,
      onSuccess: onSuccess,
    );
  }
}