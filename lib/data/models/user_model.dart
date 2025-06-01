import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  doctor,
  nurse,
  receptionist,
  patient;
}

enum Permission {
  createStaff,
  editStaff,
  viewPatients,
  editPatients,
  deactivateStaff,
  updateStaff,
  viewMedicalRecords,
  createMedicalRecords,
  updateMedicalRecords,
  viewAppointments,
  createAppointments,
  updateAppointments,
  cancelAppointments
}

extension UserRoleExtension on UserRole {
  String get name => toString().split('.').last;

  List<Permission> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          Permission.createStaff,
          Permission.editStaff,
          Permission.deactivateStaff,
          Permission.updateStaff,
          Permission.viewPatients,
          Permission.editPatients,
          Permission.viewMedicalRecords,
          Permission.createMedicalRecords,
          Permission.updateMedicalRecords,
          Permission.viewAppointments,
          Permission.createAppointments,
          Permission.updateAppointments,
          Permission.cancelAppointments,
        ];
      case UserRole.doctor:
        return [
          Permission.viewPatients,
          Permission.editPatients,
          Permission.viewMedicalRecords,
          Permission.createMedicalRecords,
          Permission.updateMedicalRecords,
          Permission.viewAppointments,
          Permission.updateAppointments,
        ];
      case UserRole.nurse:
        return [
          Permission.viewPatients,
          Permission.viewMedicalRecords,
          Permission.updateMedicalRecords,
          Permission.viewAppointments,
        ];
      case UserRole.receptionist:
        return [
          Permission.viewPatients,
          Permission.viewAppointments,
          Permission.createAppointments,
          Permission.updateAppointments,
          Permission.cancelAppointments,
        ];
      case UserRole.patient:
        return [
          Permission.viewAppointments,
          Permission.createAppointments,
          Permission.cancelAppointments,
        ];
    }
  }
}

class User {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final String? phoneNumber;
  final String? photoUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodType;
  final String? address;
  final String? emergencyContact;
  final List<String>? allergies;
  final String? medicalHistory;
  final String? prescriptions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? metadata; // For additional user data like specialty
  
  // Role-specific fields
  final String? specialty;       // For doctors
  final String? licenseNumber;   // For doctors
  final String? nursingLicense;  // For nurses
  final List<String>? departments; // For all medical staff

  User({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.phoneNumber,
    this.photoUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodType,
    this.address,
    this.emergencyContact,
    this.allergies,
    this.medicalHistory,
    this.prescriptions,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.metadata,
    // Role-specific fields
    this.specialty,
    this.licenseNumber,
    this.nursingLicense,
    this.departments,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      role: _parseUserRole(map['role']),
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] is Timestamp
              ? (map['dateOfBirth'] as Timestamp).toDate()
              : map['dateOfBirth'] is int
                  ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'] as int)
                  : DateTime.tryParse(map['dateOfBirth'] as String))
          : null,
      gender: map['gender'] as String?,
      bloodType: map['bloodType'] as String?,
      address: map['address'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      allergies: map['allergies'] != null
          ? (map['allergies'] is String
              ? List<String>.from(jsonDecode(map['allergies'] as String))
              : List<String>.from(map['allergies'] as List<dynamic>))
          : null,
      medicalHistory: map['medicalHistory'] as String?,
      prescriptions: map['prescriptions'] as String?,
      createdAt: (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)),
      updatedAt: (map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)),
      isActive: map['isActive'] is bool
          ? map['isActive'] as bool
          : (map['isActive'] == 1),
      // Role-specific fields
      specialty: map['specialty'] as String?,
      licenseNumber: map['licenseNumber'] as String?,
      nursingLicense: map['nursingLicense'] as String?,
      departments: map['departments'] != null
          ? (map['departments'] is String
              ? map['departments'].split(',')
              : List<String>.from(map['departments'] as List<dynamic>))
          : null,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
    );
  }

  static UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'doctor':
        return UserRole.doctor;
      case 'nurse':
        return UserRole.nurse;
      case 'receptionist':
        return UserRole.receptionist;
      case 'patient':
      default:
        return UserRole.patient;
    }
  }

  Map<String, dynamic> toMap({bool forSQLite = false}) {
    final map = {
      'id': id,
      'email': email,
      'metadata': metadata,
      'name': name,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'gender': gender,
      'bloodType': bloodType,
      'address': address,
      'emergencyContact': emergencyContact,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'prescriptions': prescriptions,
      'createdAt': forSQLite ? createdAt.millisecondsSinceEpoch : Timestamp.fromDate(createdAt),
      'updatedAt': forSQLite ? updatedAt.millisecondsSinceEpoch : Timestamp.fromDate(updatedAt),
      'isActive': forSQLite ? (isActive ? 1 : 0) : isActive,
      // Role-specific fields
      'specialty': specialty,
      'licenseNumber': licenseNumber,
      'nursingLicense': nursingLicense,
      'departments': departments,
    };
    
    if (forSQLite) {
      if (map['allergies'] != null) {
        map['allergies'] = jsonEncode(map['allergies']);
      }
      if (map['departments'] != null) {
        map['departments'] = (map['departments'] as List<String>).join(',');
      }
    }
    
    return map;
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? address,
    String? emergencyContact,
    List<String>? allergies,
    String? medicalHistory,
    String? prescriptions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    // Role-specific fields
    String? specialty,
    String? licenseNumber,
    String? nursingLicense,
    List<String>? departments,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      prescriptions: prescriptions ?? this.prescriptions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      // Role-specific fields
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      nursingLicense: nursingLicense ?? this.nursingLicense,
      departments: departments ?? this.departments,
    );
  }

  bool hasPermission(Permission permission) {
    return role.permissions.contains(permission);
  }
}