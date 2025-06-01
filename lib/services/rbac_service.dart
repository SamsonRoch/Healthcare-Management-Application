import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/auth_service.dart';

/// Role-Based Access Control Service
/// 
/// This service manages user roles and permissions throughout the application.
/// It provides methods to check if a user has permission to perform specific actions
/// based on their assigned role.
class RBACService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final AuthService _authService = locator<AuthService>();
  
  // Role definitions with associated permissions
  final Map<String, List<String>> _rolePermissions = {
    'admin': [
      'manage_users',
      'manage_patients',
      'manage_appointments',
      'manage_medical_records',
      'view_reports',
      'export_data',
    ],
    'doctor': [
      'view_patients',
      'manage_patients',
      'manage_appointments',
      'manage_medical_records',
      'view_reports',
    ],
    'nurse': [
      'view_patients',
      'view_appointments',
      'update_medical_records',
      'view_reports',
    ],
    'receptionist': [
      'view_patients',
      'manage_appointments',
      'view_reports',
    ],
    'patient': [
      'view_own_records',
      'view_own_appointments',
    ],
  };
  
  /// Check if the current user has a specific permission
  Future<bool> hasPermission(String permission) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;
    
    return hasUserPermission(currentUser.id, permission);
  }
  
  /// Check if a specific user has a permission
  Future<bool> hasUserPermission(String userId, String permission) async {
    try {
      // Get user role from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data();
      if (userData == null) return false;
      
      final userRole = userData['role'] as String?;
      if (userRole == null) return false;
      
      // Check if the role has the required permission
      final permissions = _rolePermissions[userRole] ?? [];
      return permissions.contains(permission);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }
  
  /// Get all permissions for a specific role
  List<String> getPermissionsForRole(String role) {
    return _rolePermissions[role] ?? [];
  }
  
  /// Get the role of the current user
  Future<String?> getCurrentUserRole() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;
    
    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.id).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data();
      if (userData == null) return null;
      
      return userData['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  /// Check if the current user has a specific role
  Future<bool> hasRole(String role) async {
    final currentRole = await getCurrentUserRole();
    return currentRole == role;
  }
}