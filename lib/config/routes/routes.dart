import 'package:flutter/material.dart';
import 'package:patient_management_app/ui/screens/admin/admin_dashboard_screen.dart';
import 'package:patient_management_app/ui/screens/admin/create_staff.dart';
import 'package:patient_management_app/ui/screens/admin/staff_manager_screen.dart';
import 'package:patient_management_app/ui/screens/admin/patient_manager_screen.dart';
import 'package:patient_management_app/ui/screens/patients/patient_detail_screen.dart';

import 'package:patient_management_app/ui/screens/appointments/appointment_detail_screen.dart';
import 'package:patient_management_app/ui/screens/appointments/book_appointment_screen.dart';
import 'package:patient_management_app/ui/screens/medical_records/medical_record_detail_screen.dart'; // Make sure this file exists
import 'package:patient_management_app/ui/screens/auth/login_screen.dart';
import 'package:patient_management_app/ui/screens/dashboard/doctor_dashboard_screen.dart';
import 'package:patient_management_app/ui/screens/dashboard/patient_dashboard_screen.dart';
import 'package:patient_management_app/ui/screens/dashboard/receptionist_dashboard_screen.dart';
import 'package:patient_management_app/ui/screens/dashboard/nurse_dashboard_screen.dart';
import 'package:patient_management_app/ui/screens/patients/patient_home_screen.dart';
import 'package:patient_management_app/ui/screens/profile/edit_profile_screen.dart';
import 'package:patient_management_app/ui/screens/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  //static const String patientDashboard = '/patient_dashboard';
  static const String adminDashboard = '/admin_dashboard';
  static const String staffManager = '/staff_manager';
  static const String patientManager = '/patient_manager';
  static const String bookAppointment = '/book-appointment';
  static const String editProfile = '/edit-profile';
  //static const String adminDashboard = '/admin-dashboard';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String receptionistDashboard = '/receptionist-dashboard';
  static const String patientDashboard = '/patient-dashboard';
  static const String patientHome = '/patient-home';
  static const String nurseDashboard = '/nurse-dashboard';
  static const String createStaff = '/create-staff'; // Add this line for the new route
  static const String appointmentDetail = '/appointment-detail';
  static const String medicalRecordDetail = '/medical-record-detail';
  static const String patientDetails = '/patient-details';

  static RouteFactory getRoutes(BuildContext context) {
    return (RouteSettings settings) {
      switch (settings.name) {
        case splash:
          return MaterialPageRoute(builder: (_) => SplashScreen());
        case login:
          return MaterialPageRoute(builder: (_) => LoginScreen());
        case adminDashboard:
          return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
        case doctorDashboard:
          return MaterialPageRoute(builder: (_) => DoctorDashboardScreen());
        case receptionistDashboard:
          return MaterialPageRoute(builder: (_) => ReceptionistDashboardScreen());
        case patientDashboard:
          return MaterialPageRoute(builder: (_) => PatientDashboardScreen());
        case patientHome:
          return MaterialPageRoute(builder: (_) => PatientHomeScreen());
        case nurseDashboard:
          return MaterialPageRoute(builder: (_) => NurseDashboardScreen());
        case patientManager:
          return MaterialPageRoute(builder: (_) => PatientManagerScreen());
        case staffManager:
          return MaterialPageRoute(builder: (_) => StaffManagerScreen());
        case medicalRecordDetail:
          return MaterialPageRoute(
            builder: (_) => MedicalRecordDetailScreen(id: settings.arguments as String),
          );
        case createStaff:
          return MaterialPageRoute(builder: (_) => const CreateStaffScreen());
        case Routes.editProfile:
          return MaterialPageRoute(builder: (_) => const EditProfileScreen());
        case appointmentDetail:
          return MaterialPageRoute(
            builder: (_) => AppointmentDetailScreen(appointmentId: settings.arguments as String,),
          );
        case Routes.bookAppointment:
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
          builder: (_) => BookAppointmentScreen(
            appointmentId: args?['appointmentId'],
            existingData: args?['existingData'],
          ),
        );
        case Routes.patientDetails:
          return MaterialPageRoute(
            builder: (_) => PatientDetailScreen(patientId: settings.arguments as String),
          );
        
        default:
          // Provide a default widget if the route is not found
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Route not found: ${settings.name}')),
            ),
          );
      }
    };
  }
}