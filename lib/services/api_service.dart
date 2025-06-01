import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:patient_management_app/config/service_locator.dart';
import 'package:patient_management_app/data/models/user_model.dart';

class ApiService {
  // Base URL for the backend API
  // In production, this would be your actual server URL
  // For local development, use your machine's IP address instead of localhost
  // when testing with a physical device
  // Dynamic base URL selection based on platform
  // Server connection configuration
  // This approach allows for easier configuration based on your environment
  static String _serverAddress = '10.0.2.2'; // Default for Android emulator
  static int _serverPort = 3000;
  
  // Configure the server address based on your environment
  static void configureServer({required String address, int port = 3000}) {
    _serverAddress = address;
    _serverPort = port;
  }
  
  // Get the complete base URL
  static String get baseUrl => 'http://$_serverAddress:$_serverPort';
  
  // Test connection to the server
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Cannot connect to server at $baseUrl: ${e.toString()}');
    }
  }
  
  // Helper method to determine the best server address based on platform
  static String getRecommendedServerAddress() {
    if (Platform.isAndroid) {
      return '10.0.2.2'; // Android emulator maps this to host's localhost
    } else if (Platform.isIOS) {
      return 'localhost'; // iOS simulator
    } else {
      return 'localhost'; // Web or other platforms
    }
    // For physical devices, use your computer's actual IP address on your network
    // Example: return '192.168.1.5';
  }
  
  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // Create a staff member through the backend API
  Future<Map<String, dynamic>> createStaffMember({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
    String? specialty,
    String? licenseNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/create-staff'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role.name,
          'phoneNumber': phoneNumber,
          'specialty': specialty,
          'licenseNumber': licenseNumber,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Connection timed out. Please make sure the server is running at $baseUrl');
      });

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to create staff member');
      }
      
      return responseData;
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Cannot connect to server. Please make sure the server is running at $baseUrl');
      } else if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}. Please check your connection and server status.');
      } else if (e is TimeoutException) {
        throw Exception('Connection timed out. Please make sure the server is running at $baseUrl');
      } else if (e is FormatException) {
        throw Exception('Invalid response format from server. Please check server logs.');
      }
      rethrow;
    }
  }

  // Update staff member status (active/inactive)
  Future<Map<String, dynamic>> updateStaffStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/staff/$userId/status'),
        headers: _headers,
        body: jsonEncode({
          'isActive': isActive,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Connection timed out. Please make sure the server is running at $baseUrl');
      });

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to update staff status');
      }
      
      return responseData;
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Cannot connect to server. Please make sure the server is running at $baseUrl');
      } else if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}. Please check your connection and server status.');
      } else if (e is TimeoutException) {
        throw Exception('Connection timed out. Please make sure the server is running at $baseUrl');
      } else if (e is FormatException) {
        throw Exception('Invalid response format from server. Please check server logs.');
      }
      rethrow;
    }
  }
}