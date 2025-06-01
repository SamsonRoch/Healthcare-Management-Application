import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';
import 'package:patient_management_app/services/api_service.dart';

class StaffService {
  final ApiService _apiService = locator<ApiService>();
  
  /// Creates a new staff member through the backend API
  Future<bool> createStaffMember(
    String email, 
    String password, 
    String name, 
    UserRole role,
    {String? phoneNumber, String? specialty, String? licenseNumber}
  ) async {
    try {
      final response = await _apiService.createStaffMember(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        specialty: specialty,
        licenseNumber: licenseNumber,
      );
      
      if (response['success']) {
        // Successfully created staff member
        return true;
      } else {
        print('Failed to create staff member: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('Error creating staff member: $e');
      // Rethrow the exception so it can be handled by the UI
      throw e;
    }
  }
  
  /// Updates a staff member's active status
  Future<bool> updateStaffStatus(String userId, bool isActive) async {
    try {
      final response = await _apiService.updateStaffStatus(
        userId: userId,
        isActive: isActive,
      );
      
      if (response['success']) {
        return true;
      } else {
        print('Failed to update staff status: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating staff status: $e');
      return false;
    }
  }
}